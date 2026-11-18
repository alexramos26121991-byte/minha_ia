import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../services/generation/generation_controller.dart';
import '../../services/generation/generation_downloader.dart';
import '../../services/generation/generation_locator.dart';
import '../../services/generation/generation_models.dart';
import '../../services/generation/image_picker_adapter.dart';
import '../../services/generation/image_source.dart';
import '../../services/notifications/notification_locator.dart';
import '../../services/notifications/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/credit_badge.dart';
import '../../widgets/generation_result_card.dart';
import '../../widgets/generation_thumbnail.dart';
import '../../widgets/insufficient_balance_card.dart';

/// Tela 3 — Animar foto, ligada ao backend da E5.
class AnimatePhotoScreen extends StatefulWidget {
  const AnimatePhotoScreen({
    this.controller,
    this.downloader,
    this.notifications,
    this.imagePicker,
    super.key,
  });

  /// Dependências injetáveis (testes). Padrão: instâncias globais/reais.
  final GenerationController? controller;
  final GenerationDownloader? downloader;
  final NotificationService? notifications;
  final ImagePickerPort? imagePicker;

  @override
  State<AnimatePhotoScreen> createState() => _AnimatePhotoScreenState();
}

class _AnimatePhotoScreenState extends State<AnimatePhotoScreen> {
  final _urlController = TextEditingController();
  late final GenerationController _controller;
  late final GenerationDownloader _downloader;
  late final NotificationService _notifications;
  late final ImagePickerPort _imagePicker;
  StreamSubscription<GenerationNotification>? _subscription;

  String _motion = 'Suave';
  String? _fileName;
  int _pollToken = 0;

  static const _motions = <String>['Suave', 'Dinâmico', 'Cinematográfico'];

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? generationController;
    _downloader = widget.downloader ?? const GenerationDownloader();
    _notifications = widget.notifications ?? notificationService;
    _imagePicker = widget.imagePicker ?? ImagePickerAdapter();
    _subscription = _notifications.generations.listen(_onNotification);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.load();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _pollToken++;
    _urlController.dispose();
    super.dispose();
  }

  void _onNotification(GenerationNotification event) {
    final current = _controller.lastGenerated;
    if (current == null || event.generationId != current.id) return;
    // O push só avisa que algo mudou; o estado final vem sempre do backend.
    unawaited(_controller.pollGeneration(current.id, maxAttempts: 1));
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage();
    if (picked == null || !mounted) return;

    final ok = await _controller.uploadImage(
      picked.bytes,
      fileName: picked.fileName,
      mimeType: picked.mimeType,
    );
    if (!mounted || !ok) return;

    final url = _controller.uploadedImageUrl;
    if (url != null && url.isNotEmpty) {
      _urlController.text = url;
      setState(() => _fileName = picked.fileName);
    }
  }

  Future<void> _submit() async {
    await _controller.animatePhoto(
      imageUrl: _urlController.text,
      motion: _motion,
    );
    final item = _controller.lastGenerated;
    if (item == null || item.isTerminal || !mounted) return;

    final token = ++_pollToken;
    await _controller.pollGeneration(
      item.id,
      interval: const Duration(seconds: 2),
      maxAttempts: 15,
      shouldStop: () => !mounted || token != _pollToken,
    );
  }

  Future<void> _download(GenerationItem item) async {
    try {
      final path = await _downloader.download(item);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vídeo salvo em: $path')),
      );
    } on GenerationDownloadFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final cost = _controller.animatePhotoCost;
        final available = _controller.availableCredits;
        final busy = _controller.generateState == GenerateState.generating ||
            _controller.uploading;
        final url = _urlController.text.trim();
        final item = _controller.lastGenerated;

        return Scaffold(
          appBar: AppBar(title: const Text('Animar foto')),
          body: SingleChildScrollView(
            padding: AppSpacing.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text('Escolha uma fotografia',
                        style: AppTypography.subtitle),
                    const Spacer(),
                    CreditBadge(amount: available ?? 0, compact: true),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Semantics(
                  key: const Key('pick-image'),
                  button: true,
                  label: 'Escolher foto da galeria',
                  child: AppCard(
                    onTap: busy ? null : _pickImage,
                    child: SizedBox(
                      height: 180,
                      child: url.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined,
                                    size: 44,
                                    color: AppColors.glow.withValues(alpha: 0.8)),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  _controller.uploading
                                      ? 'Enviando imagem…'
                                      : 'Toque para escolher da galeria',
                                  style: AppTypography.body,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            )
                          : ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusSm),
                              child: GenerationThumbnail(url: url),
                            ),
                    ),
                  ),
                ),
                if (_fileName != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text('Imagem: $_fileName', style: AppTypography.caption),
                ],
                const SizedBox(height: AppSpacing.lg),
                const Text('Ou use uma URL de imagem',
                    style: AppTypography.subtitle),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _urlController,
                  enabled: !busy,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    hintText: 'https://exemplo.com/minha-foto.jpg',
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const Text('Movimento', style: AppTypography.subtitle),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final value in _motions)
                      ChoiceChip(
                        label: Text(value),
                        selected: _motion == value,
                        onSelected: busy
                            ? null
                            : (_) => setState(() => _motion = value),
                      ),
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
                if (_controller.uploading || _controller.generateState == GenerateState.generating)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: LinearProgressIndicator(minHeight: 3),
                  ),
                AppButton(
                  key: const Key('animate-photo-button'),
                  label: _controller.uploading
                      ? 'Enviando imagem…'
                      : _controller.generateState == GenerateState.generating
                          ? 'Animando…'
                          : 'Animar foto',
                  icon: Icons.animation_outlined,
                  gradient: true,
                  loading: busy,
                  onPressed: busy ? null : _submit,
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
                    item != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  GenerationResultCard(
                    item: item,
                    onRefresh: item.isTerminal
                        ? null
                        : () => unawaited(_controller.pollGeneration(item.id)),
                    onDownload: () => unawaited(_download(item)),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
