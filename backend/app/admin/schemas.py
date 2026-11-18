"""Schemas administrativos."""

import uuid

from pydantic import BaseModel, Field


class CreditAdjustmentIn(BaseModel):
    user_id: uuid.UUID
    amount: int = Field(description="Positivo credita; negativo debita.")
    reason: str = Field(min_length=3, max_length=200)


class CostConfigOut(BaseModel):
    operation: str
    credits: int
    enabled: bool
