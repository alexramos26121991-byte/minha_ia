"""Schemas de pagamento (ADR 0004 — provisório)."""

import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, HttpUrl


class CheckoutIn(BaseModel):
    plan_slug: str = Field(min_length=1, max_length=64)
    provider: str = Field(pattern=r"^(stripe|mercadopago)$")
    success_url: HttpUrl | None = None


class CheckoutOut(BaseModel):
    checkout_id: str
    provider: str
    checkout_url: HttpUrl
    expires_at: datetime | None = None


class PaymentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    provider: str
    external_id: str
    amount_brl: float
    status: str
    created_at: datetime
