"""Testes da E5 — vídeo/animação assíncronos, upload, worker e webhook.

Nenhuma chave real, Redis, Firebase ou rede: Celery é substituído por dispatchers
que só registram chamadas, e o provider é uma implementação local controlada.
"""

from __future__ import annotations

import hashlib
import json
import time
import uuid
from dataclasses import dataclass
from decimal import Decimal
from typing import Callable

import pytest
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

import app.generation.video_service as video_service_module
from app.admin.model import CostConfig
from app.credits.model import CreditLedgerEntry
from app.credits.service import CreditService
from app.core.config import settings
from app.core.database import Base, get_db
from app.core.security import AuthError, VerifiedIdentity, get_verifier
from app.generation.deps import (
    get_fal_webhook_dispatcher,
    get_fal_webhook_verifier,
    get_media_storage,
    get_video_job_dispatcher,
    get_video_provider,
)
from app.generation.model import Generation
from app.generation.providers.video_base import (
    GeneratedVideo,
    VideoJob,
    VideoJobFailed,
    VideoOperation,
    VideoProvider,
)
from app.generation.storage import LocalMediaStorage
from app.generation.video_service import VideoGenerationService
from app.generation.webhook import FalWebhookVerifier
from app.main import app
from app.payments.model import Payment, WebhookEvent  # noqa: F401
from app.plans.model import Plan
from app.users.model import User

FREE_PLAN_ID = uuid.UUID("11111111-1111-4111-8111-111111111111")
ZERO_PLAN_ID = uuid.UUID("22222222-2222-4222-8222-222222222222")
JOB_ID = "019a1b2c-3d4e-7f80-9a1b-2c3d4e5f6a7b"
PNG = b"\x89PNG\r\n\x1a\n" + b"\x00" * 24


class FakeVideoProvider(VideoProvider):
    """Provider determinístico: estados configuráveis e vídeo em memória."""

    name = "fake-video"

    def __init__(
        self,
        *,
        statuses: list[str] | None = None,
        result_error: Exception | None = None,
    ) -> None:
        self.statuses = statuses or ["COMPLETED"]
        self.result_error = result_error
        self.polls = 0
        self.submissions: list[dict] = []

    def submit(
        self,
        *,
        operation: VideoOperation,
        prompt: str | None,
        image_url: str | None,
        motion: str | None,
        duration_seconds: int,
        resolution: str,
    ) -> VideoJob:
        self.submissions.append(
            {
                "operation": operation,
                "prompt": prompt,
                "image_url": image_url,
                "motion": motion,
                "duration_seconds": duration_seconds,
                "resolution": resolution,
            }
        )
        return VideoJob(
            provider_request_id=JOB_ID,
            status_url=f"mock://video/{JOB_ID}/status",
            response_url=f"mock://video/{JOB_ID}/result",
            provider=self.name,
        )

    def status(self, job: VideoJob) -> str:
        index = min(self.polls, len(self.statuses) - 1)
        self.polls += 1
        return self.statuses[index]

    def result(self, job: VideoJob) -> GeneratedVideo:
        if self.result_error is not None:
            raise self.result_error
        return GeneratedVideo(
            content=b"\x00\x00\x00\x18ftypmp42falso",
            media_type="video/mp4",
            provider=self.name,
            extension="mp4",
        )


class FakeVerifier:
    def verify(self, token: str) -> VerifiedIdentity:
        identities = {
            "token-ana": ("firebase-uid-ana", "ana@example.com", "Ana"),
            "token-beto": ("firebase-uid-beto", "beto@example.com", "Beto"),
        }
        if token not in identities:
            raise AuthError("ID token inválido.")
        uid, email, name = identities[token]
        return VerifiedIdentity(uid=uid, email=email, display_name=name)


@dataclass
class Ctx:
    client: TestClient
    Session: Callable[[], Session]
    provider: FakeVideoProvider
    storage: LocalMediaStorage
    ana_id: uuid.UUID
    beto_id: uuid.UUID
    dispatched: list[str]
    webhook_dispatched: list[tuple[str, dict]]
    private_key: Ed25519PrivateKey


