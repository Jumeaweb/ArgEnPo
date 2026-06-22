import 'package:flutter/material.dart';
import '../theme/theme.dart';

class AppSectionTitle extends StatelessWidget {
  final String text;

  const AppSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8,
        bottom: 10,
      ),
      child: Text(
        text,
        style: AppTextStyles.sectionTitle,
      ),
    );
  }
}