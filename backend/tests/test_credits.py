"""Testes da E3 — motor de créditos, idempotência e reconciliação."""

from __future__ import annotations

import uuid
from datetime import timedelta
from decimal import Decimal

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, select, text
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.admin.model import AdminAuditLog, CostConfig
from app.credits.model import CreditLedgerEntry
from app.credits.service import (
    CostNotConfigured,
    CreditService,
    InsufficientCredits,
    ReservationAlreadySettled,
    ReservationNotFound,
)
from app.credits.tasks import reconcile_orphan_reservations_task
from app.core.config import settings
from app.core.database import Base, get_db
from app.core.security import AuthError, VerifiedIdentity, get_verifier
from app.generation.model import Generation  # noqa: F401 — registra a tabela no Base.metadata
from app.main import app
from app.payments.model import Payment, WebhookEvent  # noqa: F401 — idem
from app.plans.model import Plan
from app.users.model import User

FREE_PLAN_ID = uuid.UUID("11111111-1111-4111-8111-111111111111")


class FakeVerifier:
    def __init__(self) -> None:
        self.identity = VerifiedIdentity(
            uid="firebase-uid-ana", email="ana@example.com", display_name="Ana"
        )

    def verify(self, token: str) -> VerifiedIdentity:
        if token == "token-invalido":
            raise AuthError("ID token inválido.")
        if token == "token-admin":
            return VerifiedIdentity(
                uid="firebase-uid-admin",
                email="admin@example.com",
                display_name="Admin",
            )
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
            id=FREE_PLAN_ID,
            slug="gratuito",
            name="Gratuito",
            monthly_credits=30,
            price_brl=Decimal("0.00"),
            recurrence="monthly",
            is_active=True,
            sort_order=0,
        )
    )
    seed.add_all(
        [
            User(
                id=uuid.uuid4(),
                firebase_uid="firebase-uid-ana",
                email="ana@example.com",
                plan_id=FREE_PLAN_ID,
            ),
            User(
                id=uuid.uuid4(),
                firebase_uid="firebase-uid-admin",
                email="admin@example.com",
                plan_id=FREE_PLAN_ID,
                role="admin",
            ),
        ]
    )
    seed.add_all(
        [
            CostConfig(operation="image", credits=10, enabled=True),
            CostConfig(operation="video", credits=50, enabled=True),
            CostConfig(operation="animate_photo", credits=20, enabled=True),
        ]
    )
    seed.commit()
    ana_id = seed.execute(
        select(User.id).where(User.firebase_uid == "firebase-uid-ana")
    ).scalar_one()
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
        yield client, Session, verifier, ana_id

    app.dependency_overrides.clear()


AUTH = {"Authorization": "Bearer token-ana"}
ADMIN_AUTH = {"Authorization": "Bearer token-admin"}


def _session(Session):
    return Session()


def _ledger_count(db, user_id):
    return len(
        db.execute(
            select(CreditLedgerEntry).where(CreditLedgerEntry.user_id == user_id)
        ).scalars().all()
    )


# --- saldo e ledger -------------------------------------------------------


def test_saldo_inicial_vem_do_plano(ctx):
    client, Session, _, ana_id = ctx
    response = client.get("/credits/balance", headers=AUTH)
    assert response.status_code == 200, response.text
    assert response.json() == {
        "user_id": str(ana_id),
        "balance": 30,
        "reserved": 0,
        "available": 30,
    }
    db = _session(Session)
    entries = db.execute(
        select(CreditLedgerEntry).where(CreditLedgerEntry.user_id == ana_id)
    ).scalars().all()
    assert len(entries) == 1
    assert entries[0].kind == "grant"
    assert entries[0].amount == 30
    db.close()


