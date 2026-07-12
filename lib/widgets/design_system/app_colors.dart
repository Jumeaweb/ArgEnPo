import 'package:flutter/material.dart';

/// Design System - Couleurs métier ArgEnPo.
///
/// Les couleurs générales liées aux états et aux domaines fonctionnels
/// de l'application sont centralisées ici.
///
/// Les couleurs spécifiques à la timeline des activités restent gérées
/// par `activity_theme.dart`.
abstract final class AppColors {
  AppColors._();

  // ==========================================================================
  // Domaines métier
  // ==========================================================================

  static const Color group = Color(0xFF6750A4);
  static const Color member = Color(0xFF386A20);
  static const Color expense = Color(0xFF006A6A);
  static const Color repayment = Color(0xFF8A4F00);
  static const Color invitation = Color(0xFF4F5F9A);
  static const Color notification = Color(0xFF6750A4);
  static const Color statistics = Color(0xFF7D5260);

  // ==========================================================================
  // États
  // ==========================================================================

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFED6C02);
  static const Color error = Color(0xFFBA1A1A);
  static const Color info = Color(0xFF1976D2);
  static const Color pending = Color(0xFF6D5E00);
  static const Color disabled = Color(0xFF79747E);

  // ==========================================================================
  // Soldes et montants
  // ==========================================================================

  static const Color positiveBalance = Color(0xFF2E7D32);
  static const Color negativeBalance = Color(0xFFBA1A1A);
  static const Color neutralBalance = Color(0xFF605D62);

  // ==========================================================================
  // Arrière-plans légers
  // ==========================================================================

  static const Color successContainer = Color(0xFFE8F5E9);
  static const Color warningContainer = Color(0xFFFFF3E0);
  static const Color errorContainer = Color(0xFFFFEDEA);
  static const Color infoContainer = Color(0xFFE3F2FD);
  static const Color pendingContainer = Color(0xFFFFF8D8);

  // ==========================================================================
  // Texte sur arrière-plans légers
  // ==========================================================================

  static const Color onSuccessContainer = Color(0xFF1B5E20);
  static const Color onWarningContainer = Color(0xFF7A2E00);
  static const Color onErrorContainer = Color(0xFF8C1D18);
  static const Color onInfoContainer = Color(0xFF0D47A1);
  static const Color onPendingContainer = Color(0xFF4F4300);
}