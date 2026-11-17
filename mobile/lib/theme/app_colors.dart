import 'package:material_ui/material_ui.dart';

/// Paleta oficial do MINHA IA (ADR 0001 / PRD).
abstract final class AppColors {
  static const Color background = Color(0xFF10101C);
  static const Color primary = Color(0xFF7651D8);
  static const Color glow = Color(0xFFB69AFF);
  static const Color card = Color(0xFF1D1B2B);
  static const Color cardLight = Color(0xFF262338);
  static const Color text = Colors.white;
  static const Color textMuted = Color(0xFFAAA6BD);
  static const Color success = Color(0xFF4ADE80);
  static const Color error = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFFFC857);

  static const List<Color> heroGradient = <Color>[
    Color(0xFF7651D8),
    Color(0xFF4B2FA0),
    Color(0xFF10101C),
  ];

  static const List<Color> actionGradient = <Color>[
    Color(0xFF8B5CF6),
    Color(0xFF5B3BB5),
  ];

  static LinearGradient get hero => const LinearGradient(
        colors: heroGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get action => const LinearGradient(
        colors: actionGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
