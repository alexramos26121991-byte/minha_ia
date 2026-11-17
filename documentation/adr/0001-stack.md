# ADR 0001 — Stack tecnológica

- Status: **Aceito (provisório — aguardando confirmação do usuário)**
- Data: 2026-11-17

## Contexto
Projeto greenfield: app mobile Android/iOS, backend para lógica de créditos e integrações, painel administrativo. Ambiente de desenvolvimento atual é Windows; iOS só pode ser validado em macOS/CI.

## Decisão
| Camada | Tecnologia |
|---|---|
| Mobile | Flutter (Dart), `go_router`, `flutter_riverpod`, `dio` |
| Backend | Python 3.11+, FastAPI, SQLAlchemy, Alembic, PostgreSQL, Celery + Redis |
| Auth / Push / Storage | Firebase Auth + FCM Admin SDK + Google Cloud Storage |
| Admin web | Next.js (React/TypeScript) |
| Infra | Docker Compose local; Cloud Run/Fly.io + Redis gerenciado em produção |
| CI/CD | GitHub Actions, Fastlane (iOS em runner macOS) |

## Alternativas consideradas
- React Native — descartado por ecossistema visual e single codebase mais maduro para este caso.
- Supabase no lugar de Firebase — descartado porque a especificação pede Firebase.
- Flutter Web para o admin — descartado: tabelas e gráficos são mais lentos de construir que em Next.js.

## Consequências
- Backend é a fonte da verdade; Firebase fica com Auth, FCM e storage de mídia.
- Nenhuma chave de API é enviada ao app.
- Requer JDK 17 no ambiente para gerar o cliente Dart do OpenAPI.
- Validação de iOS depende de runner macOS; no Windows verificamos APK, backend e admin.
