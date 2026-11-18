# MINHA IA — Plano de Execução Completo

> Status: **Em execução — E0 a E5 concluídas** · Versão: 1.2 · Data: 2026-11-18
> Objetivo: transformar a especificação do produto em etapas executáveis, ordenadas e verificáveis.
> Foco da primeira entrega: **UI + funcional equilibrados** (app navegável com identidade visual real e fluxos reais ponta a ponta).

---

## 0. Pré-requisitos do ambiente

Antes da E0, garantir instalado e funcionando:

| Ferramenta | Versão mínima | Uso |
|---|---|---|
| Flutter SDK + Dart | 3.x / 3.x | app Android/iOS |
| Android Studio + SDK | recente | build Android, emulador |
| **macOS + Xcode** | recente | build iOS e TestFlight — **não é possível no Windows** |
| Python | 3.11+ | backend |
| Node.js + npm | 18+ | admin, Redocly |
| Docker Desktop | recente | Postgres, Redis, API |
| **JDK** | 17 | `openapi-generator` (cliente Dart) |
| Firebase CLI | recente | Auth, FCM, Storage |
| Stripe CLI | recente | teste de webhooks (E7) |

> **Ambiente atual é Windows.** Verificação local cobre Android + backend + admin. iOS é verificado apenas em runner macOS na CI e via TestFlight. Nenhum comando deste plano assume shell POSIX.

---

## 1. Visão geral

**MINHA IA** é uma plataforma mobile (Android + iOS) de criação de imagens e vídeos com IA, com:

- Identidade visual própria: tema escuro, futurista, paleta roxa.
- 6 telas principais distribuídas em 5 abas de navegação inferior.
- Sistema de créditos como unidade de consumo e monetização.
- Backend FastAPI como **fonte da verdade** (auth, créditos, geração, pagamentos, admin).
- Integração com modelos de IA substituíveis por provedor.
- Painel administrativo web.

**Princípio orientador:** construir um *slice vertical* real dentro de uma casca visual completa. Após a E5, **Home, Criar imagem, Criar vídeo, Animar foto, Galeria e Perfil são reais**; apenas **Efeitos segue como "em breve" de forma honesta** — sem botões que fingem funcionar. Isso evita tanto o app "fake" quanto o backend órfão.

---

## 2. Premissas e decisões em aberto

Estas decisões **devem ser fechadas na E0**:

| # | Decisão | Recomendação | Por quê |
|---|---|---|---|
| D1 | Provedor de imagens | **Confirmado: GPT Image via OpenAI** (`gpt-image-1`); fal.ai/Replicate como alternativas | Qualidade e estabilidade; abstração permite trocar |
| D2 | Provedor de vídeo | **Confirmado: fal.ai + Kling** (`fal-ai/kling-video/v3/pro/{text-to-video,image-to-video}`); Luma/Veio via fal.ai como alternativas | Geração assíncrona via Queue API, webhook assinado, custo por segundo |
| D3 | Provedor de áudio | ElevenLabs (voz) + MusicGen/Lyria (música) | Separar por capacidade |
| D4 | Lip-sync / avatares | Sync Labs ou Hedra — **flag desligada no início** | Não pode bloquear o MVP |
| D5 | Pagamentos | Stripe + Mercado Pago/Pix | Pix é quase obrigatório no BR |
| D6 | Repositório Git | **Inicializar na E0** | Sem rollback não há execução segura |
| D7 | Deploy backend | Cloud Run ou Fly.io + Redis gerenciado | Suporta jobs longos |
| D8 | Painel admin | Next.js com auth separada | Mais rápido que Flutter Web para tabelas/gráficos |
| D9 | Fonte da verdade | Backend. Notificações via **FCM Admin SDK**; Firestore opcional só para estado leve espelhado por Cloud Function | Evita regras de crédito divergentes |
| D10 | Chaves de API | **Somente no backend**, nunca no app | Segurança |
| D11 | Preços dos planos | Gratuito R$ 0 / Básico R$ 29,90 / Pro R$ 89,90 / Premium R$ 249,90 mensais; pacote avulso de 100 créditos a R$ 9,90 — **confirmar** | Necessário para E0/E7 |
| D12 | Privacidade | Anonimização com retenção de 5 anos para ledger/pagamentos; exclusão de mídia sob demanda | Ledger é append-only por auditoria (LGPD) |