@pytest.fixture()
def ctx(tmp_path, monkeypatch: pytest.MonkeyPatch):
    # exemplo.test não resolve na máquina de teste: a validação SSRF usa
    # _resolve_host, que é injetado aqui para devolver um IP público fictício.
    monkeypatch.setattr(
        video_service_module,
        "_resolve_host",
        lambda host: ["93.184.216.34"],
    )
    engine = create_engine(
        "sqlite://",
        poolclass=StaticPool,
        connect_args={"check_same_thread": False},
    )
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)

    seed = Session()
    seed.add_all(
        [
            Plan(
                id=FREE_PLAN_ID,
                slug="gratuito",
                name="Gratuito",
                monthly_credits=100,
                price_brl=Decimal("0.00"),
                recurrence="monthly",
                is_active=True,
                sort_order=0,
            ),
            Plan(
                id=ZERO_PLAN_ID,
                slug="sem-credito",
                name="Sem crédito",
                monthly_credits=0,
                price_brl=Decimal("0.00"),
                recurrence="monthly",
                is_active=True,
                sort_order=1,
            ),
            User(
                id=uuid.uuid4(),
                firebase_uid="firebase-uid-ana",
                email="ana@example.com",
                plan_id=FREE_PLAN_ID,
            ),
            User(
                id=uuid.uuid4(),
                firebase_uid="firebase-uid-beto",
                email="beto@example.com",
                plan_id=ZERO_PLAN_ID,
            ),
            CostConfig(operation="image", credits=10, enabled=True),
            CostConfig(operation="video", credits=50, enabled=True),
            CostConfig(operation="animate_photo", credits=20, enabled=True),
        ]
    )
    seed.commit()
    ana_id = seed.execute(
        select(User.id).where(User.firebase_uid == "firebase-uid-ana")
    ).scalar_one()
    beto_id = seed.execute(
        select(User.id).where(User.firebase_uid == "firebase-uid-beto")
    ).scalar_one()
    seed.close()

    def override_get_db():
        session = Session()
        try:
            yield session
        finally:
            session.close()

    provider = FakeVideoProvider()
    storage = LocalMediaStorage(tmp_path / "media")
    dispatched: list[str] = []
    webhook_dispatched: list[tuple[str, dict]] = []
    private_key = Ed25519PrivateKey.generate()
    public_bytes = private_key.public_key().public_bytes(
        encoding=serialization.Encoding.Raw,
        format=serialization.PublicFormat.Raw,
    )
    verifier = FalWebhookVerifier(pinned_keys=[public_bytes])

    app.dependency_overrides[get_db] = override_get_db
    app.dependency_overrides[get_verifier] = FakeVerifier
    app.dependency_overrides[get_media_storage] = lambda: storage
    app.dependency_overrides[get_video_provider] = lambda: provider
    app.dependency_overrides[get_video_job_dispatcher] = lambda: dispatched.append
    app.dependency_overrides[get_fal_webhook_verifier] = lambda: verifier
    app.dependency_overrides[get_fal_webhook_dispatcher] = (
        lambda: lambda request_id, payload: webhook_dispatched.append((request_id, payload))
    )

    with TestClient(app) as client:
        yield Ctx(
            client, Session, provider, storage, ana_id, beto_id,
            dispatched, webhook_dispatched, private_key,
        )

    app.dependency_overrides.clear()


AUTH = {"Authorization": "Bearer token-ana"}
BETO_AUTH = {"Authorization": "Bearer token-beto"}


def _video_payload(key: str = "key-video-001") -> dict:
    return {
        "prompt": "um dragão sobre a cidade",
        "duration_seconds": 5,
        "resolution": "720p",
        "idempotency_key": key,
    }


def _animate_payload(key: str = "key-animate-001") -> dict:
    return {
        "image_url": "https://exemplo.test/foto.png",
        "motion": "zoom lento",
        "idempotency_key": key,
    }


def _balance(Session, user_id):
    session = Session()
    try:
        return CreditService.get_balance(session, user_id)
    finally:
        session.close()


