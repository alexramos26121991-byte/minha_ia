"""Rotas de autenticação — contrato na E1c, Firebase na E2."""

from fastapi import APIRouter, Depends

from app.auth.schemas import SessionOut
from app.core.errors import not_implemented
from app.core.security import get_current_user_id

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post(
    "/session",
    response_model=SessionOut,
    operation_id="createSession",
    summary="Abre uma sessão a partir do ID token do Firebase",
    description="Contrato definido na E1c; validação Firebase/upsert de usuário na E2.",
)
async def create_session(user_id: str = Depends(get_current_user_id)) -> SessionOut:
    raise not_implemented("E2")
