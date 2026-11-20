"""Verificação real de saúde das dependências (F0).

``/health`` continua com o mesmo contrato (``HealthOut``), mas o status deixa
de ser estático: ``ok`` somente quando Postgres e Redis respondem; caso
contrário, ``degraded``. O detalhe de qual dependência falhou vai para o log —
a resposta pública não expõe endereços internos.
"""

from __future__ import annotations

import logging
from collections.abc import Mapping

import redis
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

from app.core.config import settings
from app.core.database import engine

logger = logging.getLogger(__name__)

_DEPENDENCIES = ("database", "queue")


def check_dependencies() -> dict[str, str]:
    """Consulta ativamente Postgres e Redis com timeouts curtos."""
    results: dict[str, str] = {}

    try:
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))
        results["database"] = "ok"
    except SQLAlchemyError as exc:
        logger.warning("Health: banco indisponível (%s)", type(exc).__name__)
        results["database"] = "unavailable"

    client = redis.from_url(
        settings.redis_url,
        socket_connect_timeout=2,
        socket_timeout=2,
    )
    try:
        client.ping()
        results["queue"] = "ok"
    except redis.RedisError as exc:
        logger.warning("Health: fila indisponível (%s)", type(exc).__name__)
        results["queue"] = "unavailable"
    finally:
        client.close()

    return results


def overall_status(checks: Mapping[str, str]) -> str:
    """Devolve ``ok`` apenas se todas as dependências monitoradas responderam."""
    if all(checks.get(name) == "ok" for name in _DEPENDENCIES):
        return "ok"
    return "degraded"
