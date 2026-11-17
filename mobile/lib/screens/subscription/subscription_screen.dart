import 'package:material_ui/material_ui.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

/// Tela auxiliar — Planos.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  static const _plans = [
    ('Gratuito', '30 créditos', 'R\$ 0,00', false),
    ('Básico', '300 créditos', 'R\$ 29,90', false),
    ('Pro', '1.000 créditos', 'R\$ 89,90', true),
    ('Premium', '3.000 créditos', 'R\$ 249,90', false),
  ];

  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planos')),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          Text('Escolha o plano ideal', style: AppTypography.title),
          const SizedBox(height: AppSpacing.sm),
          Text('Mais créditos para criar sem limites.', style: AppTypography.body),
          const SizedBox(height: AppSpacing.xl),
          for (final plan in _plans)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppCard(
                onTap: () => setState(() => _selected = _plans.indexOf(plan)),
                gradient: _plans.indexOf(plan) == _selected ? AppColors.action : null,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(plan.$1, style: AppTypography.subtitle),
                          const SizedBox(height: 4),
                          Text(plan.$2, style: AppTypography.caption),
                        ],
                      ),
                    ),
                    Text(plan.$3, style: AppTypography.subtitle),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Continuar',
            icon: Icons.arrow_forward,
            gradient: true,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pagamentos disponíveis na próxima versão.'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
