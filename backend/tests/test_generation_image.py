"""Testes da E4 — geração de imagem, débito, estorno, idempotência e galeria."""

from __future__ import annotations

import uuid
from dataclasses import replace
from decimal import Decimal

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, select, text
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.admin.model import CostConfig
from app.credits.model import CreditLedgerEntry
from app.credits.service import CreditService
from app.core.config import settings
from app.core.database import Base, get_db
from app.core.security import AuthError, VerifiedIdentity, get_verifier
from app.generation.deps import get_image_provider, get_media_storage
from app.generation.model import Generation  # noqa: F401 — registra a tabela
from app.generation.providers.base import (
    GeneratedImage,
    ImageProvider,
    ImageProviderUnavailable,
)
from app.generation.providers.mock import MockImageProvider
from app.generation.storage import LocalMediaStorage
from app.main import app
from app.payments.model import Payment, WebhookEvent  # noqa: F401
from app.plans.model import Plan
from app.users.model import User

FREE_PLAN_ID = uuid.UUID("11111111-1111-4111-8111-111111111111")
ZERO_PLAN_ID = uuid.UUID("22222222-2222-4222-8222-222222222222")


class FakeProvider(ImageProvider):
    name = "fake"

    def __init__(self) -> None:
        self.calls = 0
        self.error: Exception | None = None
        self.delay = 0.0

    def generate(self, *, prompt: str, style: str | None, size: str) -> GeneratedImage:
        self.calls += 1
        if self.error is not None:
            raise self.error
        if self.delay:
            import time

            time.sleep(self.delay)
        image = MockImageProvider().generate(prompt=prompt, style=style, size=size)
        return replace(image, provider=self.name)


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


@pytest.fixture()
def ctx(tmp_path):
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
                monthly_credits=30,
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

    provider = FakeProvider()
    storage = LocalMediaStorage(tmp_path / "media")
    app.dependency_overrides[get_db] = override_get_db
    app.dependency_overrides[get_verifier] = FakeVerifier
    app.dependency_overrides[get_image_provider] = lambda: provider
    app.dependency_overrides[get_media_storage] = lambda: storage

    with TestClient(app) as client:
        yield client, Session, provider, storage, ana_id, beto_id

    app.dependency_overrides.clear()


AUTH = {"Authorization": "Bearer token-ana"}
BETO_AUTH = {"Authorization": "Bearer token-beto"}


def _payload(key: str, prompt: str = "um gato astronauta") -> dict:
    return {
        "prompt": prompt,
        "style": "cyberpunk",
        "size": "1024x1024",
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
            select(CreditLedgerEntry.kind)
            .where(CreditLedgerEntry.user_id == user_id)
            .order_by(CreditLedgerEntry.created_at, CreditLedgerEntry.id)
        ).scalars().all()
        return list(rows)
    finally:
        session.close()


def test_generate_image_happy_path(ctx):
    client, Session, provider, storage, ana_id, _ = ctx

    response = client.post("/generations/image", json=_payload("key-happy-001"), headers=AUTH)

    assert response.status_code == 201, response.text
    body = response.json()
    assert body["status"] == "completed"
    assert body["type"] == "image"
    assert body["provider"] == "fake"
    assert body["cost_credits"] == 10
    assert body["prompt"] == "um gato astronauta"
    assert body["media_url"] == f"/media/{ana_id}/{body['id']}.png"
    assert body["error_message"] is None
    assert provider.calls == 1

    balance = _balance(Session, ana_id)
    assert (balance.balance, balance.reserved, balance.available) == (20, 0, 20)
    assert _kinds(Session, ana_id) == ["grant", "reserve", "commit"]
    assert storage.url_for(f"{ana_id}/{body['id']}.png") == body["media_url"]


def test_generate_image_is_idempotent(ctx):
    client, Session, provider, _, ana_id, _ = ctx
    payload = _payload("key-idempotent-001")

    first = client.post("/generations/image", json=payload, headers=AUTH)
    second = client.post("/generations/image", json=payload, headers=AUTH)

    assert first.status_code == second.status_code == 201
    assert first.json()["id"] == second.json()["id"]
    assert provider.calls == 1
    assert _balance(Session, ana_id).available == 20
    assert _kinds(Session, ana_id) == ["grant", "reserve", "commit"]