def _kinds(Session, user_id) -> list[str]:
    session = Session()
    try:
        rows = session.execute(
            select(CreditLedgerEntry.kind, CreditLedgerEntry.created_at)
            .where(CreditLedgerEntry.user_id == user_id)
            .order_by(CreditLedgerEntry.created_at, CreditLedgerEntry.id)
        ).all()
        # No Windows, datetime.now() tem resolução de ~1-15ms: grant e reserve
        # podem dividir o mesmo created_at. O desempate por sequência lógica só
        # atua quando os timestamps são idênticos; ordens cronológicas reais
        # (ex.: reserve antes do grant) continuam sendo detectadas.
        sequence = {"grant": 0, "reserve": 1, "commit": 2, "refund": 2, "adjust": 2}
        return [
            kind
            for kind, _ in sorted(rows, key=lambda row: (row[1], sequence.get(row[0], 3)))
        ]
    finally:
        session.close()


def _row(Session, generation_id: str) -> Generation:
    session = Session()
    try:
        return session.get(Generation, uuid.UUID(generation_id))
    finally:
        session.close()


def _run_worker(Session, generation_id: str, provider: VideoProvider, storage) -> dict:
    """Executa o job fora da rota, como faria o worker do Celery."""
    with Session() as db:
        result = VideoGenerationService.process(
            db, generation_id=generation_id, provider=provider, storage=storage
        )
        return result.model_dump(mode="json")


def _signed_webhook(ctx: Ctx, payload: dict, *, delivery_id: str = "delivery-001") -> tuple[bytes, dict]:
    body = json.dumps(payload, separators=(",", ":")).encode("utf-8")
    timestamp = str(int(time.time()))
    message = "\n".join(
        [delivery_id, "user-oficial", timestamp, hashlib.sha256(body).hexdigest()]
    ).encode("utf-8")
    signature = ctx.private_key.sign(message)
    headers = {
        "X-Fal-Webhook-Request-Id": delivery_id,
        "X-Fal-Webhook-User-Id": "user-oficial",
        "X-Fal-Webhook-Timestamp": timestamp,
        "X-Fal-Webhook-Signature": signature.hex(),
    }
    return body, headers


# ---------------------------------------------------------------------------
# Enfileiramento (202)
# ---------------------------------------------------------------------------


def test_video_enfileira_com_202_e_reserva_50(ctx: Ctx) -> None:
    response = ctx.client.post("/generations/video", json=_video_payload(), headers=AUTH)

    assert response.status_code == 202, response.text
    body = response.json()
    assert body["status"] == "queued"
    assert body["type"] == "video"
    assert body["cost_credits"] == 50
    assert body["progress"] == 0
    assert body["media_url"] is None
    assert ctx.dispatched == [body["id"]]

    assert _balance(ctx.Session, ctx.ana_id).available == 50  # 100 - 50 reservados
    assert _kinds(ctx.Session, ctx.ana_id) == ["grant", "reserve"]


def test_animate_photo_enfileira_com_custo_20(ctx: Ctx) -> None:
    response = ctx.client.post("/generations/animate-photo", json=_animate_payload(), headers=AUTH)

    assert response.status_code == 202, response.text
    body = response.json()
    assert body["status"] == "queued"
    assert body["type"] == "animate_photo"
    assert body["cost_credits"] == 20
    assert body["progress"] == 0
    assert ctx.provider.submissions == []  # submit acontece só no worker
    assert ctx.dispatched == [body["id"]]
    assert _kinds(ctx.Session, ctx.ana_id) == ["grant", "reserve"]


def test_enfileiramento_e_idempotente(ctx: Ctx) -> None:
    payload = _video_payload("key-video-idem")

    first = ctx.client.post("/generations/video", json=payload, headers=AUTH)
    second = ctx.client.post("/generations/video", json=payload, headers=AUTH)

    assert first.status_code == second.status_code == 202
    assert first.json()["id"] == second.json()["id"]
    assert ctx.dispatched == [first.json()["id"]]
    assert _kinds(ctx.Session, ctx.ana_id) == ["grant", "reserve"]


def test_insufficient_credits_nao_enfileira(ctx: Ctx) -> None:
    response = ctx.client.post("/generations/video", json=_video_payload(), headers=BETO_AUTH)

    assert response.status_code == 402, response.text
    assert ctx.dispatched == []
    assert _kinds(ctx.Session, ctx.beto_id) == []


