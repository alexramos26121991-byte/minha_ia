import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_card.dart';
import '../../widgets/credit_badge.dart';

/// Tela 6 — Perfil e planos.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: AppColors.action,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, size: 42, color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text('Bem-vindo!', style: AppTypography.title),
                const SizedBox(height: 4),
                Text('Plano Gratuito', style: AppTypography.caption),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            gradient: AppColors.action,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CRÉDITOS DISPONÍVEIS', style: AppTypography.caption),
                      const SizedBox(height: AppSpacing.sm),
                      const Text('30',
                          style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ],
                  ),
                ),
                const Icon(Icons.bolt, size: 40, color: Colors.white24),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            onTap: () => context.go('/perfil/planos'),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium_outlined,
                    color: AppColors.glow, size: 22),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Assinaturas e planos', style: AppTypography.subtitle),
                      const SizedBox(height: 2),
                      Text('Veja os planos e compre créditos', style: AppTypography.caption),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Row(
              children: [
                const Icon(Icons.settings_outlined, color: AppColors.glow, size: 22),
                const SizedBox(width: AppSpacing.md),
                Text('Configurações', style: AppTypography.subtitle),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Row(
              children: [
                const Icon(Icons.help_outline, color: AppColors.glow, size: 22),
                const SizedBox(width: AppSpacing.md),
                Text('Suporte', style: AppTypography.subtitle),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(child: CreditBadge(amount: 30)),
        ],
      ),
    );
  }
}
