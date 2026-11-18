"""Dependencies que combinam identidade, banco e autorização.

Centralizar esta resolução evita que cada router compare o UID do token com
``users.id`` (são identificadores diferentes: UID do Firebase vs. UUID interno).
"""

from __future__ import annotations

from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import VerifiedIdentity, get_current_identity
from app.users.model import User
from app.users.service import find_by_uid


def get_current_user(
    identity: VerifiedIdentity = Depends(get_current_identity),
    db: Session = Depends(get_db),
) -> User:
    """Resolve o portador do token para o registro interno de usuário."""
    user = find_by_uid(db, identity.uid)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Perfil não encontrado. Abra uma sessão antes de consultar o perfil.",
        )
    return user


def get_admin_user(user: User = Depends(get_current_user)) -> User:
    """Gate mínimo para rotas administrativas (RBAC completo na E8)."""
    if user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acesso restrito a administradores.",
        )
    return user
