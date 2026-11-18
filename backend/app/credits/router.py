"""Rotas de créditos — implementadas na E3."""

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.admin.schemas import CostConfigOut
from app.core.database import get_db
from app.core.deps import get_current_user
from app.credits.schemas import BalanceOut, LedgerEntryOut
from app.credits.service import CreditService
from app.users.model import User

router = APIRouter(prefix="/credits", tags=["credits"])


@router.get(
    "/balance",
    response_model=BalanceOut,
    operation_id="getCreditBalance",
    summary="Retorna saldo, reservado e disponível",
)
async def get_balance(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> BalanceOut:
    return CreditService.get_balance(db, user.id)


@router.get(
    "/ledger",
    response_model=list[LedgerEntryOut],
    operation_id="listCreditLedger",
    summary="Lista o histórico append-only de créditos",
)
async def list_ledger(
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[LedgerEntryOut]:
    return CreditService.list_ledger(db, user.id, limit, offset)


@router.get(
    "/costs",
    response_model=list[CostConfigOut],
    operation_id="listCreditCosts",
    summary="Custos de geração por operação (somente leitura)",
)
async def list_costs(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[CostConfigOut]:
    """Expõe a tabela mestre de custos ao app, sem permitir alteração.

    O cliente precisa do valor antes de confirmar a geração; buscá-lo do
    backend evita que o preço exibido diverge do valor debitado.
    """
    return [
        CostConfigOut(operation=row.operation, credits=row.credits, enabled=row.enabled)
        for row in CreditService.list_costs(db)
    ]
