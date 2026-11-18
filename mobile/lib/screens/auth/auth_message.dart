import 'package:material_ui/material_ui.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Mensagem de erro anunciada por leitores de tela.
class AuthMessage extends StatelessWidget {
  const AuthMessage({required this.text, super.key});

  final String? text;

  @override
  Widget build(BuildContext context) {
    final message = text?.trim();
    if (message == null || message.isEmpty) return const SizedBox.shrink();

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTypography.body.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
