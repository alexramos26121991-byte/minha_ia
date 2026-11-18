"""Cria users e plans e semeia os 4 planos do PRD.

Revision ID: 0001_initial
Revises:
Create Date: 2026-11-17
"""

import uuid

import sqlalchemy as sa
from alembic import op

revision = "0001_initial"
down_revision = None
branch_labels = None
depends_on = None

# UUIDs fixos tornam o seed determinístico e idempotente entre ambientes.
PLAN_SEED = [
    {
        "id": uuid.UUID("11111111-1111-4111-8111-111111111111"),
        "slug": "gratuito",
        "name": "Gratuito",
        "monthly_credits": 30,
        "price_brl": "0.00",
        "recurrence": "monthly",
        "is_active": True,
        "sort_order": 0,
    },
    {
        "id": uuid.UUID("22222222-2222-4222-8222-222222222222"),
        "slug": "basico",
        "name": "Básico",
        "monthly_credits": 300,
        "price_brl": "29.90",
        "recurrence": "monthly",
        "is_active": True,
        "sort_order": 1,
    },
    {
        "id": uuid.UUID("33333333-3333-4333-8333-333333333333"),
        "slug": "pro",
        "name": "Pro",
        "monthly_credits": 1000,
        "price_brl": "89.90",
        "recurrence": "monthly",
        "is_active": True,
        "sort_order": 2,
    },
    {
        "id": uuid.UUID("44444444-4444-4444-8444-444444444444"),
        "slug": "premium",
        "name": "Premium",
        "monthly_credits": 3000,
        "price_brl": "249.90",
        "recurrence": "monthly",
        "is_active": True,
        "sort_order": 3,
    },
]


def upgrade() -> None:
    op.create_table(
        "plans",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column("slug", sa.String(length=64), nullable=False),
        sa.Column("name", sa.String(length=80), nullable=False),
        sa.Column("monthly_credits", sa.Integer(), nullable=False),
        sa.Column("price_brl", sa.Numeric(10, 2), nullable=False),
        sa.Column("recurrence", sa.String(length=16), nullable=False, server_default="monthly"),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default="0"),
    )
    op.create_index("ix_plans_slug", "plans", ["slug"], unique=True)

    op.create_table(
        "users",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column("firebase_uid", sa.String(length=128), nullable=False),
        sa.Column("email", sa.String(length=320), nullable=False),
        sa.Column("plan_id", sa.Uuid(as_uuid=True), nullable=True),
        sa.Column("fcm_token", sa.String(length=512), nullable=True),
        sa.Column("status", sa.String(length=32), nullable=False, server_default="active"),
        sa.Column("consent_version", sa.String(length=32), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.ForeignKeyConstraint(["plan_id"], ["plans.id"], ondelete="SET NULL"),
    )
    op.create_index("ix_users_firebase_uid", "users", ["firebase_uid"], unique=True)
    op.create_index("ix_users_email", "users", ["email"], unique=True)

    plans_table = sa.table(
        "plans",
        sa.column("id", sa.Uuid()),
        sa.column("slug", sa.String()),
        sa.column("name", sa.String()),
        sa.column("monthly_credits", sa.Integer()),
        sa.column("price_brl", sa.Numeric(10, 2)),
        sa.column("recurrence", sa.String()),
        sa.column("is_active", sa.Boolean()),
        sa.column("sort_order", sa.Integer()),
    )
    op.bulk_insert(plans_table, PLAN_SEED)


def downgrade() -> None:
    op.drop_index("ix_users_email", table_name="users")
    op.drop_index("ix_users_firebase_uid", table_name="users")
    op.drop_table("users")
    op.drop_index("ix_plans_slug", table_name="plans")
    op.drop_table("plans")
