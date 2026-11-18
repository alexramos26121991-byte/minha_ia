import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Aviso de saldo insuficiente com atalho para a tela de planos.
class InsufficientBalanceCard extends StatelessWidget {
  const InsufficientBalanceCard({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_outline, color: AppColors.error, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    message,
                    style: AppTypography.body,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: () => context.go('/perfil/planos'),
              icon: const Icon(Icons.workspace_premium_outlined),
              label: const Text('Ver planos e créditos'),
            ),
          ],
        ),
      ),
    );
  }
}
