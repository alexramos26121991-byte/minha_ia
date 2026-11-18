"""Registro idempotente de eventos de webhook (tabela da migration 0003).

O modelo ``WebhookEvent`` vive em ``app.payments.model`` — a tabela é
compartilhada com os webhooks de pagamento e possui a constraint única
``(provider, external_id)``. Aqui só adicionamos a operação de registro.
"""

from __future__ import annotations

from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.payments.model import WebhookEvent

__all__ = ["WebhookEvent", "register_event"]


def register_event(
    db: Session,
    *,
    provider: str,
    external_id: str,
    event_type: str,
    payload: dict,
) -> bool:
    """Grava o evento uma única vez.

    Retorna ``True`` quando é novo e ``False`` quando é reentrega. O chamador
    só deve debitar/confirmar créditos quando receber ``True``.
    """
    if not external_id:
        raise ValueError("external_id é obrigatório.")
    try:
        db.add(
            WebhookEvent(
                provider=provider,
                external_id=external_id[:160],
                event_type=event_type[:80],
                payload=payload,
            )
        )
        db.commit()
        return True
    except IntegrityError:
        db.rollback()
        return False
