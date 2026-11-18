# Registro de decisões do plano

Este arquivo registra mudanças de escopo, etapas puladas e decisões provisórias. Nada é apagado — apenas marcado com o novo status.

| Data | Item | Status | Motivo |
|---|---|---|---|
| 2026-11-17 | Plano de execução v1.0 | **Substituído pela v1.1** | 15 achados da revisão adversarial corrigidos |
| 2026-11-17 | ADRs 0001–0004, 0007 | **Provisórios** | Usuário ainda não confirmou provedores, preços e prazos de retenção |
| 2026-11-17 | Git não estava instalado | **Resolvido** | Instalado via `winget install Git.Git` (v2.56.0.4) |
| 2026-11-17 | Docker Desktop na E1c | **Bloqueado localmente** | WSL não instalado e sessão sem elevação: o engine Linux não sobe. `docker compose up` não executado; validação feita com `TestClient` + SQLite em memória (`/health` 200, `/plans` com 4 planos) e migration via Alembic em modo offline. |
| 2026-11-17 | Firebase/GCS na E1c | **Pendente do usuário** | Faltam projeto Firebase, `google-services.json`, `GoogleService-Info.plist`, service account do Admin SDK e bucket GCS com CORS. Placeholders já presentes em `.env.example`. |
| 2026-11-17 | Firebase Auth na E2 | **Abstraído; integração real pendente** | Criado `TokenVerifier` no backend (`auth_provider=dev\|firebase`) e `AuthProvider` no app (`DevAuthProvider`). O modo `dev` aceita tokens `dev:<email>:<nonce>` e é **recusado** quando `app_env=production`; o modo `firebase` usa `firebase-admin` com import lazy. Isso permite E2E e testes sem credenciais sem abrir brecha em produção. |
| 2026-11-17 | Porta de sessão no app (E2) | **Provisória** | `sessionSync` registra `consent_version=lgpd-2026-11` e `fcm_token` no `POST /auth/session`. Versão de consentimento e retenção LGPD seguem pendentes de confirmação (ADRs 0003/0007). |
| 2026-11-17 | Validação da E2 | **Local green** | Backend: 7 testes (`pytest`), Alembic head `0002_user_display_name`; contrato: Redocly válido (19 paths) e cliente Dart regerado; mobile: `flutter analyze` limpo, 16 testes, `flutter build apk --debug` OK. Permanece bloqueado: Docker/Postgres, Firebase/GCS e validação iOS (Windows). |
