"""Schemas de usuário expostos no contrato."""

import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    firebase_uid: str
    email: str
    plan_slug: str | None = None
    status: str
    consent_version: str | None = None
    created_at: datetime


class UserUpdateIn(BaseModel):
    fcm_token: str | None = Field(default=None, max_length=512)
    consent_version: str | None = Field(default=None, max_length=32)
