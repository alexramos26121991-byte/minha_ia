"""Testes de seleção de provedor (D2) e verificação de webhook do fal.ai.

Cobre os três pontos pendentes do D2:

* ``get_video_provider``: auto/falai/mock e fail-closed em produção;
* ``FalWebhookVerifier``: JWKS Ed25519, timestamp, headers ausentes e corpo
  adulterado;
* ``register_event``: idempotência na tabela ``webhook_events``.
"""

from __future__ import annotations

import time

import httpx
import pytest
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool

from app.core import config as config_module
from app.generation import deps as deps_module
from app.generation.providers.falai import FalVideoProvider
from app.generation.providers.mock_video import MockVideoProvider
from app.generation.providers.video_base import VideoProviderUnavailable
from app.generation.webhook import FalWebhookVerifier
from app.generation.webhook_events import register_event
from app.payments.model import WebhookEvent


# ---------------------------------------------------------------------------
# Seleção de provedor
# ---------------------------------------------------------------------------


def _settings(**overrides):
    base = config_module.Settings(
        _env_file=None,
        app_env="development",
        image_provider="mock",
        video_provider="auto",
        openai_api_key="",
        fal_api_key="",
    )
    for key, value in overrides.items():
        setattr(base, key, value)
    return base


def _patch_settings(monkeypatch: pytest.MonkeyPatch, **overrides) -> None:
    monkeypatch.setattr(deps_module.settings, "app_env", overrides.pop("app_env", "development"))
    monkeypatch.setattr(deps_module.settings, "video_provider", overrides.pop("video_provider", "auto"))
    monkeypatch.setattr(deps_module.settings, "fal_api_key", overrides.pop("fal_api_key", ""))
    for key, value in overrides.items():
        monkeypatch.setattr(deps_module.settings, key, value)


def _assert_no_settings_leak() -> None:
    # Garante que os testes não alteraram o settings global carregado no import.
    assert config_module.Settings(_env_file=None).app_env == "development"


def test_auto_sem_chave_em_dev_usa_mock(monkeypatch: pytest.MonkeyPatch) -> None:
    _patch_settings(monkeypatch, video_provider="auto", fal_api_key="")
    provider = deps_module.get_video_provider()
    assert isinstance(provider, MockVideoProvider)


def test_auto_com_chave_usa_falai(monkeypatch: pytest.MonkeyPatch) -> None:
    _patch_settings(monkeypatch, video_provider="auto", fal_api_key="key-teste")
    provider = deps_module.get_video_provider()
    assert isinstance(provider, FalVideoProvider)


def test_falai_explicito_sem_chave_levanta_503(monkeypatch: pytest.MonkeyPatch) -> None:
    _patch_settings(monkeypatch, video_provider="falai", fal_api_key="")
    with pytest.raises(Exception, match="FAL_API_KEY"):
        deps_module.get_video_provider()


def test_mock_explicito_em_producao_falha_fechado(monkeypatch: pytest.MonkeyPatch) -> None:
    _patch_settings(monkeypatch, video_provider="mock", app_env="production")
    with pytest.raises(Exception, match="não configurado para produção"):
        deps_module.get_video_provider()


def test_auto_sem_chave_em_producao_falha_fechado(monkeypatch: pytest.MonkeyPatch) -> None:
    _patch_settings(monkeypatch, video_provider="auto", app_env="production", fal_api_key="")
    with pytest.raises(Exception, match="não configurado para produção"):
        deps_module.get_video_provider()


def test_provedor_desconhecido_e_recusado(monkeypatch: pytest.MonkeyPatch) -> None:
    _patch_settings(monkeypatch, video_provider="replicate")
    with pytest.raises(Exception, match="inválido"):
        deps_module.get_video_provider()


def test_settings_helper_nao_vaza() -> None:
    _settings(fal_api_key="chave", video_provider="falai")
    _assert_no_settings_leak()


# ---------------------------------------------------------------------------
# Webhook — verificação ED25519
# ---------------------------------------------------------------------------


def _signed_headers(request_id: str, user_id: str, timestamp: str, signature: bytes) -> dict[str, str]:
    return {
        "X-Fal-Webhook-Request-Id": request_id,
        "X-Fal-Webhook-User-Id": user_id,
        "X-Fal-Webhook-Timestamp": timestamp,
        "X-Fal-Webhook-Signature": signature.hex(),
    }


def _make_verifier(private_key: Ed25519PrivateKey, **kwargs):
    public_bytes = private_key.public_key().public_bytes(
        encoding=serialization.Encoding.Raw,
        format=serialization.PublicFormat.Raw,
    )
    return FalWebhookVerifier(pinned_keys=[public_bytes], **kwargs)


def _sign(private_key: Ed25519PrivateKey, body: bytes, request_id: str, user_id: str, timestamp: str) -> bytes:
    import hashlib

    message = "\n".join(
        [request_id, user_id, timestamp, hashlib.sha256(body).hexdigest()]
    ).encode("utf-8")
    return private_key.sign(message)


