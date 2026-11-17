# ADR 0007 — Privacidade e LGPD

- Status: **Aceito (provisório — prazos a validar juridicamente)**
- Data: 2026-11-17

## Contexto
O sistema lida com fotos de usuários, prompts, pagamentos e um ledger financeiro append-only. A LGPD exige exclusão/anonimização, mas auditoria exige retenção.

## Decisão
- **Mídia e prompts:** podem ser excluídos a qualquer momento pelo usuário na Galeria; exclusão remove o arquivo do Storage e marca o registro como `deleted` (soft delete com purga física em 30 dias).
- **Ledger e payments:** **anonimizar** em vez de excluir. Substituir `user_id` identificável por hash irreversível, manter valores e datas por **5 anos** para auditoria financeira.
- **Exportação:** usuário pode pedir exportação de seus dados em JSON.
- **Consentimento:** termos e política aceitos no cadastro, com versão registrada.
- **FCM token:** removido no logout e na exclusão de conta.
- **Prompts:** enviados ao provedor de IA apenas para geração; não usados para treino (contrato a confirmar com cada provedor).

## Alternativas consideradas
- Excluir tudo — inviável: quebra auditoria de créditos e pagamentos.
- Reter tudo sem anonimizar — descumpre LGPD.

## Consequências
- O schema precisa de campos `deleted_at`, `anonymized_at` e `consent_version`.
- O job de anonimização entra na E9.
- A tabela `credit_ledger` permanece append-only: anonimização altera apenas a referência ao usuário, nunca os valores.
