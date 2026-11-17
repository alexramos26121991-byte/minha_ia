import 'package:material_ui/material_ui.dart';

/// Tokens de espaçamento e raio.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  static const double radiusSm = 12;
  static const double radiusMd = 18;
  static const double radiusLg = 24;
  static const double radiusPill = 999;

  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: lg, vertical: md);
  static const EdgeInsets card = EdgeInsets.all(lg);
}
