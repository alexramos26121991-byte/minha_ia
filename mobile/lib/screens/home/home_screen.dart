import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../services/generation/generation_controller.dart';
import '../../services/generation/generation_locator.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_card.dart';
import '../../widgets/gradient_header.dart';

/// Tela 1 — Início.
class HomeScreen extends StatefulWidget {
  const HomeScreen({this.controller, super.key});

  /// Injeta um controlador (testes). Por padrão usa a instância global.
  final GenerationController? controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final GenerationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? generationController;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: GradientHeader(
                  title: 'Sua imaginação,\nsem limites.',
                  subtitle: 'Transforme suas ideias em realidade com inteligência artificial.',
                  trailing: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(Icons.auto_awesome, color: AppColors.glow, size: 22),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _CreditCard(controller: _controller),
                    const SizedBox(height: AppSpacing.xl),
                    Text('O que vamos criar?', style: AppTypography.title),
                    const SizedBox(height: AppSpacing.md),
                    _ActionCard(
                      icon: Icons.movie_creation_outlined,
                      title: 'Criar vídeo',
                      subtitle: 'Transforme um texto em vídeo incrível',
                      onTap: () => context.go('/criar/video'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ActionCard(
                      icon: Icons.add_photo_alternate_outlined,
                      title: 'Criar imagem',
                      subtitle: 'Dê vida às suas ideias em segundos',
                      onTap: () => context.go('/imagens'),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Novidades e modelos populares', style: AppTypography.title),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 132,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _ModelCard(
                            title: 'Imagem IA',
                            subtitle: 'Realista e criativa',
                            icon: Icons.brush_outlined,
                            onTap: () => context.go('/imagens'),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          _ModelCard(
                            title: 'Animar foto',
                            subtitle: 'Transforme uma foto em vídeo',
                            icon: Icons.animation_outlined,
                            onTap: () => context.go('/criar/animar-foto'),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          _ModelCard(
                            title: 'Vídeo IA',
                            subtitle: 'Crie um vídeo a partir de texto',
                            icon: Icons.videocam_outlined,
                            onTap: () => context.go('/criar/video'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CreditCard extends StatelessWidget {
  const _CreditCard({required this.controller});

  final GenerationController controller;

  @override
  Widget build(BuildContext context) {
    final available = controller.availableCredits;
    final loading = controller.loadState == GenerationLoadState.loading ||
        controller.loadState == GenerationLoadState.initial;

    return Semantics(
      label: loading
          ? 'Carregando saldo de créditos'
          : 'Saldo de ${available ?? 0} créditos disponíveis',
      child: AppCard(
        gradient: AppColors.action,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SEU SALDO',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (loading)
                    const SizedBox(
                      width: 90,
                      height: 34,
                      child: LinearProgressIndicator(color: Colors.white),
                    )
                  else
                    Text(
                      '${available ?? 0}',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    controller.errorMessage != null
                        ? 'Não foi possível atualizar o saldo'
                        : 'créditos disponíveis · Plano Gratuito',
                    style: AppTypography.caption.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.bolt, size: 46, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: AppColors.glow, size: 26),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.subtitle),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  const _ModelCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Semantics(
        button: true,
        label: 'Abrir $title: $subtitle',
        child: AppCard(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.glow, size: 28),
              const Spacer(),
              Text(title, style: AppTypography.subtitle),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  subtitle,
                  style: AppTypography.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
