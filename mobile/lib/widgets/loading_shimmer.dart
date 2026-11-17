import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Placeholder animado simples para estados de carregamento.
class LoadingShimmer extends StatefulWidget {
  const LoadingShimmer({this.height = 16, this.width = double.infinity, super.key});

  final double height;
  final double width;

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity = 0.35 + 0.25 * _controller.value;
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: AppColors.cardLight.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        );
      },
    );
  }
}
