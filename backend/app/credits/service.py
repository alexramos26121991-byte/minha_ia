"""CreditService — reserva, confirmação, estorno e reconciliação de créditos.

Regras de ouro:

* o saldo nunca fica negativo quando ``CREDITS_ENFORCED=true``;
* reserva/confirmação/estorno são idempotentes por ``idempotency_key``;
* o ledger é append-only — nunca há UPDATE ou DELETE em ``credit_ledger``;
* custos são lidos de ``cost_config``, nunca recebidos do cliente.

Modelo de saldo: ``balance`` é o total pertencente ao usuário, ``reserved`` é o
bloqueio de operações em voo e ``available = balance - reserved``. O ledger
registra a variação de ``available``; ``balance_after`` é o disponível após o
lançamento.
"""

from __future__ import annotations

import logging
import uuid
from datetime import timedelta

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.admin.model import AdminAuditLog, CostConfig
from app.core.config import settings
from app.credits.model import CreditAccount, CreditLedgerEntry, utcnow
from app.credits.schemas import BalanceOut, LedgerEntryOut
from app.plans.model import Plan
from app.users.model import User

logger = logging.getLogger(__name__)

RESERVE = "reserve"
COMMIT = "commit"
REFUND = "refund"
GRANT = "grant"
ADJUST = "adjust"


class CreditError(Exception):
    """Base dos erros de negócio do motor de créditos."""


class InsufficientCredits(CreditError):
    """Saldo disponível insuficiente para a operação."""


class ReservationNotFound(CreditError):
    """A chave de idempotência não corresponde a uma reserva."""


class ReservationAlreadySettled(CreditError):
    """A reserva já foi confirmada ou estornada."""


class CostNotConfigured(CreditError):
    """Operação ausente ou desabilitada na tabela mestre de custos."""


def _available(account: CreditAccount) -> int:
    return account.balance - account.reserved


def _find_entry(db: Session, key: str) -> CreditLedgerEntry | None:
    return db.execute(
        select(CreditLedgerEntry).where(CreditLedgerEntry.idempotency_key == key)
    ).scalar_one_or_none()


def _append(
    db: Session,
    *,
    user_id: uuid.UUID,
    amount: int,
    reason: str,
    kind: str,
    balance_after: int,
    idempotency_key: str,
    reservation_key: str | None = None,
) -> CreditLedgerEntry:
    entry = CreditLedgerEntry(
        id=uuid.uuid4(),
        user_id=user_id,
        amount=amount,
        reason=reason[:200],
        kind=kind,
        balance_after=balance_after,
        idempotency_key=idempotency_key[:160],
        reservation_key=reservation_key[:160] if reservation_key else None,
    )
    db.add(entry)
    return entry


def _ensure_account(db: Session, user_id: uuid.UUID) -> CreditAccount:
    """Cria a conta na primeira uso, creditando os créditos do plano do usuário."""
    account = db.execute(
        select(CreditAccount).where(CreditAccount.user_id == user_id)
    ).scalar_one_or_none()
    if account is not None:
        return account

    user = db.execute(select(User).where(User.id == user_id)).scalar_one_or_none()
    grant = 0
    reason = "crédito inicial"
    plan_slug = "sem-plano"
    if user is not None and user.plan_id is not None:
        plan = db.get(Plan, user.plan_id)
        if plan is not None:
            grant = plan.monthly_credits
            plan_slug = plan.slug
            reason = f"créditos do plano {plan.slug}"

    key = f"grant:plan:{user_id}:{plan_slug}"
    account = CreditAccount(user_id=user_id, balance=grant, reserved=0)
    db.add(account)
    db.flush()
    if grant and _find_entry(db, key) is None:
        _append(
            db,
            user_id=user_id,
            amount=grant,
            reason=reason,
            kind=GRANT,
            balance_after=grant,
            idempotency_key=key,
        )
    db.commit()
    db.refresh(account)
    return account


def _lock_account(db: Session, user_id: uuid.UUID) -> CreditAccount:
    """Bloqueia a linha para serializar reservas concorrentes.

    Em SQLite o ``FOR UPDATE`` é ignorado, mas os testes são sequenciais e a
    constraint de unicidade do ledger garante a idempotência.
    """
    return db.execute(
        select(CreditAccount).where(CreditAccount.user_id == user_id).with_for_update()
    ).scalar_one()


