# ADR 0006 — Painel administrativo web

- Status: **Aceito**
- Data: 2026-11-17

## Contexto
O administrador precisa de tabelas densas, filtros e gráficos de receita/custo — tarefas ruins de fazer em Flutter.

## Decisão
Painel em **Next.js**, hospedado separadamente do app e do backend, com papéis `admin` e `super_admin`.

Áreas obrigatórias:
1. Dashboard (usuários, gerações, receita, custo de APIs, margem)
2. Usuários (buscar, bloquear, ajustar créditos)
3. Gerações (filtrar, visualizar, reprocessar, estornar)
4. Planos (criar/editar)
5. Pagamentos (listar, reembolsar)
6. Modelos de IA (configurar provedor, custo, habilitar)
7. Custos e consumo (gráficos por provedor/usuário/período)
8. Denúncias (fila, resolver, banir)

Toda ação grava em `admin_audit_log` imutável.

## Alternativas consideradas
- Flutter Web — rejeitado por produtividade em tabelas/gráficos.
- Usar Firebase Console como admin — insuficiente para créditos e auditoria.

## Consequências
- Admin consome a mesma API do app, com escopo `admin`.
- Ajuste de créditos feito no admin aparece no ledger do usuário.
