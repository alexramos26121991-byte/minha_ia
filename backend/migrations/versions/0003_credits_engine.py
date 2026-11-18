"""Cria o motor de créditos e tabelas de apoio da E3.

Revision ID: 0003_credits_engine
Revises: 0002_user_display_name
Create Date: 2026-11-17

Inclui ``users.role`` para o gate administrativo mínimo e as tabelas
``credit_accounts``, ``credit_ledger`` (append-only), ``generations``,
``payments``, ``webhook_events``, ``cost_config`` e ``admin_audit_log``.
"""

import sqlalchemy as sa
from alembic import op

revision = "0003_credits_engine"
down_revision = "0002_user_display_name"
branch_labels = None
depends_on = None

# Provisório (ADR 0003): 1 crédito ≈ R$ 0,05. Revisar quando os provedores
# forem confirmados. O cliente nunca envia estes valores.
COST_SEED = [
    {"operation": "image", "credits": 10, "enabled": True},
    {"operation": "video", "credits": 50, "enabled": True},
    {"operation": "animate_photo", "credits": 20, "enabled": True},
]


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column("role", sa.String(length=16), nullable=False, server_default="user"),
    )

    op.create_table(
        "credit_accounts",
        sa.Column("user_id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column("balance", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("reserved", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
    )

    op.create_table(
        "credit_ledger",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column("user_id", sa.Uuid(as_uuid=True), nullable=False),
        sa.Column("amount", sa.Integer(), nullable=False),
        sa.Column("reason", sa.String(length=200), nullable=False),
        sa.Column("kind", sa.String(length=32), nullable=False),
        sa.Column("balance_after", sa.Integer(), nullable=False),
        sa.Column("idempotency_key", sa.String(length=160), nullable=False),
        sa.Column("reservation_key", sa.String(length=160), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.UniqueConstraint("idempotency_key", name="uq_credit_ledger_idempotency"),
    )
    op.create_index("ix_credit_ledger_user_id", "credit_ledger", ["user_id"])
    op.create_index("ix_credit_ledger_idempotency_key", "credit_ledger", ["idempotency_key"], unique=True)
    op.create_index("ix_credit_ledger_user_created", "credit_ledger", ["user_id", "created_at"])
    op.create_index("ix_credit_ledger_reservation", "credit_ledger", ["reservation_key", "kind"])

    op.create_table(
        "generations",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column("user_id", sa.Uuid(as_uuid=True), nullable=False),
        sa.Column("type", sa.String(length=32), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False, server_default="pending"),
        sa.Column("provider", sa.String(length=64), nullable=True),
        sa.Column("cost_credits", sa.Integer(), nullable=False),
        sa.Column("storage_path", sa.String(length=512), nullable=True),
        sa.Column("idempotency_key", sa.String(length=160), nullable=False),
        sa.Column("prompt", sa.Text(), nullable=True),
        sa.Column("error_message", sa.String(length=500), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.UniqueConstraint("idempotency_key", name="uq_generations_idempotency"),
    )
    op.create_index("ix_generations_user_id", "generations", ["user_id"])
    op.create_index("ix_generations_idempotency_key", "generations", ["idempotency_key"], unique=True)

    op.create_table(
        "payments",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column("user_id", sa.Uuid(as_uuid=True), nullable=False),
        sa.Column("provider", sa.String(length=32), nullable=False),
        sa.Column("external_id", sa.String(length=160), nullable=False),
        sa.Column("amount_brl", sa.Numeric(10, 2), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False, server_default="pending"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.UniqueConstraint("provider", "external_id", name="uq_payment_provider_external"),
    )
    op.create_index("ix_payments_user_id", "payments", ["user_id"])

    op.create_table(
        "webhook_events",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column("provider", sa.String(length=32), nullable=False),
        sa.Column("external_id", sa.String(length=160), nullable=False),
        sa.Column("event_type", sa.String(length=80), nullable=False),
        sa.Column("payload", sa.JSON(), nullable=False),
        sa.Column("processed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.UniqueConstraint("provider", "external_id", name="uq_webhook_provider_external"),
    )

    op.create_table(
        "cost_config",
        sa.Column("operation", sa.String(length=64), primary_key=True),
        sa.Column("credits", sa.Integer(), nullable=False),
        sa.Column("enabled", sa.Boolean(), nullable=False, server_default=sa.true()),
    )

    op.create_table(
        "admin_audit_log",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column("admin_id", sa.String(length=128), nullable=False),
        sa.Column("action", sa.String(length=64), nullable=False),
        sa.Column("target_user_id", sa.Uuid(as_uuid=True), nullable=True),
        sa.Column("payload", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.ForeignKeyConstraint(["target_user_id"], ["users.id"], ondelete="SET NULL"),
    )
    op.create_index("ix_admin_audit_log_admin_id", "admin_audit_log", ["admin_id"])

    cost_table = sa.table(
        "cost_config",
        sa.column("operation", sa.String()),
        sa.column("credits", sa.Integer()),
        sa.column("enabled", sa.Boolean()),
    )
    op.bulk_insert(cost_table, COST_SEED)


def downgrade() -> None:
    op.drop_index("ix_admin_audit_log_admin_id", table_name="admin_audit_log")
    op.drop_table("admin_audit_log")
    op.drop_table("cost_config")
    op.drop_table("webhook_events")
    op.drop_index("ix_payments_user_id", table_name="payments")
    op.drop_table("payments")
    op.drop_index("ix_generations_idempotency_key", table_name="generations")
    op.drop_index("ix_generations_user_id", table_name="generations")
    op.drop_table("generations")
    op.drop_index("ix_credit_ledger_reservation", table_name="credit_ledger")
    op.drop_index("ix_credit_ledger_user_created", table_name="credit_ledger")
    op.drop_index("ix_credit_ledger_idempotency_key", table_name="credit_ledger")
    op.drop_index("ix_credit_ledger_user_id", table_name="credit_ledger")
    op.drop_table("credit_ledger")
    op.drop_table("credit_accounts")
    op.drop_column("users", "role")
