"""Rotas de pagamento — implementação na E7 (Stripe + Mercado Pago/Pix)."""

from fastapi import APIRouter, Depends, Header

from app.core.errors import not_implemented
from app.core.security import get_current_user_id
from app.payments.schemas import CheckoutIn, CheckoutOut, PaymentOut

router = APIRouter(prefix="/payments", tags=["payments"])


@router.post(
    "/checkout",
    response_model=CheckoutOut,
    operation_id="createCheckout",
    summary="Cria checkout hosted (cartão/Pix) — nunca expõe dados de cartão no app",
)
async def create_checkout(
    payload: CheckoutIn,
    user_id: str = Depends(get_current_user_id),
) -> CheckoutOut:
    raise not_implemented("E7")


@router.post(
    "/webhook",
    operation_id="handlePaymentWebhook",
    summary="Recebe webhook assinado, deduplica e credita em uma transação",
    description="Público: validação por assinatura, não por token do app.",
)
async def handle_payment_webhook(
    x_signature: str | None = Header(default=None, alias="X-Signature"),
) -> dict[str, str]:
    raise not_implemented("E7")


@router.get(
    "",
    response_model=list[PaymentOut],
    operation_id="listPayments",
    summary="Lista pagamentos do usuário",
)
async def list_payments(
    user_id: str = Depends(get_current_user_id),
) -> list[PaymentOut]:
    raise not_implemented("E7")