**Referências visuais** a usar na E1: PixVerse (fluxo de criação), Regen (edição), Reelme (cards), Dribbble/Behance (UI escura futurista), Super Admin Dashboard (painel).

---

## 3. Critérios de sucesso por entrega

### MVP-0 — "Primeira entrega equilibrada" (E0 → E4)
- [ ] App roda em Android; iOS via build na CI macOS + TestFlight.
- [ ] **5 abas** navegáveis com tema e identidade visual aplicados.
- [x] **4 telas reais na E4:** Home (saldo real), Criar imagem, Galeria, Perfil.
- [x] **Criar vídeo e Animar foto reais na E5**; apenas Efeitos permanece honestamente "em breve".
- [x] Login/cadastro reais (modo dev local); backend com OpenAPI publicado e cliente Dart gerado.
- [ ] **Fluxo real:** prompt → estilo/tamanho → gerar → crédito debitado → imagem salva → Galeria.
- [ ] Falha estorna o crédito; erro claro em português.
- [ ] `flutter analyze`, `flutter test`, `pytest`, lint OpenAPI passando.

### MVP-1 — "Produto vendável" (E5 → E8)
- [x] Texto→vídeo e Animar foto com jobs assíncronos (202 + fila + worker + webhook/polling).
- [ ] Notificação push real — E5 entrega a abstração `NotificationService` (no-op); FCM depende de Firebase provisionado.
- [ ] Compra de créditos e assinaturas (30 / 300 / 1.000 / 3.000).
- [ ] Painel admin operacional (8 áreas).
- [ ] Efeitos e áudio conforme contratação dos modelos.

### MVP-2 — "Escala e confiança" (E9)
- [ ] CI/CD, deploy, observabilidade, moderação, anonimização LGPD, E2E.

---

## 4. Grafo de dependências e paralelismo

```
E0 Decisões + Git + ADRs
 └─ E1 Fundação (E1a tema / E1b telas / E1c backend+contrato+Firebase)
     └─ E2 Autenticação, Usuário, FCM token
         └─ E3 Ledger de créditos + reconciliação mínima
             ├─ E4 Imagem (TEXT→IMAGE)          [Lane A - UI+funcional]
             │   └─ E5 Vídeo (T2V, I2V, animar) [Lane A]
             │       └─ E6 Efeitos/Áudio/Avatares [Lane A - flags]
             ├─ E7 Pagamentos e planos           [Lane B - paralelo a A]
             └─ E8 Painel administrativo         [Lane C - depende E5,E7]
→ E9 Qualidade/Deploy/Observabilidade (após E4–E8)
```

| Lane | Etapas | Superfície de arquivos (isolar) |
|---|---|---|
| A — Geração | E4 → E5 → E6 | `backend/app/generation/**`, `mobile/lib/screens/{video,image,effects}/**` |
| B — Receita | E7 | `backend/app/payments/**`, `backend/app/plans/**`, `mobile/lib/screens/subscription/**` |
| C — Admin | E8 | `admin/**` |

**Regra de ouro do contrato:** o OpenAPI é **entregue na E1c**, mas toda etapa que adiciona ou altera endpoint **deve** atualizar `backend/openapi.yaml`, regerar o cliente Dart e conferir o diff no mesmo commit. É uma sub-tarefa obrigatória, não uma ação única da E1.

---

## 5. Convenção de execução de cada etapa

Cada etapa traz: **contexto**, **tarefas**, **verificação**, **critérios de saída**, **rollback** e **arquivos tocados**. Um agente novo deve conseguir executar qualquer etapa lendo somente o brief dela + o ADR relevante.

