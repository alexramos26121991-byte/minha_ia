import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../services/generation/generation_controller.dart';
import '../../services/generation/generation_downloader.dart';
import '../../services/generation/generation_locator.dart';
import '../../services/generation/generation_models.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/generation_tile.dart';

/// Tela 5 — Minha galeria, alimentada pelo backend da E4.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({
    this.controller,
    this.downloader,
    super.key,
  });

  /// Controlador e downloader injetáveis (testes).
  final GenerationController? controller;
  final GenerationDownloader? downloader;

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  late final GenerationController _controller;
  late final GenerationDownloader _downloader;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? generationController;
    _downloader = widget.downloader ?? const GenerationDownloader();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.load();
    });
  }

  Future<void> _download(GenerationItem item) async {
    try {
      final path = await _downloader.download(item);
      _snack('Imagem salva: $path');
    } on GenerationDownloadFailure catch (error) {
      _snack(error.message);
    }
  }

  Future<void> _share(GenerationItem item) async {
    final url = item.mediaUrl;
    if (url == null || url.isEmpty) {
      _snack('Esta imagem ainda não pode ser compartilhada.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: url));
    _snack('Link copiado. Compartilhe onde quiser.');
  }

  Future<void> _delete(GenerationItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir criação?'),
        content: const Text(
          'A imagem será removida da galeria. Os créditos já usados não são devolvidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final deleted = await _controller.delete(item.id);
    _snack(deleted ? 'Criação excluída.' : 'Não foi possível excluir. Tente novamente.');
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Minha galeria')),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm,
                ),
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: GenerationFilter.values.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final value = GenerationFilter.values[index];
                      return ChoiceChip(
                        label: Text(value.label),
                        selected: _controller.filter == value,
                        onSelected: (_) => _controller.setFilter(value),
                      );
                    },
                  ),
                ),
              ),
              Expanded(child: _body()),
            ],
          ),
        );
      },
    );
  }

  Widget _body() {
    if (_controller.itemsErrorMessage != null) {
      return EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Não foi possível carregar',
        message: _controller.itemsErrorMessage!,
        action: AppButton(
          label: 'Tentar novamente',
          compact: true,
          onPressed: () => _controller.loadItems(),
        ),
      );
    }

    if (_controller.loadState == GenerationLoadState.loading &&
        _controller.items.isEmpty) {
      return Semantics(
        label: 'Carregando galeria',
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_controller.items.isEmpty) {
      return EmptyState(
        icon: _filterIcon(_controller.filter),
        title: 'Nada por aqui ainda',
        message: _emptyMessage(_controller.filter),
        action: AppCard(
          child: Text(
            _controller.filter.hasBackendData
                ? 'Use a aba Imagens ou Criar para começar'
                : 'Esta categoria estará disponível em breve',
            style: AppTypography.caption,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GridView.builder(
        itemCount: _controller.items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
        ),
        itemBuilder: (context, index) {
          final item = _controller.items[index];
          return GenerationTile(
            title: item.title,
            type: item.subtitle,
            imageUrl: item.mediaUrl,
            isVideo: item.isVideo,
            onDownload: item.isFailed ? null : () => _download(item),
            onShare: item.isFailed ? null : () => _share(item),
            onDelete: () => _delete(item),
          );
        },
      ),
    );
  }

  IconData _filterIcon(GenerationFilter filter) => switch (filter) {
        GenerationFilter.videos => Icons.movie_outlined,
        GenerationFilter.images => Icons.image_outlined,
        GenerationFilter.downloads => Icons.download_outlined,
        GenerationFilter.projects => Icons.folder_outlined,
      };

  String _emptyMessage(GenerationFilter filter) => switch (filter) {
        GenerationFilter.videos => 'Seus vídeos gerados aparecerão nesta aba.',
        GenerationFilter.images => 'Crie uma imagem e ela aparecerá aqui.',
        GenerationFilter.downloads => 'Seus downloads serão listados aqui.',
        GenerationFilter.projects => 'Seus projetos serão listados aqui.',
      };
}
