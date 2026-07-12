import 'package:flutter/material.dart';

import 'app_spacing.dart';

/// Indicateur de chargement standard du Design System ArgEnPo.
///
/// Peut afficher uniquement un indicateur circulaire ou l’accompagner
/// d’un message explicatif.
class AppLoading extends StatelessWidget {
  const AppLoading({
    super.key,
    this.message,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.size = 32,
    this.strokeWidth = 3,
  });

  final String? message;
  final EdgeInsetsGeometry padding;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: padding,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                strokeWidth: strokeWidth,
                color: colorScheme.primary,
              ),
            ),
            if (message != null && message!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}