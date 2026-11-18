"""Catálogo de planos — lido do banco semeado na E1c."""

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.plans.model import Plan
from app.plans.schemas import PlanOut

router = APIRouter(prefix="/plans", tags=["plans"])


@router.get(
    "",
    response_model=list[PlanOut],
    operation_id="listPlans",
    summary="Lista os planos ativos (tela de planos do app)",
    description="Os preços são provisórios conforme ADR 0004.",
)
def list_plans(db: Session = Depends(get_db)) -> list[PlanOut]:
    plans = db.scalars(
        select(Plan).where(Plan.is_active.is_(True)).order_by(Plan.sort_order)
    ).all()
    return [PlanOut.model_validate(plan) for plan in plans]