- **Modelo:** `strongest` em E0, E3 (revisão) e E9 (revisão final); `default` para implementação.
- **Commits:** E1 é dividida em E1a/E1b/E1c; E8 e E9 também devem ser fatiadas em 2–3 commits (ex.: E8a dados, E8b telas, E9a testes, E9b CI, E9c deploy).
- **Comandos:** todos em PowerShell, executados na raiz `minha_ia/` salvo indicação.

---

## 6. Etapas detalhadas

---

### E0 — Fundação de decisões, Git e documentação-base

- **Dependências:** nenhuma · **Modelo:** strongest

**Contexto:** pasta `minha_ia/` recém-criada; sem Git.

**Tarefas**
1. `git init` + `.gitignore` (`.env`, `*.jks`, `build/`, `__pycache__/`, `.dart_tool/`, `google-services.json`, `GoogleService-Info.plist`) + primeiro commit.
2. Fechar D1–D12; registrar ADRs em `documentation/adr/`: `0001-stack`, `0002-provedores-ia`, `0003-modelo-creditos`, `0004-pagamentos`, `0005-arquitetura-backend`, `0006-admin-web`, `0007-privacidade-lgpd`.
3. `documentation/PRD.md` consolidando telas, módulos e planos.
4. `documentation/arquitetura.md` com diagrama C4 (containers) e fluxo de geração.
5. **Tabela mestre de custos:** operação → custo real estimado da API → margem → créditos cobrados. Ex.: 1 crédito ≈ R$ 0,05. Incluir imagem 1024, vídeo 5s/10s, TTS por minuto, avatar.
6. **Tabela de planos** com créditos, preço (D11), recorrência e regras de upgrade/downgrade.
7. Regras de retenção/anonimização (D12) no ADR 0007 e no schema.
8. `.env.example` com todas as variáveis sem valores reais (Firebase, Storage, Redis, Postgres, provedores, pagamentos).

**Verificação (PowerShell)**
```powershell
git status --short
(Get-ChildItem documentation/adr -Filter *.md).Count          # esperado: 7
Get-ChildItem -Recurse -Filter *.md -Path documentation | Select-String -Pattern 'sk-|AIza'
```

**Critérios de saída**
- [ ] Repo com commit inicial.
- [ ] 12 decisões fechadas e 7 ADRs.
- [ ] Tabelas de custo e de planos aprovadas.
- [ ] Nenhuma credencial real no repo.

**Rollback:** `git reset --soft HEAD~1` (mantém arquivos).

**Arquivos:** `documentation/**`, `.gitignore`, `.env.example`.

---

### E1 — Fundação (dividida em E1a, E1b, E1c)

**Contexto:** E0 concluída.

#### E1a — Tema e Design System

**Tarefas**
1. `flutter create` com organize paths; `pubspec.yaml`: `go_router`, `flutter_riverpod`, `dio`, `freezed`, `cached_network_image`, `flutter_secure_storage`, `firebase_core`.
2. Tema: fundo `#10101C`, primário `#7651D8`, luminoso `#B69AFF`, cartões `#1D1B2B`, texto branco/cinza claro. Tipografia e espaçamentos tokenizados.
3. Componentes base: `AppButton`, `AppCard`, `CreditBadge`, `GradientHeader`, `GenerationTile`, `EmptyState`, `LoadingShimmer`, `SoonPlaceholder`.

**Verificação:** `flutter analyze` · `flutter test test/theme/`

**Saída:** tokens e componentes com testes de widget; 0 avisos de analyze.

#### E1b — Casca navegável

**Tarefas**
1. Bottom navigation com **5 abas exatas do spec**: Início, Criar, Imagens, Galeria, Perfil.
2. Mapeamento das 6 telas principais sem ambiguidade:
   - `Início` → Home (Tela 1)
   - `Criar` → hub: Criar vídeo (Tela 2) + Animar foto (Tela 3)
   - `Imagens` → Criar imagem (Tela 4) + sub-aba Efeitos (auxiliar)
   - `Galeria` → Tela 5 com filtros **Vídeos / Imagens criadas / Downloads / Projetos**
   - `Perfil` → Tela 6 (Perfil e planos)
