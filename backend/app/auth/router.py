"""Rotas de autenticação — sessão via ID token verificado (E2)."""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.schemas import SessionIn, SessionOut
from app.core.database import get_db
from app.core.security import VerifiedIdentity, get_current_identity
from app.users.service import plan_slug_for, upsert_user

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post(
    "/session",
    response_model=SessionOut,
    operation_id="createSession",
    summary="Abre uma sessão a partir do ID token do Firebase",
    description=(
        "Verifica o ID token, cria o usuário no primeiro login e registra o "
        "fcm_token do dispositivo. Use Authorization: Bearer <id-token>."
    ),
)
async def create_session(
    payload: SessionIn,
    identity: VerifiedIdentity = Depends(get_current_identity),
    db: Session = Depends(get_db),
) -> SessionOut:
    user, is_new = upsert_user(db, identity)

    altered = False
    if payload.fcm_token is not None and user.fcm_token != payload.fcm_token:
        user.fcm_token = payload.fcm_token
        altered = True
    if (
        payload.consent_version is not None
        and user.consent_version != payload.consent_version
    ):
        user.consent_version = payload.consent_version
        altered = True
    if (
        payload.display_name
        and payload.display_name != user.display_name
    ):
        user.display_name = payload.display_name
        altered = True
    if altered:
        db.commit()
        db.refresh(user)

    return SessionOut(
        user_id=str(user.id),
        is_new=is_new,
        plan_slug=plan_slug_for(db, user.plan_id),
    )
