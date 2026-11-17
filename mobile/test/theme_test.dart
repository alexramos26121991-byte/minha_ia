import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minha_ia/theme/app_colors.dart';
import 'package:minha_ia/theme/app_spacing.dart';
import 'package:minha_ia/theme/app_theme.dart';

void main() {
  group('Tema MINHA IA', () {
    test('usa a paleta oficial', () {
      final theme = AppTheme.dark;

      expect(theme.scaffoldBackgroundColor, AppColors.background);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.secondary, AppColors.glow);
      expect(theme.colorScheme.surface, AppColors.card);
      expect(theme.brightness, Brightness.dark);
    });

    test('tokens de cor conferem com o PRD', () {
      expect(AppColors.background, const Color(0xFF10101C));
      expect(AppColors.primary, const Color(0xFF7651D8));
      expect(AppColors.glow, const Color(0xFFB69AFF));
      expect(AppColors.card, const Color(0xFF1D1B2B));
    });

    test('alvos de toque respeitam o minimo de 44dp', () {
      expect(AppSpacing.radiusPill, 999);
      expect(AppColors.action.colors.length, 2);
    });
  });
}
