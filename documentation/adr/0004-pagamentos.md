# ADR 0004 — Pagamentos e planos

- Status: **Aceito (provisório — preços aguardando confirmação)**
- Data: 2026-11-17

## Contexto
Monetização por assinatura mensal e pacotes avulsos de créditos. público principal no Brasil, onde Pix é essencial.

## Decisão

### Planos

| Plano | Créditos/mês | Preço mensal |
|---|---:|---:|
| Gratuito | 30 | R$ 0,00 |
| Básico | 300 | R$ 29,90 |
| Pro | 1.000 | R$ 89,90 |
| Premium | 3.000 | R$ 249,90 |

Pacote avulso: **100 créditos por R$ 9,90**.

### Provedores
- **Stripe** para cartão internacional.
- **Mercado Pago** para Pix e meios brasileiros.
- `PaymentProvider` abstrai ambos.

### Regras
- Dados de cartão nunca passam pelo app — checkout hosted do provedor.
- `POST /payments/webhook` valida assinatura; eventos são gravados em `webhook_events` com chave única.
- Creditar plano + `credit_ledger` + registrar `payments` acontece em **uma transação**.
- Reenviar o mesmo webhook não duplica créditos.
- Reembolso/chargeback revoga o plano; registros financeiros não são apagados.

## Alternativas consideradas
- Pagamento via lojas (IAP) — inviabilizaria créditos compartilhados e vendas avulsas; pode ser avaliado depois para conformidade com as lojas.
- Apenas Stripe — deixa o mercado brasileiro mal atendido.

## Consequências
- Planos são semeados no banco na E1c.
- A tela de planos no app consome os planos do backend, não hardcoded.
- Webhooks exigem segredo configurado no `.env`.
