"""Tasks assíncronos de créditos (E3).

O worker importa este módulo via ``celery_app.conf.imports``. O agendamento
fica no beat (``reconcile_interval_seconds``); a task também pode ser disparada
manualmente em testes e operação.
"""

from __future__ import annotations

from app.core.celery_app import celery_app
from app.core.database import SessionLocal
from app.credits.service import CreditService


@celery_app.task(name="credits.reconcile_orphan_reservations")
def reconcile_orphan_reservations_task(stale_minutes: int | None = None) -> int:
    """Estorna reservas órfãs e devolve a quantidade recuperada."""
    with SessionLocal() as db:
        return CreditService.reconcile_orphan_reservations(db, stale_minutes)