3. Telas de vídeo, animar foto e efeitos usam `SoonPlaceholder` com ícone e texto "Em breve — disponível na próxima versão". Nenhum botão finjo.
4. Instalar `go_router` com rotas nomeadas e deep links.

**Verificação:** `flutter test test/navigation/` · capturar screenshots via `integration_test` em runner (Android local / CI macOS para iOS).

**Saída:** 5 abas navegáveis, rotas nomeadas, screenshots em `documentation/screenshots/`.

#### E1c — Backend, contrato e infra

**Tarefas**
1. Backend: `fastapi`, `uvicorn`, `pydantic-settings`, `sqlalchemy`, `alembic`, `psycopg`, `celery`, `redis`; `app/{users,generation,credits,payments,admin,core}`.
2. **Migration inicial:** tabelas `users` e `plans` (necessárias já na E2 — não criar na E3). Seed dos 4 planos.
3. `GET /health`.
4. **Provisionar infra:** projeto Firebase, `google-services.json`, `GoogleService-Info.plist`, service account do Admin SDK, bucket GCS com CORS para upload. Documentar/env vars.
5. `backend/openapi.yaml` com contratos de `/auth`, `/users`, `/credits`, `/generations`, `/payments`, `/admin`. Gerar cliente Dart em `mobile/lib/services/api/generated/` com `openapi-generator` (JDK 17).
6. `docker-compose.yml`: `api`, `postgres`, `redis`.

**Verificação (PowerShell)**
```powershell
flutter analyze
flutter test
docker compose up --build -d
(Invoke-WebRequest -Uri http://localhost:8000/health -UseBasicParsing).StatusCode   # 200
npx @redocly/cli lint backend/openapi.yaml
cd backend; python -m alembic upgrade head; cd ..
```

**Saída:** health 200; OpenAPI válido; cliente Dart gerado; Firebase/GCS conectados; migration `users`/`plans` aplicada.

**Rollback:** `git revert <sha>` por sub-etapa (E1a/E1b/E1c são commits separados).

**Arquivos:** `mobile/lib/{theme,widgets,screens,services/api}`, `backend/app/**`, `backend/openapi.yaml`, `docker-compose.yml`.

---

### E2 — Autenticação, usuário e FCM

- **Dependências:** E1 (tabelas `users`/`plans` já existem) · **Modelo:** default

**Tarefas**
1. Firebase Auth: email/senha + Google + Apple (iOS).
2. Middleware backend `FirebaseAdminAuth` validando ID token; upsert do `users` no primeiro login.
3. `User`: `id`, `firebase_uid`, `email`, `display_name`, `plan_id`, `fcm_token`, `status`, `created_at`.
4. **Registrar `fcm_token` no login** (necessário para notificações da E5).
5. Tela login/cadastro/recuperação no tema; token em `FlutterSecureStorage`.
6. Perfil: dados, saldo (via `GET /credits/balance`, mesmo que provisório), plano, Configurações e Suporte.
7. Atualizar OpenAPI + regerar cliente Dart.

**Verificação**
```powershell
cd backend; python -m pytest tests/test_auth.py -q; cd ..
flutter test test/features/auth/
# manual: login → matar app → reabrir → sessão persistida → fcm_token gravado
```

**Saída:** login real nas plataformas; rotas protegidas retornam 401; registro criado no banco.

**Rollback:** flag `ENABLE_AUTH=false` com modo anônimo temporário.

---

### E3 — Motor de créditos e reconciliação mínima

- **Dependências:** E2 · **Modelo:** default + revisão strongest

