"""Schemas de plano."""

import uuid

from pydantic import BaseModel, ConfigDict


class PlanOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    slug: str
    name: str
    monthly_credits: int
    price_brl: float
    recurrence: str
    is_active: bool
