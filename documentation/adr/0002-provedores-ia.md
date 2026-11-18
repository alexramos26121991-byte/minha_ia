# ADR 0002 — Provedores de IA

- Status: **Aceito para imagem (D1) e vídeo (D2); áudio/avatar provisórios**
- Data: 2026-11-17
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

Para imagem, `IMAGE_PROVIDER=auto` escolhe OpenAI quando a chave existe e mock apenas em desenvolvimento. `mock` explícito (ou `auto` sem chave) com `APP_ENV=production` falha com 503: o provedor de development nunca entrega PNG sintético em produção. A chave fica somente no backend; o app nunca a recebe.

Para vídeo, a mesma regra vale com `VIDEO_PROVIDER=auto|falai|mock`: `auto` usa fal.ai+Kling quando `FAL_API_KEY` existe e mock em desenvolvimento; `mock` (ou `auto` sem chave) com `APP_ENV=production` falha com 503. A geração é assíncrona: a Queue API do fal.ai devolve `request_id` + URLs de status/resultado, o webhook é preferencial e o polling é fallback. Webhooks são verificados por assinatura ED25519 contra o JWKS `https://rest.fal.ai/.well-known/jwks.json` (janela de 5 min) e registrados de forma idempotente em `webhook_events`. Chaves ficam somente no backend.

**Escopo de D2:** entregar a camada de provedor (`VideoProvider`, `FalVideoProvider`, `MockVideoProvider`), a verificação de webhook, o registro idempotente de eventos e seus testes. Os endpoints `POST /generations/video` e `/animate-photo` permanecem 501 até a E5; `VIDEO_GENERATION_ENABLED` continua `false`.

## Alternativas consideradas
- Chamar APIs de IA direto do app — rejeitado: vazamento de chaves e impossibilidade de controlar créditos.
- Um único provedor para tudo — rejeitado: qualidade e custo variam muito por capacidade.

## Consequências
- Trocar de provedor exige apenas um novo adaptador + ajuste em `cost_config`.
- Funcionalidades não contratadas aparecem como "em breve", nunca quebram o app.
- Webhooks de vídeo precisam de validação de assinatura (ver ADR 0005).
