/// Design System - Durées des animations
abstract final class AppDuration {
  AppDuration._();

  static const Duration instant = Duration(milliseconds: 0);

  static const Duration fast = Duration(milliseconds: 120);

  static const Duration normal = Duration(milliseconds: 180);

  static const Duration slow = Duration(milliseconds: 300);
}