import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth/auth_locator.dart';
import '../../services/auth/auth_repository.dart';
import '../../services/generation/generation_controller.dart';
import '../../services/generation/generation_locator.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_card.dart';
import '../../widgets/credit_badge.dart';

/// Tela 6 — Perfil e planos.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({this.auth, this.controller, super.key});

  /// Injeta repositórios (testes). Por padrão usa as instâncias globais.
  final AuthRepository? auth;
  final GenerationController? controller;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthRepository _auth;
  late final GenerationController _controller;

  @override
  void initState() {
    super.initState();
    _auth = widget.auth ?? authRepository;
    _controller = widget.controller ?? generationController;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.load();
    });
  }

  static const Map<String, String> _planNames = <String, String>{
    'gratuito': 'Gratuito',
    'basico': 'Básico',
    'pro': 'Pro',
    'premium': 'Premium',
  };

  String _planLabel(String? slug) {
    if (slug == null) return 'Plano Gratuito';
    return 'Plano ${_planNames[slug] ?? slug}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _auth,
      builder: (context, _) {
        final user = _auth.user;
        return ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final available = _controller.availableCredits;
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
                        Semantics(
                          header: true,
                          child: Text(user?.greeting ?? 'Bem-vindo!', style: AppTypography.title),
                        ),
                        const SizedBox(height: 4),
                        if (user?.email != null)
                          Text(user!.email!, style: AppTypography.caption),
                        const SizedBox(height: 4),
                        Text(_planLabel(user?.planSlug), style: AppTypography.caption),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Semantics(
                    label: '${available ?? 0} créditos disponíveis',
                    child: AppCard(
                      gradient: AppColors.action,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('CRÉDITOS DISPONÍVEIS', style: AppTypography.caption),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  '${available ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.bolt, size: 40, color: Colors.white24),
                        ],
                      ),
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
                  Center(child: CreditBadge(amount: available ?? 0)),
                  const SizedBox(height: AppSpacing.xl),
                  OutlinedButton.icon(
                    onPressed: () => _auth.signOut(),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sair'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