**Tarefas**
1. Migrations: `credit_accounts`, `credit_ledger`, `generations`, `payments`, `cost_config`, `webhook_events`, `admin_audit_log`. (`users`/`plans` já existem.)
2. Ledger **append-only** com `idempotency_key`, `amount`, `reason`, `balance_after`, `created_at`.
3. `CreditService`: `reserve`, `commit`, `refund`, `get_balance`.
4. **Reconciliação mínima já aqui** (não deixar para E9): job `reconcile_orphan_reservations` que estorna reservas com mais de X minutos sem `commit`, executado a cada 5 min. Base para rollback de E4/E5.
5. Custos vêm de `cost_config`, nunca do client.
6. `GET /credits/balance`, `GET /credits/history`.
7. Admin mínimo: `POST /admin/users/{id}/credits` com log de auditoria.
8. Testes: corrida, idempotência, estorno, saldo negativo bloqueado, reconciliação.
9. Atualizar OpenAPI + regerar cliente Dart.

**Verificação**
```powershell
cd backend
python -m pytest tests/test_credits.py -q --cov=app.credits --cov-fail-under=85
python -m alembic upgrade head
python -m alembic downgrade -1
python -m alembic upgrade head
cd ..
```

**Saída:** saldo nunca negativo; estorno exato; idempotência; histórico consultável; reconciliador rodando.

**Rollback:** `alembic downgrade`; flag `CREDITS_ENFORCED=false` (modo auditoria).

---

### E4 — Slice vertical: Texto → Imagem

- **Dependências:** E3 · **Modelo:** default · **Lane:** A

**Tarefas**
1. `ImageProvider` abstraction + adaptador D1 com retry e timeout.
2. **Timeout do gateway (ex.: 25s) menor que o timeout do provedor (30s)** + handler que estorna em `TimeoutError`. Se o provedor ultrapassar sistematicamente 25s, migrar para job assíncrono na E5 (o reconciliador da E3 cobre órfãos).
3. `GenerationService`: reserva → provedor → Cloud Storage → grava `generations` → `commit`. Erro → `refund` + status `failed` + mensagem em português.
4. Endpoints: `POST /generations/image`, `GET /generations/{id}`, `GET /generations?type=image`, `DELETE /generations/{id}`.
5. **Criar imagem** funcional: prompt, estilos em cartões, resolução, formato, preview, custo visível antes de confirmar.
6. **Galeria** real: filtros Vídeos / Imagens criadas / Downloads / Projetos, thumbnails, download, compartilhar, deletar.
7. **Home** com saldo real + atalhos + cards de modelos populares.
8. Estados: carregando, sucesso, erro, saldo insuficiente (link para planos).
9. Atualizar OpenAPI + regerar cliente Dart.

**Verificação**
```powershell
cd backend; python -m pytest tests/test_generation_image.py -q; cd ..
flutter test test/features/image/ test/features/gallery/
# manual E2E: prompt → gerar → saldo cai → imagem na galeria → download
# manual falha: forçar timeout → estorno → mensagem aparece
```

**Saída:** fluxo completo em Android; iOS via CI; débito único; estorno em falha; galeria real.

**Rollback:** desligar `IMAGE_GENERATION_ENABLED`; estorno via `POST /admin/users/{id}/credits` ou reconciliador E3.

---

### E5 — Vídeo: Texto→vídeo, Imagem→vídeo, Animar foto

- **Status: CONCLUÍDA em 2026-11-18.**
- **Dependências:** E4 · **D2 (pré-entregue):** camada `VideoProvider`/`FalVideoProvider`/`MockVideoProvider`, `FalWebhookVerifier` (ED25519/JWKS) e `register_event()` idempotente já implementados e testados · **Modelo:** default · **Lane:** A

**Entregue:** `POST /generations/video` e `/generations/animate-photo` respondem 202 com job Celery/Redis; worker com polling (60 tentativas × 2 s), webhook `POST /webhooks/falai` verificado e idempotente como caminho preferencial, estorno em falha/timeout/rejeição do dispatcher, storage local com troca isolada na dependency, upload seguro em `POST /generations/uploads` (MIME + magic bytes + 10 MB), telas mobile com custo/progresso/erro/download `.mp4` e abstração de notificação. Contrato reexportado com 21 paths e cliente Dart regerado na mesma entrega.