def _reservation_for(db: Session, idempotency_key: str) -> CreditLedgerEntry:
    entry = _find_entry(db, idempotency_key)
    if entry is None or entry.kind != RESERVE:
        raise ReservationNotFound("Reserva não encontrada para esta chave.")
    return entry


class CreditService:
    """Operações de crédito — todas transacionais e auditáveis."""

    @staticmethod
    def get_balance(db: Session, user_id: uuid.UUID) -> BalanceOut:
        account = _ensure_account(db, user_id)
        return BalanceOut(
            user_id=user_id,
            balance=account.balance,
            reserved=account.reserved,
            available=_available(account),
        )

    @staticmethod
    def list_ledger(
        db: Session, user_id: uuid.UUID, limit: int = 50, offset: int = 0
    ) -> list[LedgerEntryOut]:
        rows = db.execute(
            select(CreditLedgerEntry)
            .where(CreditLedgerEntry.user_id == user_id)
            .order_by(CreditLedgerEntry.created_at.desc(), CreditLedgerEntry.id.desc())
            .limit(limit)
            .offset(offset)
        ).scalars().all()
        return [LedgerEntryOut.model_validate(row) for row in rows]

    @staticmethod
    def reserve(
        db: Session,
        user_id: uuid.UUID,
        amount: int,
        idempotency_key: str,
        reason: str = "reserva de créditos",
    ) -> LedgerEntryOut:
        """Bloqueia ``amount`` créditos. Repetir a chave não debita duas vezes."""
        if amount <= 0:
            raise ValueError("O valor da reserva deve ser positivo.")
        if not idempotency_key:
            raise ValueError("idempotency_key é obrigatória.")

        existing = _find_entry(db, idempotency_key)
        if existing is not None:
            return LedgerEntryOut.model_validate(existing)

        _ensure_account(db, user_id)
        account = _lock_account(db, user_id)
        available = _available(account)
        if available < amount:
            if settings.credits_enforced:
                raise InsufficientCredits(
                    f"Créditos insuficientes: {available} disponíveis, {amount} necessários."
                )
            logger.warning(
                "CREDITS_ENFORCED=false: reserva %s acima do saldo de %s (usuário %s)",
                amount,
                available,
                user_id,
            )

        account.reserved += amount
        entry = _append(
            db,
            user_id=user_id,
            amount=-amount,
            reason=reason,
            kind=RESERVE,
            balance_after=_available(account),
            idempotency_key=idempotency_key,
            reservation_key=idempotency_key,
        )
        db.commit()
        db.refresh(entry)
        return LedgerEntryOut.model_validate(entry)

    @staticmethod
    def commit(db: Session, idempotency_key: str) -> BalanceOut:
        """Consome a reserva. Segunda chamada é um no-op idempotente."""
        reservation = _reservation_for(db, idempotency_key)
        key = f"{COMMIT}:{idempotency_key}"
        if _find_entry(db, key) is not None:
            return CreditService.get_balance(db, reservation.user_id)
        if _find_entry(db, f"{REFUND}:{idempotency_key}") is not None:
            raise ReservationAlreadySettled("Esta reserva já foi estornada.")

        amount = -reservation.amount
        account = _lock_account(db, reservation.user_id)
        account.balance -= amount
        account.reserved = max(0, account.reserved - amount)
        _append(
            db,
            user_id=reservation.user_id,
            amount=0,
            reason=f"confirmação: {reservation.reason}",
            kind=COMMIT,
            balance_after=_available(account),
            idempotency_key=key,
            reservation_key=idempotency_key,
        )
        db.commit()
        return CreditService.get_balance(db, reservation.user_id)

    @staticmethod
    def refund(
        db: Session, idempotency_key: str, reason: str = "estorno de reserva"
    ) -> BalanceOut:
        """Devolve a reserva ao saldo disponível. Idempotente por chave."""
        reservation = _reservation_for(db, idempotency_key)
        key = f"{REFUND}:{idempotency_key}"
        if _find_entry(db, key) is not None:
            return CreditService.get_balance(db, reservation.user_id)
        if _find_entry(db, f"{COMMIT}:{idempotency_key}") is not None:
            raise ReservationAlreadySettled("Esta reserva já foi confirmada.")

        amount = -reservation.amount
        account = _lock_account(db, reservation.user_id)
        account.reserved = max(0, account.reserved - amount)
        _append(
            db,
            user_id=reservation.user_id,
            amount=amount,
            reason=reason,
            kind=REFUND,
            balance_after=_available(account),
            idempotency_key=key,
            reservation_key=idempotency_key,
        )
        db.commit()
        return CreditService.get_balance(db, reservation.user_id)

    @staticmethod
    def adjust(
        db: Session,
        user_id: uuid.UUID,
        amount: int,
        reason: str,
        *,
        audit_admin_id: str | None = None,
    ) -> BalanceOut:
        """Ajuste manual (admin). Negativo debita, positivo credita.

        Quando ``audit_admin_id`` é informado, o lançamento e o log de auditoria
        entram no mesmo commit — nunca existe ajuste sem trilha.
        """
        if amount == 0:
            raise ValueError("O ajuste não pode ser zero.")

        _ensure_account(db, user_id)
        account = _lock_account(db, user_id)
        new_available = _available(account) + amount
        if new_available < 0 and settings.credits_enforced:
            raise InsufficientCredits(
                f"Créditos insuficientes: {_available(account)} disponíveis, "
                f"{abs(amount)} necessários."
            )

        account.balance += amount
        _append(
            db,
            user_id=user_id,
            amount=amount,
            reason=reason,
            kind=ADJUST,
            balance_after=new_available,
            idempotency_key=f"admin:{uuid.uuid4()}",
        )
        if audit_admin_id is not None:
            db.add(
                AdminAuditLog(
                    id=uuid.uuid4(),
                    admin_id=audit_admin_id,
                    action="adjust_credits",
                    target_user_id=user_id,
                    payload={"amount": amount, "reason": reason},
                )
            )
        db.commit()
        return CreditService.get_balance(db, user_id)

    @staticmethod
    def get_cost_credits(db: Session, operation: str) -> int:
        """Custo vem sempre da tabela mestre — nunca do payload do cliente."""
        config = db.execute(
            select(CostConfig).where(CostConfig.operation == operation)
        ).scalar_one_or_none()
        if config is None or not config.enabled:
            raise CostNotConfigured(f"Operação {operation!r} sem custo configurado.")
        return config.credits

    @staticmethod
    def list_costs(db: Session) -> list[CostConfig]:
        return list(db.execute(select(CostConfig).order_by(CostConfig.operation)).scalars().all())

    @staticmethod
    def reconcile_orphan_reservations(
        db: Session, stale_minutes: int | None = None
    ) -> int:
        """Estorna reservas sem commit/estorno após o prazo configurado.

        Chamada pelo task Celery a cada ``RECONCILE_INTERVAL_SECONDS``.
        """
        minutes = settings.reconcile_stale_minutes if stale_minutes is None else stale_minutes
        cutoff = utcnow() - timedelta(minutes=minutes)
        reserves = db.execute(
            select(CreditLedgerEntry).where(
                CreditLedgerEntry.kind == RESERVE,
                CreditLedgerEntry.created_at < cutoff,
            )
        ).scalars().all()
        if not reserves:
            return 0

        keys = [entry.reservation_key for entry in reserves if entry.reservation_key]
        if not keys:
            return 0
        settled = set(
            db.execute(
                select(CreditLedgerEntry.reservation_key).where(
                    CreditLedgerEntry.reservation_key.in_(keys),
                    CreditLedgerEntry.kind.in_([COMMIT, REFUND]),
                )
            ).scalars().all()
        )

        reclaimed = 0
        for entry in reserves:
            if entry.reservation_key in settled:
                continue
            try:
                CreditService.refund(
                    db,
                    entry.reservation_key,
                    reason="estorno automático de reserva órfã",
                )
                reclaimed += 1
            except ReservationAlreadySettled:
                continue
        if reclaimed:
            logger.info("Reconciliação estornou %s reserva(s) órfã(s).", reclaimed)
        return reclaimed