def test_webhook_assinatura_valida() -> None:
    key = Ed25519PrivateKey.generate()
    body = b'{"request_id":"abc","status":"COMPLETED"}'
    timestamp = str(int(time.time()))
    signature = _sign(key, body, "req-1", "user-1", timestamp)
    verifier = _make_verifier(key)

    assert verifier.verify(_signed_headers("req-1", "user-1", timestamp, signature), body) is True


def test_webhook_corpo_adulterado_e_recusado() -> None:
    key = Ed25519PrivateKey.generate()
    body = b'{"request_id":"abc","status":"COMPLETED"}'
    timestamp = str(int(time.time()))
    signature = _sign(key, body, "req-1", "user-1", timestamp)
    verifier = _make_verifier(key)

    adulterado = body.replace(b"COMPLETED", b"FAILED")
    assert verifier.verify(_signed_headers("req-1", "user-1", timestamp, signature), adulterado) is False


def test_webhook_headers_ausentes_sao_recusados() -> None:
    key = Ed25519PrivateKey.generate()
    body = b"{}"
    timestamp = str(int(time.time()))
    signature = _sign(key, body, "req-1", "user-1", timestamp)
    headers = _signed_headers("req-1", "user-1", timestamp, signature)
    del headers["X-Fal-Webhook-Request-Id"]
    verifier = _make_verifier(key)

    assert verifier.verify(headers, body) is False


def test_webhook_timestamp_fora_da_janela_e_recusado() -> None:
    key = Ed25519PrivateKey.generate()
    body = b"{}"
    old = str(int(time.time()) - 4000)
    signature = _sign(key, body, "req-1", "user-1", old)
    verifier = _make_verifier(key, leeway_seconds=300)

    assert verifier.verify(_signed_headers("req-1", "user-1", old, signature), body) is False


def test_webhook_user_id_diferente_e_recusado() -> None:
    key = Ed25519PrivateKey.generate()
    body = b"{}"
    timestamp = str(int(time.time()))
    signature = _sign(key, body, "req-1", "user-1", timestamp)
    verifier = _make_verifier(key, expected_user_id="user-oficial")

    assert verifier.verify(_signed_headers("req-1", "user-1", timestamp, signature), body) is False


def test_webhook_assinatura_de_outra_chave_e_recusada() -> None:
    signer = Ed25519PrivateKey.generate()
    other = Ed25519PrivateKey.generate()
    body = b"{}"
    timestamp = str(int(time.time()))
    signature = _sign(signer, body, "req-1", "user-1", timestamp)
    verifier = _make_verifier(other)

    assert verifier.verify(_signed_headers("req-1", "user-1", timestamp, signature), body) is False


def test_webhook_busca_jwks_e_cacheia() -> None:
    key = Ed25519PrivateKey.generate()
    body = b"{}"
    timestamp = str(int(time.time()))
    signature = _sign(key, body, "req-1", "user-1", timestamp)
    public_bytes = key.public_key().public_bytes(
        encoding=serialization.Encoding.Raw,
        format=serialization.PublicFormat.Raw,
    )
    import base64

    jwks = {"keys": [{"kty": "OKP", "crv": "Ed25519", "x": base64.urlsafe_b64encode(public_bytes).decode().rstrip("=")}]}
    calls: list[int] = []

    def handler(_: httpx.Request) -> httpx.Response:
        calls.append(1)
        return httpx.Response(200, json=jwks)

    verifier = FalWebhookVerifier(
        jwks_url="https://rest.fal.ai/.well-known/jwks.json",
        transport=httpx.MockTransport(handler),
        cache_ttl_seconds=600,
    )
    headers = _signed_headers("req-1", "user-1", timestamp, signature)
    assert verifier.verify(headers, body) is True
    assert verifier.verify(headers, body) is True
    assert len(calls) == 1


# ---------------------------------------------------------------------------
# Registro idempotente de eventos
# ---------------------------------------------------------------------------


@pytest.fixture()
def db() -> Session:
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    WebhookEvent.__table__.create(engine)
    with Session(engine) as session:
        yield session
    engine.dispose()


def test_register_event_e_idempotente(db: Session) -> None:
    payload = {"request_id": "req-123", "status": "COMPLETED"}

    assert register_event(
        db,
        provider="falai",
        external_id="req-123",
        event_type="video.completed",
        payload=payload,
    ) is True
    assert register_event(
        db,
        provider="falai",
        external_id="req-123",
        event_type="video.completed",
        payload=payload,
    ) is False
    assert db.query(WebhookEvent).count() == 1


def test_register_event_exige_external_id(db: Session) -> None:
    with pytest.raises(ValueError, match="external_id"):
        register_event(db, provider="falai", external_id="", event_type="video", payload={})
