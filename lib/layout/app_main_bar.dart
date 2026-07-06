import 'package:flutter/material.dart';

import '../theme/theme.dart';

class AppMainBar extends StatelessWidget implements PreferredSizeWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const AppMainBar({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textLight,
      toolbarHeight: 72,
      title: Row(
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.appBarTitle),
              Text(subtitle, style: AppTextStyles.appBarSubtitle),
            ],
          ),
        ],
      ),
    );
  }
}