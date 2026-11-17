import 'package:material_ui/material_ui.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/soon_placeholder.dart';

/// Tela 3 — Animar foto (em breve até a E5).
class AnimatePhotoScreen extends StatelessWidget {
  const AnimatePhotoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Animar foto')),
      body: SingleChildScrollView(
        padding: AppSpacing.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SoonPlaceholder(feature: 'Animação de fotografias'),
            const SizedBox(height: AppSpacing.xl),
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: Theme.of(context).hintColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 46, color: Theme.of(context).hintColor),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Enviar uma fotografia', style: AppTypography.subtitle),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Movimento', style: AppTypography.subtitle),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              children: const [
                Chip(label: Text('Suave')),
                Chip(label: Text('Dinâmico')),
                Chip(label: Text('Cinematográfico')),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const AppButton(label: 'Animar foto', icon: Icons.animation_outlined),
          ],
        ),
      ),
    );
  }
}
