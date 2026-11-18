# Registro de decisões do plano

Este arquivo registra mudanças de escopo, etapas puladas e decisões provisórias. Nada é apagado — apenas marcado com o novo status.

| Data | Item | Status | Motivo |
|---|---|---|---|
| 2026-11-17 | Plano de execução v1.0 | **Substituído pela v1.1** | 15 achados da revisão adversarial corrigidos |
| 2026-11-17 | ADRs 0001–0004, 0007 | **Provisórios** | Usuário ainda não confirmou provedores, preços e prazos de retenção |
| 2026-11-17 | Git não estava instalado | **Resolvido** | Instalado via `winget install Git.Git` (v2.56.0.4) |
| 2026-11-17 | Docker Desktop na E1c | **Bloqueado localmente** | WSL não instalado e sessão sem elevação: o engine Linux não sobe. `docker compose up` não executado; validação feita com `TestClient` + SQLite em memória (`/health` 200, `/plans` com 4 planos) e migration via Alembic em modo offline. |
| 2026-11-17 | Firebase/GCS na E1c | **Pendente do usuário** | Faltam projeto Firebase, `google-services.json`, `GoogleService-Info.plist`, service account do Admin SDK e bucket GCS com CORS. Placeholders já presentes em `.env.example`. |
