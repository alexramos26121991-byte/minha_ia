"""Rotas administrativas — ajuste auditado implementado na E3; demais na E8."""

import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.admin.schemas import CostConfigOut, CreditAdjustmentIn
from app.core.database import get_db
from app.core.deps import get_admin_user
from app.core.errors import not_implemented
from app.credits.schemas import BalanceOut
from app.credits.service import CreditService, InsufficientCredits
from app.generation.schemas import GenerationOut
from app.payments.schemas import PaymentOut
from app.users.model import User
from app.users.schemas import UserOut

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get(
    "/users",
    response_model=list[UserOut],
    operation_id="adminListUsers",
    summary="Lista usuários (somente admin)",
)
async def admin_list_users(
    db: Session = Depends(get_db),
    admin_id: str = Depends(get_admin_user),
) -> list[UserOut]:
    raise not_implemented("E8")


@router.get(
    "/generations",
    response_model=list[GenerationOut],
    operation_id="adminListGenerations",
    summary="Lista gerações (somente admin)",
)
async def admin_list_generations(
    db: Session = Depends(get_db),
    admin_id: str = Depends(get_admin_user),
) -> list[GenerationOut]:
    raise not_implemented("E8")


@router.get(
    "/payments",
    response_model=list[PaymentOut],
    operation_id="adminListPayments",
    summary="Lista pagamentos (somente admin)",
)
async def admin_list_payments(
    db: Session = Depends(get_db),
    admin_id: str = Depends(get_admin_user),
) -> list[PaymentOut]:
    raise not_implemented("E8")


@router.patch(
    "/users/{user_id}/credits",
    response_model=BalanceOut,
    operation_id="adminAdjustCredits",
    summary="Ajusta créditos manualmente (auditado)",
)
async def admin_adjust_credits(
    user_id: str,
    payload: CreditAdjustmentIn,
    db: Session = Depends(get_db),
    admin: User = Depends(get_admin_user),
) -> BalanceOut:
    try:
        target_id = uuid.UUID(user_id)
    except ValueError as exc:
        raise HTTPException(
            status_code=422,
            detail="user_id deve ser um UUID válido.",
        ) from exc

    if payload.user_id != target_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="O user_id do corpo deve corresponder ao da URL.",
        )

    target = db.execute(select(User).where(User.id == target_id)).scalar_one_or_none()
    if target is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuário não encontrado.",
        )

    try:
        return CreditService.adjust(
            db,
            target_id,
            payload.amount,
            payload.reason,
            audit_admin_id=admin.firebase_uid,
        )
    except (InsufficientCredits, ValueError) as exc:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=str(exc),
        ) from exc


@router.get(
    "/costs",
    response_model=list[CostConfigOut],
    operation_id="adminListCosts",
    summary="Lista tabela mestre de custo (ADR 0003)",
)
async def admin_list_costs(
    db: Session = Depends(get_db),
    admin: User = Depends(get_admin_user),
) -> list[CostConfigOut]:
    configs = CreditService.list_costs(db)
    return [
        CostConfigOut(operation=row.operation, credits=row.credits, enabled=row.enabled)
        for row in configs
    ]
