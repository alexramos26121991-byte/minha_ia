"""Tasks assíncronos de geração (E5).

O worker importa este módulo via ``celery_app.conf.imports``. As funções de
dispatch são injetadas nas rotas: em produção publicam na fila; nos testes são
substituídas por uma chamada síncrona, sem Redis.

Os imports de serviços/provedores são locais de propósito: ``deps`` importa as
funções de dispatch daqui, e o serviço importa ``deps``. Importar no topo
criaria ciclo.
"""

from __future__ import annotations

import logging

from app.core.celery_app import celery_app

logger = logging.getLogger(__name__)


def _worker_dependencies():
    from app.generation.deps import get_media_storage, get_video_provider

    return get_video_provider(), get_media_storage()


@celery_app.task(name="generations.process_video", bind=True, max_retries=2)
def process_video_generation_task(self, generation_id: str) -> str:
    """Executa o job de vídeo com polling e confirma/estorna créditos."""
    from app.core.database import SessionLocal
    from app.generation.video_service import VideoGenerationService

    provider, storage = _worker_dependencies()
    with SessionLocal() as db:
        result = VideoGenerationService.process(
            db, generation_id=generation_id, provider=provider, storage=storage
        )
    logger.info("Job de vídeo %s finalizado: %s", generation_id, result.status)
    return result.status


@celery_app.task(name="generations.process_fal_webhook")
def process_fal_webhook_task(request_id: str, payload: dict) -> bool:
    """Finaliza um job já concluído, a partir de um webhook verificado."""
    from app.core.database import SessionLocal
    from app.generation.video_service import VideoGenerationService

    provider, storage = _worker_dependencies()
    with SessionLocal() as db:
        return VideoGenerationService.finalize_from_webhook(
            db, request_id=request_id, payload=payload, provider=provider, storage=storage
        )


def dispatch_video_job(generation_id: str) -> None:
    """Publica o job na fila (usado pela rota de enfileiramento)."""
    process_video_generation_task.delay(generation_id)


def dispatch_fal_webhook(request_id: str, payload: dict) -> None:
    """Publica a finalização do webhook na fila."""
    process_fal_webhook_task.delay(request_id, payload)
