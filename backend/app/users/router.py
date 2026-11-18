"""Rotas de perfil do usuário (implementação na E2)."""

from fastapi import APIRouter, Depends

from app.core.errors import not_implemented
from app.core.security import get_current_user_id
from app.users.schemas import UserOut, UserUpdateIn

router = APIRouter(prefix="/users", tags=["users"])


@router.get(
    "/me",
    response_model=UserOut,
    operation_id="getCurrentUser",
    summary="Retorna o perfil do usuário autenticado",
)
async def get_current_user(user_id: str = Depends(get_current_user_id)) -> UserOut:
    raise not_implemented("E2")


@router.patch(
    "/me",
    response_model=UserOut,
    operation_id="updateCurrentUser",
    summary="Atualiza token FCM e versão do consentimento",
)
async def update_current_user(
    payload: UserUpdateIn,
    user_id: str = Depends(get_current_user_id),
) -> UserOut:
    raise not_implemented("E2")