def test_provider_error_refunds_and_marks_failure(ctx):
    client, Session, provider, storage, ana_id, _ = ctx
    provider.error = ImageProviderUnavailable("O provedor não conseguiu gerar a imagem.")

    response = client.post("/generations/image", json=_payload("key-error-001"), headers=AUTH)

    assert response.status_code == 502, response.text
    assert "não conseguiu" in response.json()["detail"]
    assert _balance(Session, ana_id).available == 30
    assert _kinds(Session, ana_id) == ["grant", "reserve", "refund"]
    assert not list(storage.root.rglob("*.png"))

    session = Session()
    try:
        row = session.execute(select(Generation)).scalar_one()
        assert row.status == "failed"
        assert row.error_message
        assert row.storage_path is None
    finally:
        session.close()


def test_gateway_timeout_refunds(monkeypatch, ctx):
    client, Session, provider, _, ana_id, _ = ctx
    monkeypatch.setattr(settings, "image_gateway_timeout_seconds", 0.01)
    provider.delay = 0.05

    response = client.post("/generations/image", json=_payload("key-timeout-001"), headers=AUTH)

    assert response.status_code == 504, response.text
    assert "créditos foram devolvidos" in response.json()["detail"]
    assert _balance(Session, ana_id).available == 30
    assert _kinds(Session, ana_id) == ["grant", "reserve", "refund"]


def test_insufficient_credits_does_not_reserve(ctx):
    client, Session, provider, _, _, beto_id = ctx

    response = client.post(
        "/generations/image", json=_payload("key-poor-001"), headers=BETO_AUTH
    )

    assert response.status_code == 402, response.text
    assert provider.calls == 0
    assert _balance(Session, beto_id).available == 0
    assert _kinds(Session, beto_id) == []


def test_feature_flag_off_skips_reservation(monkeypatch, ctx):
    client, Session, provider, _, ana_id, _ = ctx
    monkeypatch.setattr(settings, "image_generation_enabled", False)

    response = client.post("/generations/image", json=_payload("key-flag-001"), headers=AUTH)

    assert response.status_code == 503, response.text
    assert "indisponível" in response.json()["detail"]
    assert provider.calls == 0
    assert _kinds(Session, ana_id) == []


def test_cost_always_comes_from_config(ctx):
    client, Session, provider, _, ana_id, _ = ctx
    session = Session()
    try:
        config = session.execute(
            select(CostConfig).where(CostConfig.operation == "image")
        ).scalar_one()
        config.credits = 25
        session.commit()
    finally:
        session.close()

    response = client.post("/generations/image", json=_payload("key-cost-001"), headers=AUTH)

    assert response.status_code == 201, response.text
    assert response.json()["cost_credits"] == 25
    assert _balance(Session, ana_id).available == 5
    assert provider.calls == 1


def test_list_get_and_delete_gallery(ctx):
    client, Session, provider, storage, ana_id, beto_id = ctx
    first = client.post("/generations/image", json=_payload("key-gallery-001"), headers=AUTH)
    second = client.post("/generations/image", json=_payload("key-gallery-002"), headers=AUTH)
    assert first.status_code == second.status_code == 201
    first_id = first.json()["id"]
    second_id = second.json()["id"]

    listing = client.get("/generations?type=image", headers=AUTH)
    assert listing.status_code == 200, listing.text
    assert {item["id"] for item in listing.json()} == {first_id, second_id}

    detail = client.get(f"/generations/{first_id}", headers=AUTH)
    assert detail.status_code == 200
    assert detail.json()["media_url"].startswith("/media/")

    foreign = client.get(f"/generations/{first_id}", headers=BETO_AUTH)
    assert foreign.status_code == 404
    invalid = client.get("/generations/not-a-uuid", headers=AUTH)
    assert invalid.status_code == 404

    before_delete = _balance(Session, ana_id)
    deleted = client.delete(f"/generations/{second_id}", headers=AUTH)
    assert deleted.status_code == 204
    assert client.get(f"/generations/{second_id}", headers=AUTH).status_code == 404
    assert not (storage.root / str(ana_id) / f"{second_id}.png").exists()
    assert _balance(Session, ana_id) == before_delete  # delete não estorna


def test_costs_endpoint_exposes_backend_prices(ctx):
    client, *_ = ctx

    response = client.get("/credits/costs", headers=AUTH)

    assert response.status_code == 200, response.text
    costs = {item["operation"]: item for item in response.json()}
    assert costs["image"]["credits"] == 10
    assert costs["image"]["enabled"] is True
    assert costs["video"]["credits"] == 50
    assert costs["animate_photo"]["credits"] == 20


def test_video_still_contracted_but_not_implemented(ctx):
    client, *_ = ctx

    response = client.post(
        "/generations/video",
        json={"prompt": "um vídeo", "idempotency_key": "key-video-001"},
        headers=AUTH,
    )

    assert response.status_code == 501
