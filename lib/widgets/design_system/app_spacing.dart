import 'package:flutter/widgets.dart';

/// Design System - Espacements
///
/// Toutes les marges et espacements de l'application doivent
/// utiliser ces constantes afin d'assurer une interface cohérente.
abstract final class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const EdgeInsets page = EdgeInsets.all(md);

  static const EdgeInsets card = EdgeInsets.all(md);

  static const EdgeInsets listItem =
      EdgeInsets.symmetric(horizontal: md, vertical: sm);

  static const EdgeInsets dialog = EdgeInsets.all(lg);
}