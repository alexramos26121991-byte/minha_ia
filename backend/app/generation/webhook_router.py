"""Webhook do fal.ai (D2/E5) — público, autenticado por assinatura.

Não entra no OpenAPI de propósito: é um contrato do provedor, não do app.
A ordem importa: corpo cru → assinatura → registro idempotente → fila.
Nenhum crédito é mexido nesta rota; a finalização acontece no worker.
"""

from __future__ import annotations

import json
import logging

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.generation.deps import get_fal_webhook_dispatcher, get_fal_webhook_verifier
from app.generation.video_service import WebhookDispatcher
from app.generation.webhook import HEADER_REQUEST_ID, FalWebhookVerifier
from app.generation.webhook_events import register_event

logger = logging.getLogger(__name__)

router = APIRouter(tags=["generations"])


@router.post(
    "/webhooks/falai",
    status_code=status.HTTP_200_OK,
    include_in_schema=False,
    summary="Recebe o evento assinado do fal.ai e enfileira a finalização",
)
async def handle_falai_webhook(
    request: Request,
    db: Session = Depends(get_db),
    verifier: FalWebhookVerifier = Depends(get_fal_webhook_verifier),
    dispatcher: WebhookDispatcher = Depends(get_fal_webhook_dispatcher),
) -> dict[str, object]:
    body = await request.body()
    headers = dict(request.headers)

    if not verifier.verify(headers, body):
        logger.warning("Webhook do fal.ai rejeitado: assinatura inválida")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Assinatura de webhook inválida.",
        )

    try:
        payload = json.loads(body)
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Corpo do webhook inválido.",
        ) from exc
    if not isinstance(payload, dict):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Corpo do webhook inválido.",
        )

    delivery_id = headers.get(HEADER_REQUEST_ID, "").strip()
    if not delivery_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Identificação da entrega ausente.",
        )

    is_new = register_event(
        db,
        provider="falai",
        external_id=delivery_id,
        event_type=str(payload.get("type") or "video.generation")[:80],
        payload=payload,
    )
    if not is_new:
        logger.info("Webhook do fal.ai já registrado: %s", delivery_id)
        return {"received": True, "duplicate": True}

    job_id = str(payload.get("request_id") or "").strip()
    if job_id:
        try:
            dispatcher(job_id, payload)
        except Exception:
            # O evento já está registrado; não reentregamos para não duplicar.
            # O polling do worker é o fallback quando a fila falha.
            logger.exception("Falha ao enfileirar o webhook do job %s", job_id)

    return {"received": True, "duplicate": False}
