import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// Thumbnail de uma geração.Funciona com URL absoluta do backend e degrada
/// para um ícone quando a mídia ainda não está disponível.
class GenerationThumbnail extends StatelessWidget {
  const GenerationThumbnail({
    this.url,
    this.isVideo = false,
    super.key,
  });

  final String? url;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    final placeholder = Center(
      child: Icon(
        isVideo ? Icons.play_circle_outline : Icons.image_outlined,
        size: 34,
        color: AppColors.glow.withValues(alpha: 0.7),
      ),
    );

    if (url == null || url!.isEmpty) return placeholder;

    // Placeholder estático: além de leve, evita animação infinita em testes.
    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      placeholder: (context, _) => Center(
        child: Icon(
          isVideo ? Icons.movie_outlined : Icons.image_outlined,
          size: 28,
          color: AppColors.glow.withValues(alpha: 0.35),
        ),
      ),
      errorWidget: (context, _, __) => placeholder,
    );
  }
}
