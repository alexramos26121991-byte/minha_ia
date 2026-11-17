import 'package:material_ui/material_ui.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_card.dart';
import '../../widgets/soon_placeholder.dart';

/// Tela auxiliar — Efeitos (em breve até a E6).
class EffectsScreen extends StatelessWidget {
  const EffectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Efeitos')),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          const SoonPlaceholder(feature: 'Efeitos e transformações'),
          const SizedBox(height: AppSpacing.xl),
          Text('Catálogo', style: AppTypography.title),
          const SizedBox(height: AppSpacing.md),
          for (final name in ['Transformação', 'Animação', 'Estilo artístico', 'Remoção de fundo'])
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppCard(
                child: Row(
                  children: [
                    const Icon(Icons.auto_fix_high_outlined,
                        color: Color(0xFFB69AFF), size: 22),
                    const SizedBox(width: AppSpacing.md),
                    Text(name, style: AppTypography.subtitle),
                    const Spacer(),
                    const Icon(Icons.lock_outline, size: 14, color: Colors.white38),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
