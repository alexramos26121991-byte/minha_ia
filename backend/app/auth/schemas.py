"""Schemas de sessão."""

from pydantic import BaseModel


class SessionOut(BaseModel):
    user_id: str
    is_new: bool
    plan_slug: str | None = None
