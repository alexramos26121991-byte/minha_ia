"""Rotas de perfil do usuário (E2)."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import VerifiedIdentity, get_current_identity
from app.users.schemas import UserOut, UserUpdateIn
from app.users.service import find_by_uid, to_out

router = APIRouter(prefix="/users", tags=["users"])


def _require_user(
    identity: VerifiedIdentity = Depends(get_current_identity),
    db: Session = Depends(get_db),
):
    user = find_by_uid(db, identity.uid)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Perfil não encontrado. Abra uma sessão antes de consultar o perfil.",
        )
    return user


@router.get(
    "/me",
    response_model=UserOut,
    operation_id="getCurrentUser",
    summary="Retorna o perfil do usuário autenticado",
)
async def get_current_user(user=Depends(_require_user), db: Session = Depends(get_db)) -> UserOut:
    return to_out(db, user)


@router.patch(
    "/me",
    response_model=UserOut,
    operation_id="updateCurrentUser",
    summary="Atualiza token FCM, versão do consentimento e nome de exibição",
)
async def update_current_user(
    payload: UserUpdateIn,
    user=Depends(_require_user),
    db: Session = Depends(get_db),
) -> UserOut:
    if payload.fcm_token is not None:
        user.fcm_token = payload.fcm_token
    if payload.consent_version is not None:
        user.consent_version = payload.consent_version
    if payload.display_name is not None:
        user.display_name = payload.display_name
    db.commit()
    db.refresh(user)
    return to_out(db, user)
