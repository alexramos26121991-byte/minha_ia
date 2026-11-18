"""Regras de usuário da E2: upsert no primeiro login e leitura do perfil."""

from __future__ import annotations

import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.security import VerifiedIdentity
from app.plans.model import Plan
from app.users.model import User
from app.users.schemas import UserOut

DEFAULT_PLAN_SLUG = "gratuito"


def find_by_uid(db: Session, firebase_uid: str) -> User | None:
    return db.execute(
        select(User).where(User.firebase_uid == firebase_uid)
    ).scalar_one_or_none()


def plan_slug_for(db: Session, plan_id: uuid.UUID | None) -> str | None:
    if plan_id is None:
        return None
    plan = db.execute(select(Plan).where(Plan.id == plan_id)).scalar_one_or_none()
    return plan.slug if plan else None


def upsert_user(db: Session, identity: VerifiedIdentity) -> tuple[User, bool]:
    """Cria o usuário no primeiro login ou atualiza dados do provedor.

    Retorna ``(user, is_new)`` para que a sessão informe ``is_new`` ao app.
    """
    user = find_by_uid(db, identity.uid)
    is_new = user is None

    if is_new:
        free_plan = db.execute(
            select(Plan).where(Plan.slug == DEFAULT_PLAN_SLUG)
        ).scalar_one_or_none()
        user = User(
            id=uuid.uuid4(),
            firebase_uid=identity.uid,
            email=identity.email or f"{identity.uid}@users.local",
            display_name=identity.display_name,
            plan_id=free_plan.id if free_plan else None,
        )
        db.add(user)
    else:
        if identity.email and user.email != identity.email:
            user.email = identity.email
        if identity.display_name and not user.display_name:
            user.display_name = identity.display_name

    db.commit()
    db.refresh(user)
    return user, is_new


def to_out(db: Session, user: User) -> UserOut:
    return UserOut(
        id=user.id,
        firebase_uid=user.firebase_uid,
        email=user.email,
        display_name=user.display_name,
        plan_slug=plan_slug_for(db, user.plan_id),
        status=user.status,
        consent_version=user.consent_version,
        created_at=user.created_at,
    )