**Tarefas**
1. Fila Celery + Redis. `POST /generations/video` retorna **202 + job_id** imediatamente.
2. ~~`VideoProvider` abstraction: `text_to_video`, `image_to_video`, `animate_photo`; polling + webhook.~~ **Feito na D2** (`submit()`/`status()`/`result()`, webhook preferencial, polling fallback). Falta ligar ao worker.
3. ~~**Validar assinatura do webhook do provedor** e registrar em `webhook_events` com chave única.~~ **Feito na D2**; falta o handler HTTP que chama `FalWebhookVerifier.verify()` + `register_event()`.
4. Worker: provedor → download → Cloud Storage → `generations` → `commit`. Retry com backoff; estorno após N tentativas.
5. ~~Parâmetros: modelo, duração (5s/10s), proporção (16:9, 9:16, 1:1), intensidade do movimento.~~ **Ajustado:** duração 5/10/15 s e resolução 480p/720p/1080p (parâmetros naturais do Kling); `motion` é texto livre em pt-BR ("Suave", "Dinâmico", "Cinematográfico") composto como `Movimento: <motion>`. Limite de 30 s em `VideoGenerationIn`.
6. **Upload seguro:** `POST /generations/uploads` recebe multipart e valida MIME + magic bytes (PNG/JPEG/WebP) e 10 MB no backend. A URL assinada de GCS fica pendente do provisionamento do bucket; hoje o storage é local.
7. Telas Criar vídeo e Animar foto deixam de ser "em breve"; acompanhamento de progresso via polling e abstração `NotificationService`. **FCM real fica no-op até o Firebase existir** (decisão do usuário); a troca é por injeção, sem mudar as telas.
8. Atualizar OpenAPI + regerar cliente Dart. **Feito:** 21 paths, Redocly válido, `openapitools.json` fixa o gerador 7.27.0.

**Verificação executada em 2026-11-18**
```powershell
cd backend; .\.venv\Scripts\python.exe -m pytest tests/ -q; cd ..   # 114 passed, 2 warnings
cd backend; .\.venv\Scripts\python.exe export_openapi.py; cd ..      # 21 paths
npx @redocly/cli lint backend/openapi.yaml                           # válido
flutter analyze                                                      # No issues found
flutter test --reporter compact                                      # 65 testes, verde
flutter build apk --debug                                            # OK (fora do OneDrive)
# pendente de infra: celery -A app.celery_app worker --loglevel=info
# pendente de chaves: gerar 5s 1080p → polling/webhook → vídeo na galeria → reproduzir
```

**Saída:** assíncrono sem travar API/app; vídeo correto na galeria; falha estorna. Notificação real depende de Firebase.

**Rollback:** desligar `VIDEO_GENERATION_ENABLED`; drenar fila; reconciliador E3 estorna órfãos.

---

### E6 — Efeitos, áudio e avatares (feature flags)

- **Dependências:** E5 · **Modelo:** default · **Lane:** A

**Tarefas**
1. Efeitos: estilos e transformações pré-definidas reaproveitando o pipeline de imagem/vídeo.
2. `AudioProvider`: voz (TTS), música e SFX; sincronização com vídeo.
3. Avatares/lip-sync atrás de flag, com `SoonPlaceholder` se o serviço não estiver contratado.
4. Tela Efeitos com catálogo e preview.
5. Cada capacidade com flag independente + entrada em `cost_config`.
6. Atualizar OpenAPI + regerar cliente Dart.

**Verificação:** `pytest tests/test_effects.py -q` · manual: desligar flag → "em breve" sem quebrar.

**Saída:** nenhuma tela quebra com provedor ausente; custos refletidos no ledger.

**Rollback:** desligar flags individualmente.

---

### E7 — Pagamentos, créditos avulsos e assinaturas

- **Dependências:** E3 (paralelo a E4–E6) · **Modelo:** default + revisão de webhook · **Lane:** B

