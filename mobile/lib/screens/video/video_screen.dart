import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../services/generation/generation_controller.dart';
import '../../services/generation/generation_downloader.dart';
import '../../services/generation/generation_locator.dart';
import '../../services/generation/generation_models.dart';
import '../../services/notifications/notification_locator.dart';
import '../../services/notifications/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/credit_badge.dart';
import '../../widgets/generation_result_card.dart';
import '../../widgets/insufficient_balance_card.dart';

/// Tela 2 — Criar vídeo por texto, ligada ao backend da E5.
class VideoScreen extends StatefulWidget {
  const VideoScreen({
    this.controller,
    this.downloader,
    this.notifications,
    super.key,
  });

  /// Controlador e downloader injetáveis (testes). Padrão: instâncias globais.
  final GenerationController? controller;
  final GenerationDownloader? downloader;
  final NotificationService? notifications;

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  final _promptController = TextEditingController();
  late final GenerationController _controller;
  late final GenerationDownloader _downloader;
  late final NotificationService _notifications;
  StreamSubscription<GenerationNotification>? _subscription;

  int _duration = 5;
  String _resolution = '720p';
  int _pollToken = 0;

  static const _durations = <int>[5, 10, 15];
  static const _resolutions = <String>['480p', '720p', '1080p'];

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? generationController;
    _downloader = widget.downloader ?? const GenerationDownloader();
    _notifications = widget.notifications ?? notificationService;
    _subscription = _notifications.generations.listen(_onNotification);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.load();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _pollToken++;
    _promptController.dispose();
    super.dispose();
  }

  void _onNotification(GenerationNotification event) {
    final current = _controller.lastGenerated;
    if (current == null || event.generationId != current.id) return;
    // O push só avisa que algo mudou; o estado final vem sempre do backend.
    unawaited(_controller.pollGeneration(current.id, maxAttempts: 1));
  }

  Future<void> _submit() async {
    await _controller.generateVideo(
      prompt: _promptController.text,
      durationSeconds: _duration,
      resolution: _resolution,
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
        final cost = _controller.videoCost;
        final available = _controller.availableCredits;
        final generating = _controller.generateState == GenerateState.generating;
        final item = _controller.lastGenerated;

        return Scaffold(
          appBar: AppBar(title: const Text('Criar vídeo')),
          body: SingleChildScrollView(
            padding: AppSpacing.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text('Descreva seu vídeo', style: AppTypography.subtitle),
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
                    hintText: 'Ex.: um dragão voando sobre uma cidade futurista...',
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const Text('Duração', style: AppTypography.subtitle),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final seconds in _durations)
                      ChoiceChip(
                        label: Text('$seconds s'),
                        selected: _duration == seconds,
                        onSelected: generating
                            ? null
                            : (_) => setState(() => _duration = seconds),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                const Text('Resolução', style: AppTypography.subtitle),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final value in _resolutions)
                      ChoiceChip(
                        label: Text(value),
                        selected: _resolution == value,
                        onSelected: generating
                            ? null
                            : (_) => setState(() => _resolution = value),
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
                if (generating)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: LinearProgressIndicator(minHeight: 3),
                  ),
                AppButton(
                  key: const Key('generate-video-button'),
                  label: generating ? 'Gerando vídeo…' : 'Gerar vídeo',
                  icon: Icons.movie_creation_outlined,
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
                const SizedBox(height: AppSpacing.xl),
                AppCard(
                  onTap: () => context.go('/criar/animar-foto'),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: const Icon(Icons.animation_outlined,
                            color: AppColors.glow, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Animar foto', style: AppTypography.subtitle),
                            const SizedBox(height: 2),
                            Text('Dê movimento a uma fotografia',
                                style: AppTypography.caption),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          size: 14, color: Colors.white38),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
