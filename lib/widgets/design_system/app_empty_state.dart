import 'package:flutter/material.dart';

import 'app_icons.dart';
import 'app_spacing.dart';

/// État vide standard du Design System ArgEnPo.
///
/// À utiliser lorsqu'une liste ou une section ne contient aucun élément.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.title,
    super.key,
    this.message,
    this.icon = AppIcons.empty,
    this.action,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 420,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 56,
                color: colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              if (message != null && message!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: AppSpacing.lg),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}