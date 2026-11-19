import 'package:flutter/material.dart';

import '../theme/theme.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        toolbarHeight: 72,
        title: const Row(
          children: [
            Icon(Icons.bar_chart, size: 28),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Statistiques', style: AppTextStyles.appBarTitle),
                Text('Analyse des dépenses', style: AppTextStyles.appBarSubtitle),
              ],
            ),
          ],
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Les statistiques de dépenses arriveront dans une prochaine '
            'version.',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle,
          ),
        ),
      ),
    );
  }
}
