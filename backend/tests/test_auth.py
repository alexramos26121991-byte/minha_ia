"""Testes da E2 — sessão, persistência e perfil, sem Firebase."""

from __future__ import annotations

import uuid
from decimal import Decimal

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.database import Base, get_db
from app.core.security import AuthError, VerifiedIdentity, get_verifier
from app.main import app
from app.plans.model import Plan
from app.users.model import User


class FakeVerifier:
    """Verificador determinístico para os testes."""

    def __init__(self) -> None:
        self.identity = VerifiedIdentity(
            uid="firebase-uid-ana",
            email="ana@example.com",
            display_name="Ana",
            email_verified=True,
        )

    def verify(self, token: str) -> VerifiedIdentity:
        if token == "token-invalido":
            raise AuthError("ID token inválido.")
        return self.identity


@pytest.fixture()
def ctx():
    engine = create_engine(
        "sqlite://",
        poolclass=StaticPool,
        connect_args={"check_same_thread": False},
    )
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)

    seed = Session()
    seed.add(
        Plan(
            id=uuid.UUID("11111111-1111-4111-8111-111111111111"),
            slug="gratuito",
            name="Gratuito",
            monthly_credits=30,
            price_brl=Decimal("0.00"),
            recurrence="monthly",
            is_active=True,
            sort_order=0,
        )
    )
    seed.commit()
    seed.close()

    def override_get_db():
        session = Session()
        try:
            yield session
        finally:
            session.close()

    verifier = FakeVerifier()
    app.dependency_overrides[get_db] = override_get_db
    app.dependency_overrides[get_verifier] = lambda: verifier

    with TestClient(app) as client:
        yield client, verifier, Session

    app.dependency_overrides.clear()


AUTH = {"Authorization": "Bearer token-valido"}

SESSION_BODY = {
    "fcm_token": "fcm-token-do-dispositivo",
    "consent_version": "lgpd-2026-11",
    "display_name": "Ana Souza",
}


def test_rotas_protegidas_exigem_bearer(ctx):
    client, _, _ = ctx
    response = client.post("/auth/session", json={})
    assert response.status_code == 401, response.text


def test_token_invalido_retorna_401(ctx):
    client, _, _ = ctx
    response = client.post(
        "/auth/session",
        json={},
        headers={"Authorization": "Bearer token-invalido"},
    )
    assert response.status_code == 401, response.text


def test_primeira_sessao_cria_usuario_e_registra_fcm(ctx):
    client, _, Session = ctx
    response = client.post("/auth/session", json=SESSION_BODY, headers=AUTH)
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["is_new"] is True
    assert body["plan_slug"] == "gratuito"
    assert uuid.UUID(body["user_id"])

    session = Session()
    user = session.query(User).one()
    assert user.firebase_uid == "firebase-uid-ana"
    assert user.email == "ana@example.com"
    assert user.fcm_token == "fcm-token-do-dispositivo"
    assert user.consent_version == "lgpd-2026-11"
    assert user.display_name == "Ana Souza"
    session.close()


def test_segunda_sessao_nao_e_nova(ctx):
    client, _, _ = ctx
    first = client.post("/auth/session", json=SESSION_BODY, headers=AUTH)
    second = client.post("/auth/session", json=SESSION_BODY, headers=AUTH)
    assert first.json()["user_id"] == second.json()["user_id"]
    assert second.json()["is_new"] is False


def test_perfil_antes_da_sessao_retorna_404(ctx):
    client, _, _ = ctx
    response = client.get("/users/me", headers=AUTH)
    assert response.status_code == 404, response.text


def test_get_e_patch_do_perfil(ctx):
    client, _, _ = ctx
    assert client.post("/auth/session", json=SESSION_BODY, headers=AUTH).status_code == 200

    profile = client.get("/users/me", headers=AUTH)
    assert profile.status_code == 200, profile.text
    assert profile.json()["email"] == "ana@example.com"
    assert profile.json()["display_name"] == "Ana Souza"
    assert profile.json()["plan_slug"] == "gratuito"

    updated = client.patch(
        "/users/me",
        json={"fcm_token": "novo-fcm", "display_name": "Ana Maria"},
        headers=AUTH,
    )
    assert updated.status_code == 200, updated.text
    assert updated.json()["display_name"] == "Ana Maria"

    reread = client.get("/users/me", headers=AUTH)
    assert reread.json()["display_name"] == "Ana Maria"


def test_troca_de_uid_cria_novo_usuario(ctx):
    client, verifier, _ = ctx
    assert client.post("/auth/session", json={}, headers=AUTH).json()["is_new"] is True

    verifier.identity = VerifiedIdentity(uid="firebase-uid-bia", email="bia@example.com")
    response = client.post("/auth/session", json={}, headers=AUTH)
    assert response.status_code == 200, response.text
    assert response.json()["is_new"] is True