**Tarefas**
1. `PaymentProvider` abstraction: Stripe + Mercado Pago/Pix (D5, D11).
2. Planos do banco já semeados na E1c: 30 / 300 / 1.000 / 3.000 créditos.
3. `POST /payments/checkout`, `POST /payments/webhook` com **verificação de assinatura**.
4. Tabela `webhook_events` (E3) com chave única: evento repetido é ignorado. Atualização de `plans` + `credit_ledger` + `payments` em **uma única transação**.
5. Compra avulsa de pacotes de créditos.
6. Tela Perfil/Planos: comparação, plano atual, checkout, histórico.
7. Chargeback, reembolso e falha de pagamento revertem o plano sem apagar registros.
8. Atualizar OpenAPI + regerar cliente Dart.

**Verificação**
```powershell
cd backend; python -m pytest tests/test_payments.py -q; cd ..
stripe listen --forward-to localhost:8000/payments/webhook
# manual: assinar Pro → webhook → 1.000 créditos → histórico
# manual: reenviar mesmo webhook → saldo não duplica
```

**Saída:** webhook assinado e idempotente; créditos e plano atualizados atomicamente; nada de cartão passa pelo app.

**Rollback:** `PAYMENTS_ENABLED=false`; webhooks em fallback manual; registros de `payments` nunca removidos.

---

### E8 — Painel administrativo web (fatiar em E8a/E8b/E8c)

- **Dependências:** E3, E5, E7 · **Modelo:** default · **Lane:** C

**Tarefas**
- **E8a — Dados e auth:** Next.js, roles `admin`/`super_admin`, clients da API, seed de fixture para gráficos.
- **E8b — Telas:** Dashboard (usuários, gerações, receita, custo, margem); Usuários (buscar, bloquear, ajustar créditos); Gerações (filtrar, ver, reprocessar, estornar); Planos; Pagamentos; Modelos de IA; Custos/consumo; Denúncias.
- **E8c — Auditoria e polish:** `admin_audit_log` imutável em toda ação; responsivo; testes.

**Verificação**
```powershell
cd admin; npm run lint; npm run test; npm run build; cd ..
cd backend; python -m pytest tests/test_admin.py -q; cd ..
# manual: admin adiciona 50 créditos → ledger do usuário + log
```

**Saída:** 8 áreas operacionais; ajuste auditado refletido no app; gráfico conferido contra fixture do ledger.

**Rollback:** desligar deploy do admin; backend segue funcionando.

---

### E9 — Qualidade, segurança, deploy e observabilidade (fatiar em E9a/E9b/E9c)

- **Dependências:** E4–E8 · **Modelo:** strongest na revisão final

**Tarefas**
- **E9a — Testes:** unit, widget, integração, E2E (`integration_test` no app; Playwright no admin). Cobertura ≥ 80%.
- **E9b — Segurança e compliance:** rate limiting, moderação de prompts, sanitização, secrets em vault, CORS/headers; anonimização LGPD com retenção (D12), exportação de dados; **submission** pronta para lojas (não "aprovação", que depende de revisão externa).
- **E9c — CI/CD e observabilidade:** GitHub Actions (Flutter analyze/test/build APK, pytest --cov, lint OpenAPI, Docker, Cloud Run, Fastlane/TestFlight em runner macOS); logs estruturados; métricas de latência, falha e **consumo projetado via `cost_config`**; alertas de margem negativa calculados pela tabela de custos; backup do Postgres; runbook.

**Verificação**
```powershell
flutter analyze
flutter test
flutter build apk --release
cd backend; python -m pytest --cov=app --cov-fail-under=80; cd ..
cd admin; npm audit --audit-level=high; cd ..
# smoke pós-deploy: health, login, geração imagem, webhook, admin
```

**Saída:** CI verde do zero; deploy reproduzível com rollback; alertas de custo; submission pronta.

**Rollback:** revert de tag; runbook de incidentes.

---

## 7. Riscos e mitigações

