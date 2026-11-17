import 'package:flutter/material.dart';

import '../theme/theme.dart';

class AppBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? backgroundColor;

  const AppBadge({
    super.key,
    required this.text,
    this.icon,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.secondary,
        borderRadius: BorderRadius.circular(AppDimensions.badgeRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: AppColors.textLight,
              size: AppDimensions.smallSize,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: AppTextStyles.badge,
          ),
        ],
      ),
    );
  }
}
