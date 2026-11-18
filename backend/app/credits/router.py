"""Rotas de créditos — saldo/ledger implementados na E3."""

from fastapi import APIRouter, Depends, Query

from app.core.errors import not_implemented
from app.core.security import get_current_user_id
from app.credits.schemas import BalanceOut, LedgerEntryOut

router = APIRouter(prefix="/credits", tags=["credits"])


@router.get(
    "/balance",
    response_model=BalanceOut,
    operation_id="getCreditBalance",
    summary="Retorna saldo, reservado e disponível",
)
async def get_balance(user_id: str = Depends(get_current_user_id)) -> BalanceOut:
    raise not_implemented("E3")


@router.get(
    "/ledger",
    response_model=list[LedgerEntryOut],
    operation_id="listCreditLedger",
    summary="Lista o histórico append-only de créditos",
)
async def list_ledger(
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    user_id: str = Depends(get_current_user_id),
) -> list[LedgerEntryOut]:
    raise not_implemented("E3")
