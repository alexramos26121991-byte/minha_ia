"""Rotas administrativas — implementação na E8, com log de auditoria."""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.admin.schemas import CostConfigOut, CreditAdjustmentIn
from app.core.database import get_db
from app.core.errors import not_implemented
from app.core.security import get_current_user_id
from app.credits.schemas import BalanceOut
from app.generation.schemas import GenerationOut
from app.payments.schemas import PaymentOut
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
    admin_id: str = Depends(get_current_user_id),
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
    admin_id: str = Depends(get_current_user_id),
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
    admin_id: str = Depends(get_current_user_id),
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
    admin_id: str = Depends(get_current_user_id),
) -> BalanceOut:
    raise not_implemented("E8")


@router.get(
    "/costs",
    response_model=list[CostConfigOut],
    operation_id="adminListCosts",
    summary="Lista tabela mestre de custo (ADR 0003)",
)
async def admin_list_costs(
    db: Session = Depends(get_db),
    admin_id: str = Depends(get_current_user_id),
) -> list[CostConfigOut]:
    raise not_implemented("E4")