def test_flag_off_devolve_503(monkeypatch: pytest.MonkeyPatch, ctx: Ctx) -> None:
    monkeypatch.setattr(settings, "video_generation_enabled", False)

    response = ctx.client.post("/generations/video", json=_video_payload(), headers=AUTH)

    assert response.status_code == 503, response.text
    assert "indisponível" in response.json()["detail"]
    assert ctx.dispatched == []
    assert _kinds(ctx.Session, ctx.ana_id) == []


def test_url_de_origem_https_e_validada(ctx: Ctx) -> None:
    publica = ctx.client.post("/generations/animate-photo", json=_animate_payload(), headers=AUTH)
    assert publica.status_code == 202, publica.text

    insegura = ctx.client.post(
        "/generations/animate-photo",
        json={**_animate_payload("key-animate-http"), "image_url": "http://exemplo.test/foto.png"},
        headers=AUTH,
    )
    assert insegura.status_code == 422, insegura.text
    assert "HTTPS" in insegura.json()["detail"]

    com_credencial = ctx.client.post(
        "/generations/animate-photo",
        json={**_animate_payload("key-animate-user"), "image_url": "https://user:pass@exemplo.test/foto.png"},
        headers=AUTH,
    )
    assert com_credencial.status_code == 422, com_credencial.text
    assert len(ctx.dispatched) == 1


@pytest.mark.parametrize(
    ("key", "url"),
    [
        ("loopback", "https://127.0.0.1/foto.png"),
        ("privada", "https://10.0.0.5/foto.png"),
        ("metadados", "https://169.254.169.254/latest/meta-data/"),
        ("localhost", "https://localhost/foto.png"),
        ("porta", "https://exemplo.test:8443/foto.png"),
    ],
)
def test_url_de_origem_bloqueia_enderecos_nao_publicos(
    ctx: Ctx, key: str, url: str
) -> None:
    response = ctx.client.post(
        "/generations/animate-photo",
        json={**_animate_payload(f"key-ssrf-{key}"), "image_url": url},
        headers=AUTH,
    )
    assert response.status_code == 422, response.text
    assert ctx.dispatched == []


def test_url_de_origem_bloqueia_host_que_resolve_para_rede_interna(
    monkeypatch: pytest.MonkeyPatch, ctx: Ctx
) -> None:
    monkeypatch.setattr(
        video_service_module,
        "_resolve_host",
        lambda host: ["192.168.1.10"],
    )
    response = ctx.client.post(
        "/generations/animate-photo",
        json=_animate_payload("key-ssrf-resolve"),
        headers=AUTH,
    )
    assert response.status_code == 422, response.text
    assert ctx.dispatched == []


# ---------------------------------------------------------------------------
# Upload seguro
# ---------------------------------------------------------------------------


def test_upload_png_valido(ctx: Ctx) -> None:
    response = ctx.client.post(
        "/generations/uploads",
        files={"file": ("foto.png", PNG, "image/png")},
        headers=AUTH,
    )

    assert response.status_code == 201, response.text
    body = response.json()
    assert body["media_type"] == "image/png"
    assert body["image_url"].startswith("/media/")
    assert body["image_url"].endswith(".png")
    assert (ctx.storage.root / f"{ctx.ana_id}" / f"{body['image_url'].split('/')[-1][:-4]}.png").exists()


def test_upload_recusa_mime_e_magic_bytes(ctx: Ctx) -> None:
    mime = ctx.client.post(
        "/generations/uploads",
        files={"file": ("foto.gif", PNG, "image/gif")},
        headers=AUTH,
    )
    assert mime.status_code == 415, mime.text

    conteudo = ctx.client.post(
        "/generations/uploads",
        files={"file": ("foto.png", b"<script>alert(1)</script>", "image/png")},
        headers=AUTH,
    )
    assert conteudo.status_code == 415, conteudo.text
    assert not list(ctx.storage.root.rglob("*.png"))


def test_upload_respeita_limite(monkeypatch: pytest.MonkeyPatch, ctx: Ctx) -> None:
    monkeypatch.setattr(settings, "upload_max_bytes", 8)

    response = ctx.client.post(
        "/generations/uploads",
        files={"file": ("foto.png", PNG, "image/png")},
        headers=AUTH,
    )

    assert response.status_code == 413, response.text
    assert not list(ctx.storage.root.rglob("*.png"))


# ---------------------------------------------------------------------------
# Worker de polling
# ---------------------------------------------------------------------------


