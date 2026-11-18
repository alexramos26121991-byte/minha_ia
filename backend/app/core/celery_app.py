"""Aplicação Celery — fila de gerações assíncronas (preenchida na E4/E5)."""

from celery import Celery

from app.core.config import settings

celery_app = Celery(
    "minha_ia",
    broker=settings.redis_url,
    backend=settings.redis_url,
    imports=("app.credits.tasks", "app.generation.tasks"),
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
    beat_schedule={
        "reconcile-orphan-reservations": {
            "task": "credits.reconcile_orphan_reservations",
            "schedule": float(settings.reconcile_interval_seconds),
            "options": {"expires": max(30, settings.reconcile_interval_seconds - 20)},
        },
    },
)

# Tasks de geração: app.generation.tasks (vídeo/animação — E5).
