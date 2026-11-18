"""Schemas compartilhados."""

from pydantic import BaseModel


class HealthOut(BaseModel):
    status: str
    app: str
    version: str
    environment: str
