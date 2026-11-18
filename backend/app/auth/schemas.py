"""Schemas de sessão."""

from pydantic import BaseModel, Field


class SessionIn(BaseModel):
    """Dados do dispositivo enviados no abertura de sessão.

    ``fcm_token`` é registrado já no login para que as notificações da E5
    possam ser enviadas sem uma segunda chamada do app.
    """

    fcm_token: str | None = Field(default=None, max_length=512)
    consent_version: str | None = Field(default=None, max_length=32)
    display_name: str | None = Field(default=None, max_length=120)


class SessionOut(BaseModel):
    user_id: str
    is_new: bool
    plan_slug: str | None = None
