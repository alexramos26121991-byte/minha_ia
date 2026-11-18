"""Aplicação Celery — fila de gerações assíncronas (preenchida na E4/E5)."""

from celery import Celery

from app.core.config import settings

celery_app = Celery(
    "minha_ia",
    broker=settings.redis_url,
    backend=settings.redis_url,
)

celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
    task_track_started=True,
    task_acks_late=True,
    worker_prefetch_multiplier=1,
)

# Os tasks de geração são registrados em backend/app/generation/tasks.py (E4+).
