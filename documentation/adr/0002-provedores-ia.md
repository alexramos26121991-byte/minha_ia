# ADR 0002 — Provedores de IA

- Status: **Aceito para imagem (D1 confirmado); demais capacidades provisórias**
- Data: 2026-11-17
- Confirmação D1: 2026-11-17 — OpenAI GPT Image (`gpt-image-1`) como provedor oficial de texto→imagem.

## Contexto
O produto depende de modelos de imagem, vídeo, áudio e lip-sync. Esses serviços mudam de preço e disponibilidade com frequência e alguns podem não ser contratados no início.

## Decisão
Contratar por capacidade, atrás de abstrações no backend:

| Capacidade | Provedor recomendado | Flag |
|---|---|---|
| Texto → imagem | **GPT Image (OpenAI `gpt-image-1`) — confirmado**; alternativas fal.ai / Replicate | `IMAGE_GENERATION_ENABLED` + `IMAGE_PROVIDER` |
| Texto → vídeo e imagem → vídeo | Kling / Luma / Veo via fal.ai ou Replicate | `VIDEO_GENERATION_ENABLED` |
| Animar foto | mesmo provedor de vídeo | `VIDEO_GENERATION_ENABLED` |
| Voz (TTS) | ElevenLabs | `AUDIO_GENERATION_ENABLED` |
| Música / SFX | MusicGen ou Lyria | `AUDIO_GENERATION_ENABLED` |
| Avatar / lip-sync | Sync Labs ou Hedra | `AVATAR_ENABLED` (desligado) |

Interfaces obrigatórias: `ImageProvider`, `VideoProvider`, `AudioProvider`, `AvatarProvider`. Cada uma com `generate()` e adaptação de erro padronizada.

Para imagem, `IMAGE_PROVIDER=auto` escolhe OpenAI quando a chave existe e mock apenas em desenvolvimento. `mock` explícito (ou `auto` sem chave) com `APP_ENV=production` falha com 503: o provedor de development nunca entrega PNG sintético em produção. A chave fica somente no backend; o app nunca a recebe.

## Alternativas consideradas
- Chamar APIs de IA direto do app — rejeitado: vazamento de chaves e impossibilidade de controlar créditos.
- Um único provedor para tudo — rejeitado: qualidade e custo variam muito por capacidade.

## Consequências
- Trocar de provedor exige apenas um novo adaptador + ajuste em `cost_config`.
- Funcionalidades não contratadas aparecem como "em breve", nunca quebram o app.
- Webhooks de vídeo precisam de validação de assinatura (ver ADR 0005).
