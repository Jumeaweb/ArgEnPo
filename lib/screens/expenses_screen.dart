import 'package:flutter/material.dart';

import '../theme/theme.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

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
            Icon(Icons.receipt_long, size: 28),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Dépenses', style: AppTextStyles.appBarTitle),
                Text('Toutes mes dépenses', style: AppTextStyles.appBarSubtitle),
              ],
            ),
          ],
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'La vue d\'ensemble des dépenses arrivera dans une prochaine '
            'version. En attendant, retrouvez les dépenses dans chaque groupe.',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle,
          ),
        ),
      ),
    );
  }
}
