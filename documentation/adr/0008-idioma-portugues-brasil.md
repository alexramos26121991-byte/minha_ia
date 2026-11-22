# ADR 0008 — Idioma português do Brasil (pt-BR)

- Status: **Aceito**
- Data: 2026-11-22

## Contexto
O produto é brasileiro e toda a interface já era escrita em português. Ainda
assim, existiam lacunas reais: os prompts enviados à OpenAI e à fal.ai não
pediam explicitamente português do Brasil, o Flutter não declarava locale
(usando o idioma do dispositivo), mensagens automáticas do FastAPI/Pydantic/Starlette
vinham em inglês (422 `Field required`, 403 `Not authenticated`, `Validation Error`
no OpenAPI) e os containers não fixavam locale/fuso.

## Decisão
Adotar **pt-BR como idioma único do produto**, em todas as camadas:

1. **Prompts de geração:** todo prompt enviado aos provedores termina com a
   instrução `Idioma: português do Brasil (pt-BR). Use português do Brasil em
   todo texto visível, incluindo legendas e letreiros.` A composição fica
   centralizada em `app/generation/providers/language.py` e é usada por
   `openai.py` e `falai.py`. Sem prompt e sem movimento, o prompt de vídeo
   continua vazio para não alterar o comportamento do modelo que recebe só a
   imagem de origem.
2. **API:** handlers próprios traduzem erros de validação (mantendo `loc`,
   `type`, `input` e `ctx` do contrato) e os detalhes genéricos do Starlette.
   `HTTPBearer` deixou de gerar o 403 em inglês: a ausência de credencial agora
   responde 401 com mensagem em pt-BR e `WWW-Authenticate: Bearer`. As
   descrições padrão do OpenAPI também passam a ser pt-BR.
3. **Mobile:** `MaterialApp.router` declara `locale`, `supportedLocales` e os
   delegates de localização do Flutter. `intl` formata moeda e data em pt_BR;
   rótulos relativos da galeria foram centralizados em `lib/l10n/pt_br.dart`.
   Android e iOS declaram pt-BR como região de desenvolvimento/localização.
4. **Containers:** `LANG=C.UTF-8`, `LC_ALL=C.UTF-8` e
   `TZ=America/Sao_Paulo` no `Dockerfile`, no compose base (backend, Postgres e
   Redis) e no `.env.example`.

## Alternativas consideradas
- Confiar apenas no idioma do prompt do usuário — rejeitado: modelos podem gerar
  texto em inglês dentro de imagens/vídeos mesmo com pedido em português.
- Traduzir com ARB/l10n completo no Flutter — adiado: a UI já é hardcoded em
  pt-BR e não há seletor de idioma; a infra de locale + formatação atende ao
  escopo sem duplicar todos os textos.
- Internacionalizar a API com múltiplos idiomas — rejeitado: o produto tem um
  único idioma oficial; traduzir mensagens e descrições é suficiente.

## Consequências
- Novos provedores de geração devem usar `compor_prompt_imagem`/
  `compor_prompt_video` em vez de montar prompts diretamente.
- Novos validadores devem escrever mensagens em pt-BR ou usar um código de erro
  mapeado em `app/core/errors.py`.
- O contrato `backend/openapi.yaml` muda nas descrições (não em paths/schemas).
  O cliente Dart gerado não incorpora descrições de resposta, então não há
  delta de código gerado.
- Não há seletor de idioma: se o produto vir multilíngue, esta decisão precisará
  ser revisada.
