# MINHA IA — Arquitetura

> Versão 1.0 · 2026-11-17

## 1. Diagrama de containers (C4 nível 2)

```mermaid
C4Context
    title MINHA IA — Containers

    Person(user, "Usuário", "Cria imagens e vídeos com IA")

    Container(app, "App Flutter", "Dart", "Android/iOS. UI, navegação, chamadas à API")
    Container(admin, "Painel Admin", "Next.js", "Operação da plataforma")
    Container(api, "API", "FastAPI", "Auth, créditos, geração, pagamentos, admin")
    Container(worker, "Worker", "Celery", "Jobs de geração de vídeo e áudio")
    Container(db, "PostgreSQL", "SQL", "Fonte da verdade: users, ledger, generations, payments")
    Container(redis, "Redis", "Fila", "Fila de jobs e cache")
    Container(storage, "Cloud Storage", "GCS", "Imagens e vídeos gerados")
    Container(firebase, "Firebase", "Auth/FCM", "Login e notificações push")
    Container(ai, "Provedores de IA", "HTTP", "Imagem, vídeo, áudio, avatar")

    Rel(user, app, "Usa")
    Rel(user, admin, "Administra")
    Rel(app, api, "HTTPS / OpenAPI")
    Rel(admin, api, "HTTPS / escopo admin")
    Rel(api, db, "SQL")
    Rel(api, redis, "Enfileira")
    Rel(worker, redis, "Consome")
    Rel(worker, db, "Atualiza")
    Rel(worker, storage, "Salva mídia")
    Rel(worker, ai, "Gera")
    Rel(api, firebase, "Valida token / envia push")
    Rel(app, storage, "Upload via URL assinada")
```

## 2. Fluxo de geração de imagem (MVP-0)

```mermaid
sequenceDiagram
    participant U as Usuário
    participant A as App
    participant API as FastAPI
    participant L as Ledger
    participant IA as Provedor de imagem
    participant S as Storage

    U->>A: prompt + estilo + tamanho
    A->>API: POST /generations/image (Idempotency-Key)
    API->>L: reserve(5 créditos)
    L-->>API: reservation_id
    API->>IA: generate()
    IA-->>API: imagem (ou timeout/erro)
    alt sucesso
        API->>S: salvar arquivo
        API->>L: commit(reservation)
        API-->>A: 201 + generation
    else falha / timeout
        API->>L: refund(reservation)
        API-->>A: 4xx/5xx + mensagem amigável
    end
    A->>API: GET /generations
    API-->>A: item aparece na Galeria
```

## 3. Fluxo de geração de vídeo (MVP-1)

```mermaid
sequenceDiagram
    participant A as App
    participant API as FastAPI
    participant R as Redis
    participant W as Worker
    participant IA as Provedor de vídeo
    participant S as Storage
    participant F as FCM

    A->>API: POST /generations/video
    API->>R: enfileira job
    API-->>A: 202 + job_id
    W->>R: consome job
    W->>IA: generate (webhook assinado + polling)
    IA-->>W: vídeo pronto
    W->>S: salvar arquivo
    W->>API: commit créditos + status done
    W->>F: notificar usuário (fcm_token)
    F-->>A: push "Seu vídeo está pronto"
```

## 4. Modelo de dados (resumo)

| Tabela | Campos-chave | Observação |
|---|---|---|
| `users` | id, firebase_uid, email, plan_id, fcm_token, status, consent_version | criada na E1c |
| `plans` | id, nome, creditos_mensais, preço, recorrência | seed dos 4 planos |
| `credit_accounts` | user_id, balance | saldo disponível |
| `credit_ledger` | user_id, amount, reason, idempotency_key, balance_after | **append-only** |
| `generations` | user_id, type, provider, status, params, storage_path, cost_credits | histórico |
| `payments` | user_id, provider, external_id, amount, status | nunca apagado |
| `cost_config` | operação, custo_estimado, creditos, enabled | tabela mestre ADR 0003 |
| `webhook_events` | provider, event_id, payload | unique(provider,event_id) |
| `admin_audit_log` | admin_id, action, target, timestamp | imutável |

## 5. Regras de segurança

1. App → API com token Firebase; API valida no middleware.
2. App nunca recebe chaves de provedores de IA nem de pagamento.
3. Upload de mídia por URL assinada, com MIME/tamanho validados no backend.
4. Webhooks exigem assinatura válida + deduplicação.
5. Ledger e pagamentos são append-only; anonimização LGPD preserva valores.
6. Toda rota administrativa exige papel `admin`/`super_admin` e gera log.
