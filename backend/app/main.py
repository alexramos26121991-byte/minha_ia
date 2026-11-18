"""Ponto de entrada da API MINHA IA.

O OpenAPI gerado aqui é a fonte do contrato versionado em `backend/openapi.yaml`
e do cliente Dart em `mobile/lib/services/api/generated/`.
"""

from fastapi import FastAPI
from fastapi.openapi.utils import get_openapi

from app import __version__
from app.admin.router import router as admin_router
from app.auth.router import router as auth_router
from app.core.config import settings
from app.core.schemas import HealthOut
from app.credits.router import router as credits_router
from app.generation.router import router as generation_router
from app.payments.router import router as payments_router
from app.plans.router import router as plans_router
from app.users.router import router as users_router

TAGS = [
    {"name": "system", "description": "Saúde do serviço."},
    {"name": "auth", "description": "Sessão via Firebase (E2)."},
    {"name": "users", "description": "Perfil do usuário (E2)."},
    {"name": "plans", "description": "Catálogo de planos semeados na E1c."},
    {"name": "credits", "description": "Saldo e ledger append-only (E3)."},
    {"name": "generations", "description": "Imagem (E4), vídeo/animação (E5), áudio/avatar (E6)."},
    {"name": "payments", "description": "Checkout e webhooks (E7)."},
    {"name": "admin", "description": "Operação e auditoria (E8)."},
]

app = FastAPI(
    title="MINHA IA API",
    version=__version__,
    description=(
        "API da plataforma MINHA IA — SUA IMAGINAÇÃO, SEM LIMITES. "
        "Créditos são reservados/efetivados/estornados no backend; o app nunca "
        "recebe chaves de provedores nem regras de crédito. "
        "Endpoints marcados como 501 já estão contratados e são implementados "
        "nas etapas seguintes do plano de execução."
    ),
    openapi_tags=TAGS,
)


@app.get(
    "/health",
    response_model=HealthOut,
    operation_id="health",
    tags=["system"],
    summary="Verificação de saúde (liveness/readiness)",
)
def health() -> HealthOut:
    return HealthOut(
        status="ok",
        app="minha-ia",
        version=__version__,
        environment=settings.app_env,
    )


app.include_router(auth_router)
app.include_router(users_router)
app.include_router(plans_router)
app.include_router(credits_router)
app.include_router(generation_router)
app.include_router(payments_router)
app.include_router(admin_router)


# Operações públicas: não exigem token do app (health, catálogo e webhook).
PUBLIC_OPERATION_IDS = {"health", "listPlans", "handlePaymentWebhook"}
_HTTP_METHODS = {"get", "post", "put", "patch", "delete"}


def _custom_openapi() -> dict:
    """Completa o schema com metadados e respostas de erro consistentes."""
    if app.openapi_schema:
        return app.openapi_schema
    schema = get_openapi(
        title=app.title,
        version=app.version,
        description=app.description,
        routes=app.routes,
        tags=app.openapi_tags,
    )
    schema["info"]["license"] = {
        "name": "Uso interno — MINHA IA",
        "identifier": "LicenseRef-Proprietary",
    }
    # URL relativa: o cliente Dart define a base em runtime (dev/homolog/prod).
    schema["servers"] = [{"url": "/", "description": "Base configurada pelo cliente"}]

    for path_item in schema.get("paths", {}).values():
        for method, operation in path_item.items():
            if method not in _HTTP_METHODS:
                continue
            if operation.get("operationId") in PUBLIC_OPERATION_IDS:
                # Describe explicitamente a ausência de autenticação.
                operation["security"] = []
            responses = operation.setdefault("responses", {})
            if not any(code.startswith("4") for code in responses):
                responses["400"] = {"description": "Requisição inválida."}

    app.openapi_schema = schema
    return schema


app.openapi = _custom_openapi
