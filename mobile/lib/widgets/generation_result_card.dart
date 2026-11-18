import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../services/generation/generation_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';

/// Resultado de uma geração assíncrona, com progresso e ações contextuais.
class GenerationResultCard extends StatelessWidget {
  const GenerationResultCard({
    required this.item,
    this.onRefresh,
    this.onDownload,
    super.key,
  });

  final GenerationItem item;
  final VoidCallback? onRefresh;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.status) {
      'completed' => Icons.check_circle,
      'failed' => Icons.error_outline,
      _ => Icons.hourglass_top,
    };
    final color = switch (item.status) {
      'completed' => AppColors.success,
      'failed' => AppColors.error,
      _ => AppColors.glow,
    };
    final title = switch (item.status) {
      'completed' => 'Pronto!',
      'failed' => 'Não foi possível concluir',
      _ => 'Seu vídeo está sendo criado',
    };

    return Semantics(
      container: true,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(title, style: AppTypography.subtitle)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              label: item.progressLabel,
              child: LinearProgressIndicator(
                value: item.isCompleted ? 1 : item.progress / 100,
                minHeight: 6,
                color: AppColors.glow,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(item.progressLabel, style: AppTypography.caption),
            const SizedBox(height: AppSpacing.sm),
            Text(item.title, style: AppTypography.body),
            Text(item.subtitle, style: AppTypography.caption),
            if (item.isFailed && item.errorMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(item.errorMessage!, style: AppTypography.caption),
            ],
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (!item.isTerminal && onRefresh != null)
                  OutlinedButton.icon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Atualizar status'),
                  ),
                if (item.isCompleted && item.mediaUrl != null && onDownload != null)
                  OutlinedButton.icon(
                    onPressed: onDownload,
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Baixar'),
                  ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/galeria'),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Ver na galeria'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
