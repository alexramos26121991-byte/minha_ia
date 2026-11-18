import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../services/generation/generation_controller.dart';
import '../../services/generation/generation_locator.dart';
import '../../services/generation/generation_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/credit_badge.dart';
import '../../widgets/generation_thumbnail.dart';
import '../../widgets/insufficient_balance_card.dart';

/// Tela 4 — Criar imagem, ligada ao backend da E4.
class ImageScreen extends StatefulWidget {
  const ImageScreen({this.controller, super.key});

  /// Injeta um controlador (testes). Por padrão usa a instância global.
  final GenerationController? controller;

  @override
  State<ImageScreen> createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen> {
  final _promptController = TextEditingController();
  late final GenerationController _controller;

  String _style = 'Realista';
  String _size = '1024 × 1024';

  static const _styles = ['Realista', 'Anime', '3D', 'Pintura', 'Cinematográfico'];
  static const _sizes = ['1024 × 1024', '1536 × 1024'];

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? generationController;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.load();
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await _controller.generateImage(
      prompt: _promptController.text,
      style: _style.toLowerCase(),
      size: _size.replaceAll(' × ', 'x'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final cost = _controller.imageCost;
        final available = _controller.availableCredits;
        final generating = _controller.generateState == GenerateState.generating;

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
                    CreditBadge(amount: available ?? 0, compact: true),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _promptController,
                  maxLines: 4,
                  enabled: !generating,
                  decoration: const InputDecoration(
                    hintText: 'Ex.: um gato astronauta em uma galáxia colorida...',
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
                        onSelected: generating
                            ? null
                            : (_) => setState(() => _style = style),
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
                          onSelected: generating
                              ? null
                              : (_) => setState(() => _size = size),
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
                      const Icon(Icons.auto_awesome,
                          color: AppColors.glow, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          cost > 0
                              ? 'Custo: $cost créditos · saldo disponível: ${available ?? 0}'
                              : 'Consultando o custo no servidor…',
                          style: AppTypography.body,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (generating)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: LinearProgressIndicator(minHeight: 3),
                  ),
                AppButton(
                  label: generating ? 'Gerando imagem…' : 'Gerar imagem',
                  icon: Icons.auto_awesome,
                  gradient: true,
                  loading: generating,
                  onPressed: generating ? null : _submit,
                ),
                if (_controller.insufficientBalance &&
                    _controller.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  InsufficientBalanceCard(message: _controller.errorMessage!),
                ] else if (_controller.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Semantics(
                    container: true,
                    child: AppCard(
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(_controller.errorMessage!,
                                style: AppTypography.body),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (_controller.generateState == GenerateState.success &&
                    _controller.lastGenerated != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _SuccessCard(item: _controller.lastGenerated!),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.item});

  final GenerationItem item;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text('Imagem criada!', style: AppTypography.subtitle),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: GenerationThumbnail(url: item.mediaUrl),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(item.title, style: AppTypography.body),
            Text(item.subtitle, style: AppTypography.caption),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/galeria'),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Ver na galeria'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
