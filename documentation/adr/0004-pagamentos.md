# ADR 0004 — Pagamentos e planos

- Status: **Aceito (provisório — preços aguardando confirmação)**
- Data: 2026-11-17
- Atualização: 2026-11-19 — F0: a tela de planos do app virou "Prévia dos planos", sem checkout simulado e com preços rotulados como previstos; os preços abaixo seguem **provisórios** e os endpoints de pagamento permanecem 501 até a E7.

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
- A tela de planos no app consome os planos do backend, não hardcoded. Como o checkout real ainda não existe (E7 pendente), a F0 removeu o botão de pagamento simulado: a tela mostra "Prévia dos planos", avisa que a contratação está indisponível e marca os valores como "previsto".
- Webhooks exigem segredo configurado no `.env`.
- D5 (provedor/pagamento efetivo) e D11 (preços finais) continuam em aberto; nenhuma cobrança é realizada antes da E7.