| Risco | Impacto | Mitigação |
|---|---|---|
| Custo de API estourar margem | Alto | Tabela E0; alertas via `cost_config`; limites por usuário |
| Timeout na geração de imagem prender crédito | Alto | Gateway < provedor + estorno (E4) + reconciliador (E3) |
| Vídeo demorar e travar app | Alto | 202 + fila + FCM desde E5 |
| Crédito duplicado/não debitado | Alto | Ledger, reserva/commit/refund, `webhook_events` unique |
| Provedor mudar API | Médio | Abstrações `ImageProvider`/`VideoProvider`/`AudioProvider` |
| Rejeição nas lojas por conteúdo IA | Médio | Moderação E9 + política + flags |
| Avatares travarem o projeto | Médio | Flag desde E6, fora do caminho crítico |
| iOS não verificável no Windows | Médio | CI macOS + TestFlight (E1b/E9c) |
| Webhook falso | Médio | Assinatura + unique key + transação única (E5/E7) |
| LGPD vs ledger imutável | Médio | Anonimização com retenção (D12/ADR 0007) |

---

## 8. Checklist transversal (todas as etapas)

- [ ] Nenhuma chave de API no repo ou no bundle do app.
- [ ] Nenhuma regra de crédito no client.
- [ ] Toda geração tem `idempotency_key`.
- [ ] **Toda etapa que mexe em endpoint atualizou `openapi.yaml` e regerou o cliente Dart.**
- [ ] Webhooks validam assinatura e gravam em `webhook_events`.
- [ ] Todo erro tem mensagem amigável em português.
- [ ] Tema escuro aplicado em toda tela nova.
- [ ] Commit atômico por sub-etapa, mensagem convencional (`feat:`, `fix:`, `docs:`).
- [ ] Documentação atualizada no mesmo commit da mudança.

---

## 9. Protocolo de mutação do plano

- **Split:** etapa grande → `E8a/E8b/E8c`; atualizar grafo e critérios.
- **Insert:** nova etapa → adicionar ao grafo com dependências explícitas.
- **Skip:** registrar em `documentation/plans/decisoes.md` com motivo; nunca apagar.
- **Reorder:** só se as dependências permitirem; revalidar lanes.
- **Abandon:** ADR com motivo + impacto nas etapas seguintes.

---

## 10. Próxima ação imediata

1. **Desbloquear infraestrutura:** Docker/Postgres/Redis, projeto Firebase (`google-services.json`, `GoogleService-Info.plist`, Admin SDK, GCS com CORS) e chaves `OPENAI_API_KEY`/`FAL_API_KEY`. Sem isso, E5 roda com mock em dev e falha 503 em produção.
2. **Fechar D5/D11 (pagamentos e preços)** e executar **E7** — créditos avulsos e assinaturas (30 / 300 / 1.000 / 3.000).
3. **E6** (efeitos/áudio/avatares atrás de flags) e **E8** (painel admin), depois **E9** (CI/CD, deploy, LGPD, E2E).
4. Validar iOS em runner **macOS** + TestFlight — impossível no Windows.

> Granularidade: 10 etapas, 3 lanes paralelos a partir de E3. E0–E5 concluídas; primeira entrega equilibrada entregue na **E5**.

---

### Registro de revisão

Plano revisado adversarialmente em 2026-11-17. Corrigidos 15 achados: dependências E2/E3, viabilidade iOS no Windows, ambiguidade da aba "Imagens", coerência do princípio mock, provisionamento Firebase/GCS, regeneração do OpenAPI por etapa, LGPD vs ledger, reconciliação antecipada, comandos PowerShell, fatiamento de E1/E8/E9, timeout de imagem, segurança de webhooks/upload, preços dos planos, `fcm_token`/FCM e critérios verificáveis.

**v1.2 (2026-11-18):** E5 marcada como concluída. Parâmetros de vídeo ajustados para duração/resolução do Kling (o brief original previa proporção); notificação push real postergada até Firebase, com abstração no-op já injetada; critérios de MVP-0/MVP-1 atualizados; verificação local registrada com 114 testes backend, 65 testes mobile e APK debug gerado fora do OneDrive.
