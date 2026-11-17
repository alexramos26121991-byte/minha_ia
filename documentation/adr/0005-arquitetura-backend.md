# ADR 0005 — Arquitetura do backend e fluxo de geração

- Status: **Aceito**
- Data: 2026-11-17

## Contexto
Geração de vídeo é lenta (segundos a minutos); imagem pode ser rápida, mas ainda assim pode sofrer timeout. O backend precisa não bloquear requisições e não perder créditos.

## Decisão

### Camadas
```
app/
  core/        config, segurança, exceções, db
  users/       auth, perfil, fcm_token
  credits/     ledger, reserva, reconciliador
  generation/  providers, serviço, endpoints, workers, webhooks
  payments/    checkout, webhooks, planos
  admin/       operações e auditoria
```

### Fluxo de imagem (síncrono com guarda)
`POST /generations/image` → reserva → `ImageProvider` (timeout do gateway 25s < provedor 30s) → Storage → `generations` → commit. Em `TimeoutError`/erro: refund + status `failed`.

### Fluxo de vídeo (assíncrono)
`POST /generations/video` → reserva → cria job → **202 + job_id** → worker Celery chama `VideoProvider` (webhook assinado + polling de fallback) → Storage → `generations` → commit → FCM. Falha após N tentativas: refund + notificação.

### Segurança
- Firebase ID token validado no middleware; o app nunca chama provedores diretamente.
- Upload via URL assinada com MIME/tamanho validados no backend.
- Webhooks: assinatura verificada + `webhook_events` com unique key.
- OpenAPI é o contrato; cliente Dart gerado e atualizado em toda etapa que mexe em endpoint.

## Alternativas consideradas
- Síncrono para tudo — rejeitado: timeouts de gateway e travamento do app.
- Serverless puro sem fila — rejeitado: jobs longos de vídeo são caros e frágeis.

## Consequências
- Redis e Celery são dependências obrigatórias desde a E1c.
- Reconciliador de reservas órfãs é implementado na E3, não no fim do projeto.
