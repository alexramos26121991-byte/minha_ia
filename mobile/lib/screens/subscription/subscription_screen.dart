import 'package:material_ui/material_ui.dart';

import '../../l10n/pt_br.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_card.dart';

/// Tela auxiliar — Planos (prévia do catálogo; compra indisponível nesta versão).
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  /// Catálogo ilustrativo: os valores são prévia, não cobrança disponível.
  static const _plans = [
    ('Gratuito', '30 créditos', 0.0, 'ativo', false),
    ('Básico', '300 créditos', 29.90, 'previsto', false),
    ('Pro', '1.000 créditos', 89.90, 'previsto', true),
    ('Premium', '3.000 créditos', 249.90, 'previsto', false),
  ];

  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planos')),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          Text('Prévia dos planos', style: AppTypography.title),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Os planos e valores abaixo são apenas uma prévia do catálogo '
            'previsto. Nenhuma cobrança é feita nesta versão.',
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            container: true,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Planos pagos e pagamentos ainda não estão disponíveis '
                      'nesta versão. Os créditos do plano gratuito já estão '
                      'ativos e podem ser usados normalmente.',
                      style: AppTypography.body,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                    Text(
                      '${formatarReais(plan.$3)} · ${plan.$4}',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
