import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_icons.dart';
import 'app_radius.dart';
import 'app_spacing.dart';

/// Puce d'état standard du Design System ArgEnPo.
///
/// Utilisable pour les invitations, soldes, dépenses, notifications
/// et tous les états métier de l'application.
class AppStatusChip extends StatelessWidget {
  const AppStatusChip({
    required this.label,
    super.key,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.compact = false,
  });

  const AppStatusChip.success({
    required this.label,
    super.key,
    this.icon = AppIcons.success,
    this.backgroundColor = AppColors.successContainer,
    this.foregroundColor = AppColors.onSuccessContainer,
    this.borderColor = AppColors.success,
    this.compact = false,
  });

  const AppStatusChip.warning({
    required this.label,
    super.key,
    this.icon = AppIcons.warning,
    this.backgroundColor = AppColors.warningContainer,
    this.foregroundColor = AppColors.onWarningContainer,
    this.borderColor = AppColors.warning,
    this.compact = false,
  });

  const AppStatusChip.error({
    required this.label,
    super.key,
    this.icon = AppIcons.error,
    this.backgroundColor = AppColors.errorContainer,
    this.foregroundColor = AppColors.onErrorContainer,
    this.borderColor = AppColors.error,
    this.compact = false,
  });

  const AppStatusChip.info({
    required this.label,
    super.key,
    this.icon = AppIcons.info,
    this.backgroundColor = AppColors.infoContainer,
    this.foregroundColor = AppColors.onInfoContainer,
    this.borderColor = AppColors.info,
    this.compact = false,
  });

  const AppStatusChip.pending({
    required this.label,
    super.key,
    this.icon = AppIcons.pending,
    this.backgroundColor = AppColors.pendingContainer,
    this.foregroundColor = AppColors.onPendingContainer,
    this.borderColor = AppColors.pending,
    this.compact = false,
  });

  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final effectiveBackgroundColor =
        backgroundColor ?? colorScheme.surfaceContainerHighest;

    final effectiveForegroundColor =
        foregroundColor ?? colorScheme.onSurfaceVariant;

    final effectiveBorderColor =
        borderColor ?? colorScheme.outlineVariant;

    final horizontalPadding =
        compact ? AppSpacing.sm : AppSpacing.md;

    final verticalPadding =
        compact ? AppSpacing.xs : AppSpacing.sm;

    final iconSize = compact ? 14.0 : 16.0;

    return Semantics(
      label: label,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: effectiveBackgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: effectiveBorderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: iconSize,
                color: effectiveForegroundColor,
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: effectiveForegroundColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}