def test_ledger_e_paginado_e_tem_kind(ctx):
    client, _, _, ana_id = ctx
    # Gera um lançamento extra para garantir mais de uma página.
    assert client.patch(
        f"/admin/users/{ana_id}/credits",
        json={
            "user_id": str(ana_id),
            "amount": 1,
            "reason": "ajuste para paginação",
        },
        headers=ADMIN_AUTH,
    ).status_code == 200

    first = client.get("/credits/ledger?limit=1&offset=0", headers=AUTH)
    second = client.get("/credits/ledger?limit=1&offset=1", headers=AUTH)
    assert first.status_code == 200 and second.status_code == 200
    assert len(first.json()) == 1
    assert len(second.json()) == 1
    assert first.json()[0]["id"] != second.json()[0]["id"]
    assert "kind" in first.json()[0]


# --- reserva / commit / estorno ------------------------------------------


def test_reserva_commit_debita_uma_unica_vez(ctx):
    client, Session, _, ana_id = ctx
    db = _session(Session)

    reservation = CreditService.reserve(db, ana_id, 5, "img-abc123", "gerar imagem")
    assert reservation.amount == -5
    assert CreditService.get_balance(db, ana_id).available == 25
    assert CreditService.get_balance(db, ana_id).reserved == 5

    committed = CreditService.commit(db, "img-abc123")
    assert (committed.balance, committed.reserved, committed.available) == (25, 0, 25)
    # Segunda confirmação não altera nada.
    again = CreditService.commit(db, "img-abc123")
    assert again == committed
    assert _ledger_count(db, ana_id) == 3  # grant + reserve + commit
    db.close()


def test_reserva_com_mesma_chave_e_idempotente(ctx):
    _, Session, _, ana_id = ctx
    db = _session(Session)

    CreditService.reserve(db, ana_id, 5, "mesma-chave")
    second = CreditService.reserve(db, ana_id, 5, "mesma-chave")
    assert second.amount == -5
    balance = CreditService.get_balance(db, ana_id)
    assert (balance.balance, balance.reserved, balance.available) == (30, 5, 25)
    assert _ledger_count(db, ana_id) == 2
    db.close()


def test_estorno_devolve_exatamente_o_reservado(ctx):
    _, Session, _, ana_id = ctx
    db = _session(Session)

    CreditService.reserve(db, ana_id, 8, "vid-xyz789")
    refunded = CreditService.refund(db, "vid-xyz789", "provedor falhou")
    assert (refunded.balance, refunded.reserved, refunded.available) == (30, 0, 30)
    entries = db.execute(
        select(CreditLedgerEntry).where(CreditLedgerEntry.kind == "refund")
    ).scalars().all()
    assert len(entries) == 1
    assert entries[0].amount == 8
    assert "provedor falhou" in entries[0].reason
    assert CreditService.refund(db, "vid-xyz789") == refunded  # no-op
    db.close()


def test_confirmar_apos_estorno_e_bloqueado(ctx):
    _, Session, _, ana_id = ctx
    db = _session(Session)
    CreditService.reserve(db, ana_id, 4, "chave-estornada")
    CreditService.refund(db, "chave-estornada")
    with pytest.raises(ReservationAlreadySettled):
        CreditService.commit(db, "chave-estornada")
    db.close()


def test_estornar_apos_confirmar_e_bloqueado(ctx):
    _, Session, _, ana_id = ctx
    db = _session(Session)
    CreditService.reserve(db, ana_id, 4, "chave-confirmada")
    CreditService.commit(db, "chave-confirmada")
    with pytest.raises(ReservationAlreadySettled):
        CreditService.refund(db, "chave-confirmada")
    db.close()


def test_chave_de_reserva_inexistente_e_bloqueada(ctx):
    _, Session, _, _ = ctx
    db = _session(Session)
    with pytest.raises(ReservationNotFound):
        CreditService.commit(db, "nao-existe")
    with pytest.raises(ReservationNotFound):
        CreditService.refund(db, "nao-existe")
    db.close()