def test_worker_sucesso_confirma_e_salva_mp4(ctx: Ctx) -> None:
    created = ctx.client.post("/generations/video", json=_video_payload(), headers=AUTH)
    generation_id = created.json()["id"]

    result = _run_worker(ctx.Session, generation_id, ctx.provider, ctx.storage)

    assert result["status"] == "completed"
    assert result["progress"] == 100
    assert result["provider"] == "fake-video"
    assert result["media_url"].endswith(".mp4")
    assert ctx.provider.submissions[0]["operation"] == VideoOperation.TEXT_TO_VIDEO
    assert _balance(ctx.Session, ctx.ana_id).available == 50
    assert _kinds(ctx.Session, ctx.ana_id) == ["grant", "reserve", "commit"]
    assert list(ctx.storage.root.rglob("*.mp4"))


def test_worker_falha_estorna(ctx: Ctx) -> None:
    ctx.provider.result_error = VideoJobFailed("O provedor não conseguiu gerar o vídeo.")
    created = ctx.client.post("/generations/video", json=_video_payload(), headers=AUTH)
    generation_id = created.json()["id"]

    result = _run_worker(ctx.Session, generation_id, ctx.provider, ctx.storage)

    assert result["status"] == "failed"
    assert result["progress"] == 0
    assert "não conseguiu" in result["error_message"]
    assert _balance(ctx.Session, ctx.ana_id).available == 100
    assert _kinds(ctx.Session, ctx.ana_id) == ["grant", "reserve", "refund"]
    assert not list(ctx.storage.root.rglob("*.mp4"))


def test_worker_timeout_estorna(
    monkeypatch: pytest.MonkeyPatch, ctx: Ctx
) -> None:
    monkeypatch.setattr(settings, "video_poll_attempts", 2)
    monkeypatch.setattr(settings, "video_poll_interval_seconds", 0.0)
    ctx.provider.statuses = ["IN_PROGRESS"]
    created = ctx.client.post("/generations/video", json=_video_payload(), headers=AUTH)

    result = _run_worker(ctx.Session, created.json()["id"], ctx.provider, ctx.storage)

    assert result["status"] == "failed"
    assert "demorou" in result["error_message"]
    assert _kinds(ctx.Session, ctx.ana_id) == ["grant", "reserve", "refund"]


def test_worker_e_idempotente(ctx: Ctx) -> None:
    created = ctx.client.post("/generations/video", json=_video_payload(), headers=AUTH)
    generation_id = created.json()["id"]

    first = _run_worker(ctx.Session, generation_id, ctx.provider, ctx.storage)
    second = _run_worker(ctx.Session, generation_id, ctx.provider, ctx.storage)

    assert first["status"] == second["status"] == "completed"
    assert len(ctx.provider.submissions) == 1
    assert _kinds(ctx.Session, ctx.ana_id) == ["grant", "reserve", "commit"]


def test_worker_de_video_inesperado_nao_e_aceito(ctx: Ctx) -> None:
    created = ctx.client.post("/generations/video", json=_video_payload(), headers=AUTH)
    generation_id = created.json()["id"]
    with ctx.Session() as db:
        row = db.get(Generation, uuid.UUID(generation_id))
        row.type = "image"
        db.commit()

    with pytest.raises(Exception, match="não encontrada"):
        with ctx.Session() as db:
            VideoGenerationService.process(
                db, generation_id=generation_id, provider=ctx.provider, storage=ctx.storage
            )


# ---------------------------------------------------------------------------
# Webhook HTTP (assinatura, deduplicação, finalização)
# ---------------------------------------------------------------------------


def test_webhook_assinado_enfileira_e_finaliza(ctx: Ctx) -> None:
    created = ctx.client.post("/generations/video", json=_video_payload(), headers=AUTH)
    with ctx.Session() as db:
        row = db.get(Generation, uuid.UUID(created.json()["id"]))
        row.provider_request_id = JOB_ID
        db.commit()

    body, headers = _signed_webhook(ctx, {"request_id": JOB_ID, "status": "COMPLETED"})
    response = ctx.client.post("/webhooks/falai", content=body, headers=headers)

    assert response.status_code == 200, response.text
    assert response.json() == {"received": True, "duplicate": False}
    assert ctx.webhook_dispatched == [(JOB_ID, {"request_id": JOB_ID, "status": "COMPLETED"})]

    with ctx.Session() as db:
        finalized = VideoGenerationService.finalize_from_webhook(
            db, request_id=JOB_ID, payload={"status": "COMPLETED"},
            provider=ctx.provider, storage=ctx.storage,
        )
    assert finalized is True
    finalized_row = _row(ctx.Session, created.json()["id"])
    assert finalized_row.status == "completed"
    assert _kinds(ctx.Session, ctx.ana_id) == ["grant", "reserve", "commit"]


