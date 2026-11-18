import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'generation_thumbnail.dart';

/// Tile de mídia gerada com ações de download, compartilhar e excluir.
class GenerationTile extends StatelessWidget {
  const GenerationTile({
    required this.title,
    required this.type,
    this.imageUrl,
    this.isVideo = false,
    this.onTap,
    this.onDownload,
    this.onShare,
    this.onDelete,
    super.key,
  });

  final String title;
  final String type;
  final String? imageUrl;
  final bool isVideo;
  final VoidCallback? onTap;
  final VoidCallback? onDownload;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: GridTile(
        footer: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, Color(0xEE10101C)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(type, style: AppTypography.caption),
              Row(
                children: [
                  _action(
                    icon: Icons.download_outlined,
                    tooltip: 'Baixar $title',
                    onPressed: onDownload,
                  ),
                  _action(
                    icon: Icons.share_outlined,
                    tooltip: 'Compartilhar $title',
                    onPressed: onShare,
                  ),
                  _action(
                    icon: Icons.delete_outline,
                    tooltip: 'Excluir $title',
                    onPressed: onDelete,
                    color: AppColors.error,
                  ),
                ],
              ),
            ],
          ),
        ),
        child: GestureDetector(
          onTap: onTap,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.cardLight, AppColors.background],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: GenerationThumbnail(url: imageUrl, isVideo: isVideo),
          ),
        ),
      ),
    );
  }

  Widget _action({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    return Semantics(
      button: true,
      label: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 18, color: color ?? AppColors.glow),
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        onPressed: onPressed,
      ),
    );
  }
}
