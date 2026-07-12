import 'package:flutter/material.dart';

import 'app_duration.dart';
import 'app_radius.dart';
import 'app_shadow.dart';
import 'app_spacing.dart';

/// Carte standard du Design System ArgEnPo.
///
/// Ce composant centralise l’apparence des surfaces de l’application :
/// espacements, rayon, bordure, ombre et interaction tactile.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    super.key,
    this.onTap,
    this.padding = AppSpacing.card,
    this.margin = EdgeInsets.zero,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = AppRadius.lg,
    this.showShadow = true,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final bool showShadow;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final radius = BorderRadius.circular(borderRadius);

    final effectiveBackgroundColor =
        backgroundColor ?? colorScheme.surfaceContainerLow;

    final effectiveBorderColor =
        borderColor ?? colorScheme.outlineVariant.withValues(alpha: 0.55);

    final content = Padding(
      padding: padding,
      child: child,
    );

    return AnimatedContainer(
      duration: AppDuration.normal,
      curve: Curves.easeOutCubic,
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: radius,
        border: Border.all(
          color: effectiveBorderColor,
        ),
        boxShadow: showShadow ? AppShadow.sm : null,
      ),
      clipBehavior: clipBehavior,
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: radius,
                child: content,
              ),
            ),
    );
  }
}