def test_webhook_assinatura_invalida_e_recusado(ctx: Ctx) -> None:
    body, headers = _signed_webhook(ctx, {"request_id": JOB_ID, "status": "COMPLETED"})
    headers["X-Fal-Webhook-Signature"] = "00" * 64

    response = ctx.client.post("/webhooks/falai", content=body, headers=headers)

    assert response.status_code == 401, response.text
    assert ctx.webhook_dispatched == []
    with ctx.Session() as db:
        assert db.query(WebhookEvent).count() == 0


def test_webhook_reentrega_e_duplicata(ctx: Ctx) -> None:
    body, headers = _signed_webhook(ctx, {"request_id": JOB_ID, "status": "IN_PROGRESS"})

    first = ctx.client.post("/webhooks/falai", content=body, headers=headers)
    second = ctx.client.post("/webhooks/falai", content=body, headers=headers)

    assert first.status_code == second.status_code == 200
    assert first.json()["duplicate"] is False
    assert second.json()["duplicate"] is True
    assert len(ctx.webhook_dispatched) == 1
    with ctx.Session() as db:
        assert db.query(WebhookEvent).count() == 1


def test_webhook_job_desconhecido_e_ignorado(ctx: Ctx) -> None:
    body, headers = _signed_webhook(ctx, {"request_id": "job-inexistente", "status": "COMPLETED"})

    response = ctx.client.post("/webhooks/falai", content=body, headers=headers)

    assert response.status_code == 200, response.text
    assert ctx.webhook_dispatched == [("job-inexistente", {"request_id": "job-inexistente", "status": "COMPLETED"})]
    with ctx.Session() as db:
        assert VideoGenerationService.finalize_from_webhook(
            db, request_id="job-inexistente", payload={"status": "COMPLETED"},
            provider=ctx.provider, storage=ctx.storage,
        ) is False


def test_webhook_de_falha_estorna(ctx: Ctx) -> None:
    created = ctx.client.post("/generations/video", json=_video_payload(), headers=AUTH)
    with ctx.Session() as db:
        row = db.get(Generation, uuid.UUID(created.json()["id"]))
        row.provider_request_id = JOB_ID
        db.commit()

    with ctx.Session() as db:
        finalized = VideoGenerationService.finalize_from_webhook(
            db,
            request_id=JOB_ID,
            payload={"status": "FAILED", "error": "moderation"},
            provider=ctx.provider,
            storage=ctx.storage,
        )

    assert finalized is True
    assert _row(ctx.Session, created.json()["id"]).status == "failed"
    assert _kinds(ctx.Session, ctx.ana_id) == ["grant", "reserve", "refund"]


# ---------------------------------------------------------------------------
# Contrato / galeria
# ---------------------------------------------------------------------------


def test_galeria_filtra_video_e_expoe_progress(ctx: Ctx) -> None:
    video = ctx.client.post("/generations/video", json=_video_payload(), headers=AUTH)
    animated = ctx.client.post("/generations/animate-photo", json=_animate_payload(), headers=AUTH)
    assert video.status_code == animated.status_code == 202

    listing = ctx.client.get("/generations?type=video", headers=AUTH)
    assert listing.status_code == 200, listing.text
    assert [item["id"] for item in listing.json()] == [video.json()["id"]]

    animated_listing = ctx.client.get("/generations?type=animate_photo", headers=AUTH)
    assert [item["id"] for item in animated_listing.json()] == [animated.json()["id"]]
    assert all(item["progress"] == 0 for item in animated_listing.json())

    detail = ctx.client.get(f"/generations/{video.json()['id']}", headers=AUTH)
    assert detail.status_code == 200
    assert detail.json()["progress"] == 0
