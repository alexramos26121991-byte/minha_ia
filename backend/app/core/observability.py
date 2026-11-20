"""Observabilidade opcional — Sentry só é iniciado se houver DSN (F0).

O import é lazy: ambientes sem `sentry-sdk` instalado continuam funcionando,
mas a configuração deixa de ser um campo morto no `.env.example`.
"""

from __future__ import annotations

import logging

from app import __version__
from app.core.config import settings

logger = logging.getLogger(__name__)


def setup_observability() -> bool:
    """Ativa o reportador de erros e devolve ``True`` se algo foi iniciado."""
    dsn = settings.sentry_dsn.strip()
    if not dsn:
        return False
    try:
        import sentry_sdk
    except ImportError:
        logger.warning("SENTRY_DSN definida, mas sentry-sdk não está instalado.")
        return False
    sentry_sdk.init(
        dsn=dsn,
        environment=settings.app_env,
        release=__version__,
        traces_sample_rate=settings.sentry_traces_sample_rate,
        send_default_pii=False,
    )
    logger.info("Observabilidade iniciada (Sentry, environment=%s)", settings.app_env)
    return True
