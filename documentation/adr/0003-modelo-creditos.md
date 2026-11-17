# ADR 0003 — Modelo de créditos e custos

- Status: **Aceito (provisório — valores a validar com preços reais dos provedores)**
- Data: 2026-11-17

## Contexto
Créditos são a unidade de consumo: o usuário paga em reais, o sistema converte em créditos, e cada geração debita créditos. O modelo precisa ser auditável, idempotente e à prova de falha de API.

## Decisão

**Farol:** 1 crédito ≈ **R$ 0,05** de receita (custo marginal + margem). Câmbio de referência: R$ 5,50 por US$ 1,00.

### Tabela mestre de custo (provisória)

| Operação | Custo API estimado | Créditos | Receita equivalente |
|---|---:|---:|---:|
| Imagem 1024×1024 | US$ 0,04 (~R$ 0,22) | 5 | R$ 0,25 |
| Imagem 1536×1024 | US$ 0,08 (~R$ 0,44) | 9 | R$ 0,45 |
| Vídeo 5s / 720p | US$ 0,30 (~R$ 1,65) | 35 | R$ 1,75 |
| Vídeo 10s / 720p | US$ 0,60 (~R$ 3,30) | 70 | R$ 3,50 |
| Animar foto 5s | US$ 0,25 (~R$ 1,38) | 30 | R$ 1,50 |
| Voz (TTS) 1 min | US$ 0,18 (~R$ 0,99) | 20 | R$ 1,00 |
| Música 30s | US$ 0,10 (~R$ 0,55) | 12 | R$ 0,60 |
| Avatar / lip-sync 5s | US$ 0,50 (~R$ 2,75) | 60 | R$ 3,00 |

Valores ficam na tabela `cost_config` no banco — **nunca no cliente**.

### Mecânica
1. `reserve(user, amount, idempotency_key)` congela créditos.
2. Geração executada.
3. `commit(reservation)` efetiva ou `refund(reservation)` devolve em erro/timeout.
4. `credit_ledger` é append-only, com `balance_after`.
5. Job `reconcile_orphan_reservations` estorna reservas órfãs (> 15 min sem commit) a cada 5 min.
6. Nenhuma operação pode levar saldo a negativo, mesmo em concorrência.

## Alternativas consideradas
- Debitar diretamente na chamada — rejeitado: falha da API deixaria o usuário sem crédito e sem resultado.
- Saldo apenas no Firestore — rejeitado: regras divergentes e corrida entre client e server.

## Consequências
- Toda geração exige `idempotency_key`.
- Ajustes manuais de crédito pelo admin são auditados.
- A tabela de custos precisa ser revisitada quando os preços reais dos provedores forem confirmados (E1c/E4).
