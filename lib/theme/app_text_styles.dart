import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';

class AppTextStyles {
  static const appBarTitle = TextStyle(
  fontSize: AppDimensions.appBarTitleSize,
  fontWeight: FontWeight.bold,
  color: AppColors.textLight,
);

static const title = TextStyle(
  fontSize: AppDimensions.titleSize,
  fontWeight: FontWeight.bold,
  color: AppColors.textPrimary,
);

static const sectionTitle = TextStyle(
  fontSize: AppDimensions.sectionTitleSize,
  fontWeight: FontWeight.bold,
  color: AppColors.textPrimary,
);

static const subtitle = TextStyle(
  fontSize: AppDimensions.subtitleSize,
  color: AppColors.textSecondary,
);

static const small = TextStyle(
  fontSize: AppDimensions.smallSize,
  color: AppColors.textSecondary,
);
static const appBarSubtitle = TextStyle(
  fontSize: 12,
  color: Colors.white70,
);
static const button = TextStyle(
  fontSize: AppDimensions.bodySize,
  fontWeight: FontWeight.bold,
  color: AppColors.textLight,
);
static const amount = TextStyle(
  fontSize: AppDimensions.bodySize,
  fontWeight: FontWeight.bold,
  color: AppColors.success,
);
static const appBarGroupTitle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.bold,
  color: AppColors.textLight,
);
static const summaryAmount = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.bold,
);
/*
  static const appBarTitle = TextStyle(
    fontSize: AppDimensions.appBarTitleSize,
    fontWeight: FontWeight.bold,
    color: AppColors.textLight,
  );

  static const appBarSubtitle = TextStyle(
    fontSize: 12,
    color: Colors.white70,
  );

  static const title = TextStyle(
    fontSize: AppDimensions.titleSize,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const subtitle = TextStyle(
    fontSize: AppDimensions.subtitleSize,
    color: AppColors.textSecondary,
  );

  static const small = TextStyle(
    fontSize: AppDimensions.smallSize,
    color: AppColors.textSecondary,
  );

  static const sectionTitle = TextStyle(
    fontSize: AppDimensions.sectionTitleSize,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const sectionTitleLogin = TextStyle(
    fontSize: AppDimensions.sectionTitleSize,
    fontWeight: FontWeight.bold,
    color: AppColors.textGreen,
  );

  static const amount = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.success,
  );*/
}