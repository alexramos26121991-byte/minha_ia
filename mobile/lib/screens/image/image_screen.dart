import 'package:material_ui/material_ui.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/credit_badge.dart';

/// Tela 4 — Criar imagem (UI pronta; lógica real na E4).
class ImageScreen extends StatefulWidget {
  const ImageScreen({super.key});

  @override
  State<ImageScreen> createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen> {
  final _promptController = TextEditingController();
  String _style = 'Realista';
  String _size = '1024 × 1024';

  static const _styles = ['Realista', 'Anime', '3D', 'Pintura', 'Cinematográfico'];
  static const _sizes = ['1024 × 1024', '1536 × 1024'];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar imagem')),
      body: SingleChildScrollView(
        padding: AppSpacing.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text('Descreva sua imagem', style: AppTypography.subtitle),
                const Spacer(),
                CreditBadge(amount: 30, compact: true),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _promptController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Ex.: um gato astronauta em uma galaxia colorida...',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text('Estilo', style: AppTypography.subtitle),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final style in _styles)
                  ChoiceChip(
                    label: Text(style),
                    selected: _style == style,
                    onSelected: (_) => setState(() => _style = style),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text('Resolução', style: AppTypography.subtitle),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                for (final size in _sizes) ...[
                  Expanded(
                    child: ChoiceChip(
                      label: Center(child: Text(size)),
                      selected: _size == size,
                      onSelected: (_) => setState(() => _size = size),
                    ),
                  ),
                  if (size != _sizes.last) const SizedBox(width: AppSpacing.sm),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AppCard(
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFFB69AFF), size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Custo estimado: ${_size == '1536 × 1024' ? 9 : 5} créditos',
                    style: AppTypography.body,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const AppButton(label: 'Gerar imagem', icon: Icons.auto_awesome, gradient: true),
          ],
        ),
      ),
    );
  }
}