def test_valores_invalidos_sao_rejeitados(ctx):
    _, Session, _, ana_id = ctx
    db = _session(Session)
    with pytest.raises(ValueError):
        CreditService.reserve(db, ana_id, 0, "chave-zero")
    with pytest.raises(ValueError):
        CreditService.reserve(db, ana_id, 1, "")
    with pytest.raises(ValueError):
        CreditService.adjust(db, ana_id, 0, "ajuste zero")
    db.close()


def test_saldo_insuficiente_bloqueia_reserva(ctx):
    _, Session, _, ana_id = ctx
    db = _session(Session)

    with pytest.raises(InsufficientCredits):
        CreditService.reserve(db, ana_id, 31, "chave-grande")
    balance = CreditService.get_balance(db, ana_id)
    assert (balance.balance, balance.reserved, balance.available) == (30, 0, 30)
    assert _ledger_count(db, ana_id) == 1
    db.close()


def test_modo_auditoria_permite_saldo_negativo(ctx, monkeypatch):
    _, Session, _, ana_id = ctx
    monkeypatch.setattr(settings, "credits_enforced", False)
    db = _session(Session)
    reservation = CreditService.reserve(db, ana_id, 100, "auditoria")
    assert reservation.balance_after == -70
    assert CreditService.get_balance(db, ana_id).available == -70
    db.close()


# --- reconciliação --------------------------------------------------------


def _envelhecer_reserva(db, chave: str, minutos: int):
    db.execute(
        text(
            "UPDATE credit_ledger SET created_at = datetime('now', :delta) "
            "WHERE idempotency_key = :key"
        ),
        {"delta": f"-{minutos} minutes", "key": chave},
    )
    db.commit()


def test_reconciliacao_estorna_apenas_reservas_orfa(ctx):
    _, Session, _, ana_id = ctx
    db = _session(Session)

    CreditService.reserve(db, ana_id, 7, "orfa-antiga")
    CreditService.reserve(db, ana_id, 3, "fresca")
    _envelhecer_reserva(db, "orfa-antiga", 120)

    recovered = CreditService.reconcile_orphan_reservations(db, stale_minutes=30)
    assert recovered == 1

    balance = CreditService.get_balance(db, ana_id)
    assert (balance.balance, balance.reserved, balance.available) == (30, 3, 27)
    # A reserva órfã tem estorno; a fresca permanece intocada.
    assert CreditService.refund(db, "orfa-antiga") == CreditService.get_balance(db, ana_id)
    assert db.execute(
        select(CreditLedgerEntry.idempotency_key).where(
            CreditLedgerEntry.idempotency_key == "refund:fresca"
        )
    ).scalar_one_or_none() is None
    db.close()


def test_reconciliacao_ignora_reserva_confirmada(ctx):
    _, Session, _, ana_id = ctx
    db = _session(Session)

    CreditService.reserve(db, ana_id, 6, "confirmada-antiga")
    CreditService.commit(db, "confirmada-antiga")
    _envelhecer_reserva(db, "confirmada-antiga", 120)
    _envelhecer_reserva(db, "commit:confirmada-antiga", 120)

    assert CreditService.reconcile_orphan_reservations(db, stale_minutes=30) == 0
    balance = CreditService.get_balance(db, ana_id)
    assert (balance.balance, balance.reserved, balance.available) == (24, 0, 24)
    db.close()


def test_reconciliacao_sem_reservas_retorna_zero(ctx):
    _, Session, _, ana_id = ctx
    db = _session(Session)
    assert CreditService.reconcile_orphan_reservations(db, stale_minutes=-1) == 0
    assert CreditService.get_balance(db, ana_id).balance == 30
    db.close()


def test_task_de_reconciliacao_esta_agendada():
    assert reconcile_orphan_reservations_task.name == "credits.reconcile_orphan_reservations"
    from app.core.celery_app import celery_app

    beat = celery_app.conf.beat_schedule["reconcile-orphan-reservations"]
    assert beat["task"] == "credits.reconcile_orphan_reservations"
    assert beat["schedule"] == float(settings.reconcile_interval_seconds)


