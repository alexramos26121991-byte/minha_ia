"""Testes da F0 — honestidade operacional e fail-closed.

Cobre: health real (DB + Redis), guard de configuração de produção, limites do
worker e observabilidade opcional. Nenhuma rede, Postgres ou Redis é exigido:
as dependências são substituídas por fakes determinísticos.
"""

from __future__ import annotations

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.exc import SQLAlchemyError

from app.core import config as config_module
from app.core import health as health_module
from app.core import observability as observability_module
from app.core.config import settings


class _FakeConnection:
    def __init__(self, fail: bool) -> None:
        self.fail = fail

    def __enter__(self):
        return self

    def __exit__(self, *args) -> bool:
        return False

    def execute(self, _statement):
        if self.fail:
            raise SQLAlchemyError("banco fora do ar")
        return None


class _FakeEngine:
    def __init__(self, fail: bool) -> None:
        self.fail = fail

    def connect(self):
        return _FakeConnection(self.fail)


class _FakeRedis:
    def __init__(self, fail: bool) -> None:
        self.fail = fail

    def ping(self) -> bool:
        if self.fail:
            raise health_module.redis.RedisError("fila fora do ar")
        return True

    def close(self) -> None:
        return None


# ---------------------------------------------------------------------------
# Health real
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("db_fail", "queue_fail", "expected"),
    [
        (False, False, "ok"),
        (True, False, "degraded"),
        (False, True, "degraded"),
        (True, True, "degraded"),
    ],
)
def test_check_dependencies_reflete_dependencias(
    monkeypatch: pytest.MonkeyPatch,
    db_fail: bool,
    queue_fail: bool,
    expected: str,
) -> None:
    monkeypatch.setattr(health_module, "engine", _FakeEngine(db_fail))
    monkeypatch.setattr(
        health_module.redis,
        "from_url",
        lambda *args, **kwargs: _FakeRedis(queue_fail),
    )

    checks = health_module.check_dependencies()

    assert checks["database"] == ("unavailable" if db_fail else "ok")
    assert checks["queue"] == ("unavailable" if queue_fail else "ok")
    assert health_module.overall_status(checks) == expected


def test_health_endpoint_publica_status_degradado(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    import app.main as main_module

    monkeypatch.setattr(
        main_module,
        "check_dependencies",
        lambda: {"database": "ok", "queue": "unavailable"},
    )
    with TestClient(main_module.app) as client:
        response = client.get("/health")

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "degraded"
    assert set(body) == {"status", "app", "version", "environment"}


def test_health_endpoint_publica_status_ok(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    import app.main as main_module

    monkeypatch.setattr(
        main_module,
        "check_dependencies",
        lambda: {"database": "ok", "queue": "ok"},
    )
    with TestClient(main_module.app) as client:
        response = client.get("/health")

    assert response.status_code == 200
    assert response.json()["status"] == "ok"


# ---------------------------------------------------------------------------
# Guard de produção
# ---------------------------------------------------------------------------


def _production_settings(**overrides):
    values = {
        "app_env": "production",
        "auth_provider": "firebase",
        "postgres_password": "senha-forte-nao-padrao-2026",
        "firebase_project_id": "projeto-teste",
        "firebase_service_account_json": '{"type": "service_account"}',
        "openai_api_key": "sk-teste",
        "fal_api_key": "key-teste",
        "fal_webhook_user_id": "user-teste",
        "allow_mock_providers": False,
    }
    values.update(overrides)
    return config_module.Settings(_env_file=None, **values)


def test_producao_com_configuracao_completa_inicializa() -> None:
    assert _production_settings().app_env == "production"


def test_producao_nao_exige_jwt_secret() -> None:
    # security.py valida ID tokens do Firebase: não existe HMAC próprio.
    # Manter JWT_SECRET no guard seria config morta e falsa sensação de segurança.
    assert not hasattr(_production_settings(), "jwt_secret")


def test_desenvolvimento_aceita_defaults() -> None:
    assert config_module.Settings(_env_file=None).app_env == "development"


@pytest.mark.parametrize(
    ("campo", "valor", "fragmento"),
    [
        ("auth_provider", "dev", "AUTH_PROVIDER"),
        ("postgres_password", "trocar", "POSTGRES_PASSWORD"),
        ("firebase_project_id", "", "FIREBASE_PROJECT_ID"),
        ("firebase_service_account_json", "", "FIREBASE_SERVICE_ACCOUNT_JSON"),
        ("openai_api_key", "", "OPENAI_API_KEY"),
        ("fal_api_key", "", "FAL_API_KEY"),
        ("fal_webhook_user_id", "", "FAL_WEBHOOK_USER_ID"),
        ("allow_mock_providers", True, "ALLOW_MOCK_PROVIDERS"),
    ],
)
def test_producao_recusa_configuracao_incompleta(
    campo: str, valor: object, fragmento: str
) -> None:
    with pytest.raises(ValueError, match=fragmento):
        _production_settings(**{campo: valor})


# ---------------------------------------------------------------------------
# Worker e observabilidade
# ---------------------------------------------------------------------------


def test_celery_tem_timeouts_e_retry_configurados() -> None:
    from app.core.celery_app import celery_app

    assert celery_app.conf.task_soft_time_limit == settings.worker_soft_timeout_seconds
    assert celery_app.conf.task_time_limit == settings.worker_hard_timeout_seconds
    assert celery_app.conf.broker_connection_retry_on_startup is True
    assert celery_app.conf.result_expires == 24 * 3600


def test_tasks_de_geracao_tem_retry_automatico() -> None:
    from app.generation.tasks import (
        process_fal_webhook_task,
        process_video_generation_task,
    )

    assert process_video_generation_task.max_retries == 2
    assert process_fal_webhook_task.max_retries == 3


def test_observability_sem_dsn_nao_inicializa(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setattr(observability_module.settings, "sentry_dsn", "")
    assert observability_module.setup_observability() is False
