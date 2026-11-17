# MINHA IA — Product Requirements Document (PRD)

> Versão 1.0 · 2026-11-17 · Consolidado a partir da especificação do produto.
> Decisões técnicas e valores estão nos ADRs em `documentation/adr/`.

## 1. Propósito

Plataforma mobile de criação de imagens e vídeos com IA. O usuário transforma texto ou foto em conteúdo visual, paga com créditos e acompanha tudo em uma galeria.

## 2. Identidade visual

- Nome: **MINHA IA**
- Tagline: **SUA IMAGINAÇÃO, SEM LIMITES**
- Mensagem: "Transforme suas ideias em realidade. Crie vídeos incríveis, anime fotografias e transforme seus textos em experiências visuais com inteligência artificial."
- Ações principais: **Criar vídeo** e **Criar imagem**

| Elemento | Cor |
|---|---|
| Fundo | `#10101C` |
| Roxo principal | `#7651D8` |
| Roxo luminoso | `#B69AFF` |
| Cartões | `#1D1B2B` |
| Texto | branco e cinza claro |

Tema escuro, interface futurista, gradientes roxos e cards com profundidade.

## 3. Telas e navegação

### Navegação inferior (5 abas)
`Início` · `Criar` · `Imagens` · `Galeria` · `Perfil`

### Mapeamento das 6 telas principais

| Tela | Conteúdo | Aba |
|---|---|---|
| 1 — Início | Boas-vindas, saldo de créditos, atalhos, novidades e modelos populares | Início |
| 2 — Criar vídeo | Descrição, modelo, duração, proporção, gerar | Criar |
| 3 — Animar foto | Enviar foto, movimento, animação, gerar | Criar |
| 4 — Criar imagem | Prompt, estilos, resolução, formato | Imagens |
| 5 — Minha galeria | Vídeos, imagens, downloads, histórico de projetos | Galeria |
| 6 — Perfil e planos | Login, créditos, assinaturas, configurações, suporte | Perfil |

Telas auxiliares: **Efeitos** (sub-aba de Imagens) e **Planos** (sub-fluxo de Perfil).

> Nota de implementação: "Imagens" é a aba de criação de imagem; na Galeria, o filtro correspondente chama-se "Imagens criadas" para evitar ambiguidade.

## 4. Funcionalidades

| Módulo | Funcionalidade | Entrega |
|---|---|---|
| Vídeo IA | Texto para vídeo | MVP-1 |
| Vídeo IA | Foto animada | MVP-1 |
| Vídeo IA | Imagem para vídeo | MVP-1 |
| Imagem IA | Texto para imagem | MVP-0 |
| Efeitos | Transformações e animações | MVP-1 |
| Personagens | Avatares e sincronização labial | MVP-1 (flag) |
| Áudio | Voz, música e efeitos sonoros | MVP-1 |
| Galeria | Histórico e downloads | MVP-0 |
| Créditos | Consumo por geração | MVP-0 |
| Assinaturas | Planos pagos | MVP-1 |
| Administração | Gestão da plataforma | MVP-1 |

Funcões dependentes de contratação de modelos (avatares, áudio, efeitos avançados) ficam atrás de feature flags e aparecem como "em breve" quando indisponíveis.

## 5. Arquitetura

- **Mobile:** Flutter, Android e iOS
- **Backend:** Python / FastAPI — autenticação, pedidos, créditos, processamento
- **APIs de IA:** imagem, vídeo e áudio (abstraídas por provedor)
- **Firebase:** login, FCM e dados leves
- **Cloud Storage:** fotos e vídeos
- **Pagamentos:** créditos e assinaturas (Stripe + Mercado Pago/Pix)
- **Admin:** Next.js

Estrutura de pastas:

```
minha_ia/
├── mobile/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   │   ├── home/
│   │   │   ├── video/
│   │   │   ├── image/
│   │   │   ├── effects/
│   │   │   ├── gallery/
│   │   │   ├── profile/
│   │   │   └── subscription/
│   │   ├── widgets/
│   │   ├── services/
│   │   └── theme/
│   ├── assets/
│   └── pubspec.yaml
├── backend/
│   ├── main.py
│   ├── app/
│   │   ├── users/
│   │   ├── generation/
│   │   ├── payments/
│   │   ├── credits/
│   │   └── admin/
│   └── openapi.yaml
├── admin/
└── documentation/
```

## 6. Painel administrativo

O administrador pode: ver usuários; consultar vídeos e imagens gerados; adicionar/retirar créditos; criar e alterar planos; consultar pagamentos; configurar modelos de IA; acompanhar custos e consumo das APIs; bloquear contas e analisar denúncias.

## 7. Monetização

| Plano | Créditos mensais |
|---|---:|
| Gratuito | 30 |
| Básico | 300 |
| Pro | 1.000 |
| Premium | 3.000 |

Preços e regras: ADR 0004. Custo por operação: ADR 0003.

## 8. Requisitos não funcionais

- Segurança: chaves de API apenas no backend; nenhuma regra de crédito no cliente.
- Confiabilidade: reserva/commit/refund, idempotência e reconciliação de órfãos.
- Performance: geração de vídeo assíncrona com notificação push.
- Acessibilidade: contraste AA, alvos de toque ≥ 44dp, suporte a leitor de tela.
- Compatibilidade: Android e iOS; validação de iOS em CI macOS.
- Privacidade: LGPD (ADR 0007).
- Idioma da interface: português (Brasil).
