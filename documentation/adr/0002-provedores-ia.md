# ADR 0002 — Provedores de IA

- Status: **Aceito para imagem (D1) e vídeo (D2); áudio/avatar provisórios**
- Data: 2026-11-17
- Atualização: 2026-11-18 — E5 concluída: provedor de vídeo ligado ao worker, webhook e upload.
- Atualização: 2026-11-19 — F0: mock passou a ser **opt-in** (`ALLOW_MOCK_PROVIDERS=true`); `auto` exige provedor real em qualquer ambiente; hardening de JWKS/SSRF e health real.
- Confirmação D1: 2026-11-17 — OpenAI GPT Image (`gpt-image-1`) como provedor oficial de texto→imagem.
- Confirmação D2: 2026-11-17 — **fal.ai + Kling** como provedor oficial de texto→vídeo, imagem→vídeo e animar foto.

## Contexto
O produto depende de modelos de imagem, vídeo, áudio e lip-sync. Esses serviços mudam de preço e disponibilidade com frequência e alguns podem não ser contratados no início.

## Decisão
Contratar por capacidade, atrás de abstrações no backend:

| Capacidade | Provedor recomendado | Flag |
|---|---|---|
| Texto → imagem | **GPT Image (OpenAI `gpt-image-1`) — confirmado**; alternativas fal.ai / Replicate | `IMAGE_GENERATION_ENABLED` + `IMAGE_PROVIDER` |
| Texto → vídeo e imagem → vídeo | **fal.ai + Kling (`fal-ai/kling-video/v3/pro/{text-to-video,image-to-video}`) — confirmado**; Luma/Veio via fal.ai como alternativa | `VIDEO_GENERATION_ENABLED` + `VIDEO_PROVIDER` |
| Animar foto | mesmo provedor de vídeo (Kling image-to-video) | `VIDEO_GENERATION_ENABLED` |
| Voz (TTS) | ElevenLabs | `AUDIO_GENERATION_ENABLED` |
| Música / SFX | MusicGen ou Lyria | `AUDIO_GENERATION_ENABLED` |
| Avatar / lip-sync | Sync Labs ou Hedra | `AVATAR_ENABLED` (desligado) |

Interfaces obrigatórias: `ImageProvider`, `VideoProvider`, `AudioProvider`, `AvatarProvider`. Cada uma com `generate()` e adaptação de erro padronizada.

Para imagem, `IMAGE_PROVIDER=auto` **exige OpenAI**: sem `OPENAI_API_KEY`, a seleção falha com 503 em qualquer ambiente, inclusive desenvolvimento. `IMAGE_PROVIDER=mock` só é aceito com `ALLOW_MOCK_PROVIDERS=true` e é recusado com 503 em produção: o provedor sintético nunca é entregue como geração real. A chave fica somente no backend; o app nunca a recebe.

Para vídeo, a mesma regra vale com `VIDEO_PROVIDER=auto|falai|mock`: `auto` exige fal.ai+Kling e falha com 503 sem `FAL_API_KEY` em qualquer ambiente; `mock` depende do mesmo opt-in e nunca roda em produção. A geração é assíncrona: a Queue API do fal.ai devolve `request_id` + URLs de status/resultado, o webhook é preferencial e o polling é fallback. Webhooks são verificados por assinatura ED25519 contra o JWKS `https://rest.fal.ai/.well-known/jwks.json` (janela de 5 min) e registrados de forma idempotente em `webhook_events`. Em produção, `FAL_WEBHOOK_USER_ID` é obrigatório. O cache do JWKS é compartilhado por instância (evita um fetch por request) e serve chaves antigas em caso de indisponibilidade temporária do endpoint. A URL de origem da imagem passa por validação SSRF (hosts privados, loopback, credenciais e portas não padrão bloqueados) e o MP4 baixado precisa conter a assinatura `ftyp`. Chaves ficam somente no backend.

**Escopo de D2:** entregar a camada de provedor (`VideoProvider`, `FalVideoProvider`, `MockVideoProvider`), a verificação de webhook, o registro idempotente de eventos e seus testes. **Conclusão na E5 (2026-11-18):** `POST /generations/video` e `POST /generations/animate-photo` respondem 202 com job assíncrono; `VIDEO_GENERATION_ENABLED` passou a `true` no default; `POST /webhooks/falai` foi ligado ao worker, com polling como fallback. O upload seguro entrou em `POST /generations/uploads` (MIME + magic bytes + 10 MB).

**Notificações:** o app consome eventos de mudança de status por uma abstração `NotificationService`. Como o Firebase ainda não foi provisionado, a implementação é `NoopNotificationService` e o acompanhamento real hoje é feito por polling (`GET /generations/{id}`). A troca por FCM será feita por injeção, sem alterar as telas.

## Alternativas consideradas
- Chamar APIs de IA direto do app — rejeitado: vazamento de chaves e impossibilidade de controlar créditos.
- Um único provedor para tudo — rejeitado: qualidade e custo variam muito por capacidade.

## Consequências
- Trocar de provedor exige apenas um novo adaptador + ajuste em `cost_config`.
- Sem chave de provedor, a chamada falha fechado (503) com mensagem clara em pt-BR — nunca devolve mídia simulada. Na F0, a UI mobile deixou de usar "Em breve" e passou a mostrar aviso honesto de indisponibilidade; capacidades ainda não contratadas (voz/avatar) seguem atrás de flags desligadas.
- Webhooks de vídeo precisam de validação de assinatura (ver ADR 0005).
- Configuração de produção incompleta impede o boot: `Settings` valida chaves, segredos e `ALLOW_MOCK_PROVIDERS=false` no startup.
