import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Badge de saldo de créditos.
class CreditBadge extends StatelessWidget {
  const CreditBadge({required this.amount, this.compact = false, super.key});

  final int amount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm + 4 : AppSpacing.md,
        vertical: compact ? AppSpacing.xs + 2 : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.glow.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 14, color: AppColors.glow),
          const SizedBox(width: 6),
          Text(
            '$amount créditos',
            style: AppTypographyBadge.style.copyWith(
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

abstract final class AppTypographyBadge {
  static const TextStyle style = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );
}
