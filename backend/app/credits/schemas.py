"""Schemas de créditos (tabelas credit_accounts/credit_ledger na E3)."""

import uuid
from datetime import datetime


from pydantic import BaseModel, ConfigDict


class BalanceOut(BaseModel):
    user_id: uuid.UUID
    balance: int
    reserved: int = 0
    available: int


class LedgerEntryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    amount: int
    reason: str
    balance_after: int
    created_at: datetime
