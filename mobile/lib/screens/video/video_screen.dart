import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/soon_placeholder.dart';

/// Tela 2 — Criar vídeo (em breve até a E5).
class VideoScreen extends StatelessWidget {
  const VideoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar vídeo')),
      body: SingleChildScrollView(
        padding: AppSpacing.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SoonPlaceholder(feature: 'Geração de vídeo por texto'),
            const SizedBox(height: AppSpacing.xl),
            const Text('Descreva seu vídeo', style: AppTypography.subtitle),
            const SizedBox(height: AppSpacing.md),
            const TextField(
              maxLines: 4,
              enabled: false,
              decoration: InputDecoration(
                hintText: 'Ex.: um dragão voando sobre uma cidade futurista...',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Modelo de IA', style: AppTypography.subtitle),
            const SizedBox(height: AppSpacing.md),
            _DisabledField(icon: Icons.smart_toy_outlined, label: 'Modelo padrão'),
            const SizedBox(height: AppSpacing.lg),
            const Text('Duração e proporção', style: AppTypography.subtitle),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: const [
                Expanded(child: _DisabledField(icon: Icons.timer_outlined, label: '5 segundos')),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: _DisabledField(icon: Icons.aspect_ratio, label: '16:9')),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const AppButton(label: 'Gerar vídeo', icon: Icons.movie_creation_outlined),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              onTap: () => context.go('/criar/animar-foto'),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(Icons.animation_outlined,
                        color: AppColors.glow, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Animar foto', style: AppTypography.subtitle),
                        const SizedBox(height: 2),
                        Text(
                          'Dê movimento a uma fotografia',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 14, color: Colors.white38),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisabledField extends StatelessWidget {
  const _DisabledField({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.55,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).hintColor),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: AppTypography.body),
          ],
        ),
      ),
    );
  }
}