def test_task_de_reconciliacao_executa_estorno(ctx, monkeypatch):
    _, Session, _, ana_id = ctx
    db = _session(Session)
    CreditService.reserve(db, ana_id, 2, "task-orfa")
    _envelhecer_reserva(db, "task-orfa", 120)
    db.close()

    # A task usa SessionLocal; trocamos pela sessão do fixture SQLite.
    monkeypatch.setattr("app.credits.tasks.SessionLocal", Session)
    assert reconcile_orphan_reservations_task(stale_minutes=30) == 1

    db = _session(Session)
    assert CreditService.get_balance(db, ana_id).available == 30
    db.close()


# --- admin e custos -------------------------------------------------------


def test_admin_pode_ajustar_creditos_com_auditoria(ctx):
    client, Session, _, ana_id = ctx
    response = client.patch(
        f"/admin/users/{ana_id}/credits",
        json={"user_id": str(ana_id), "amount": 10, "reason": "bônus de teste"},
        headers=ADMIN_AUTH,
    )
    assert response.status_code == 200, response.text
    assert response.json()["balance"] == 40

    db = _session(Session)
    logs = db.execute(select(AdminAuditLog)).scalars().all()
    assert len(logs) == 1
    assert logs[0].admin_id == "firebase-uid-admin"
    assert logs[0].target_user_id == ana_id
    assert logs[0].payload["reason"] == "bônus de teste"
    db.close()


def test_ajuste_negativo_nao_deixa_saldo_negativo(ctx):
    client, _, _, ana_id = ctx
    response = client.patch(
        f"/admin/users/{ana_id}/credits",
        json={"user_id": str(ana_id), "amount": -100, "reason": "estorno indevido"},
        headers=ADMIN_AUTH,
    )
    assert response.status_code == 409, response.text
    assert client.get("/credits/balance", headers=AUTH).json()["balance"] == 30


def test_usuario_comum_nao_pode_ajustar_creditos(ctx):
    client, _, _, ana_id = ctx
    response = client.patch(
        f"/admin/users/{ana_id}/credits",
        json={"user_id": str(ana_id), "amount": 10, "reason": "tentativa indevida"},
        headers=AUTH,
    )
    assert response.status_code == 403, response.text


def test_ajuste_com_ids_divergentes_e_target_inexistente(ctx):
    client, _, _, ana_id = ctx
    body = {"user_id": str(ana_id), "amount": 1, "reason": "teste de validação"}
    mismatch = client.patch(
        f"/admin/users/{uuid.uuid4()}/credits", json=body, headers=ADMIN_AUTH
    )
    assert mismatch.status_code == 400, mismatch.text

    unknown_id = uuid.uuid4()
    unknown = client.patch(
        f"/admin/users/{unknown_id}/credits",
        json={**body, "user_id": str(unknown_id)},
        headers=ADMIN_AUTH,
    )
    assert unknown.status_code == 404, unknown.text

    invalid = client.patch(
        "/admin/users/nao-uuid/credits",
        json={**body, "user_id": str(uuid.uuid4())},
        headers=ADMIN_AUTH,
    )
    assert invalid.status_code == 422, invalid.text


def test_custo_vem_da_tabela_mestre(ctx):
    client, Session, _, _ = ctx
    response = client.get("/admin/costs", headers=ADMIN_AUTH)
    assert response.status_code == 200, response.text
    costs = {row["operation"]: row for row in response.json()}
    assert costs["image"]["credits"] == 10
    assert costs["video"]["credits"] == 50
    assert costs["animate_photo"]["credits"] == 20

    db = _session(Session)
    assert CreditService.get_cost_credits(db, "image") == 10
    with pytest.raises(CostNotConfigured):
        CreditService.get_cost_credits(db, "operacao-inexistente")
    db.close()


def test_rotas_de_creditos_exigem_sessao(ctx):
    client, _, _, _ = ctx
    assert client.get("/credits/balance").status_code == 401
    assert client.get("/credits/ledger").status_code == 401
