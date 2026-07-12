import 'package:flutter/material.dart';

/// Design System - Icônes
///
/// Toutes les icônes utilisées dans ArgEnPo doivent être référencées ici.
/// Cela garantit une interface cohérente et facilite les évolutions futures.
abstract final class AppIcons {
  AppIcons._();

  // ==========================================================================
  // Navigation
  // ==========================================================================

  static const home = Icons.home_rounded;
  static const groups = Icons.groups_rounded;
  static const notifications = Icons.notifications_rounded;
  static const profile = Icons.account_circle_rounded;
  static const settings = Icons.settings_rounded;
  static const statistics = Icons.bar_chart_rounded;

  // ==========================================================================
  // Groupes
  // ==========================================================================

  static const group = Icons.group_rounded;
  static const addGroup = Icons.group_add_rounded;
  static const member = Icons.person_rounded;
  static const addMember = Icons.person_add_alt_1_rounded;
  static const owner = Icons.workspace_premium_rounded;
  static const admin = Icons.admin_panel_settings_rounded;

  // ==========================================================================
  // Dépenses
  // ==========================================================================

  static const expense = Icons.receipt_long_rounded;
  static const addExpense = Icons.add_card_rounded;
  static const repayment = Icons.swap_horiz_rounded;
  static const balance = Icons.account_balance_wallet_rounded;
  static const euro = Icons.euro_rounded;

  // ==========================================================================
  // Activités
  // ==========================================================================

  static const activity = Icons.history_rounded;
  static const timeline = Icons.timeline_rounded;

  // ==========================================================================
  // Invitations
  // ==========================================================================

  static const invitation = Icons.mail_outline_rounded;
  static const accepted = Icons.check_circle_rounded;
  static const declined = Icons.cancel_rounded;
  static const pending = Icons.schedule_rounded;

  // ==========================================================================
  // États
  // ==========================================================================

  static const success = Icons.check_circle_rounded;
  static const warning = Icons.warning_amber_rounded;
  static const error = Icons.error_rounded;
  static const info = Icons.info_rounded;

  // ==========================================================================
  // Actions
  // ==========================================================================

  static const add = Icons.add_rounded;
  static const edit = Icons.edit_rounded;
  static const delete = Icons.delete_rounded;
  static const close = Icons.close_rounded;
  static const search = Icons.search_rounded;
  static const filter = Icons.filter_list_rounded;
  static const refresh = Icons.refresh_rounded;
  static const share = Icons.share_rounded;
  static const more = Icons.more_vert_rounded;
  static const back = Icons.arrow_back_rounded;
  static const forward = Icons.arrow_forward_rounded;
  static const logout = Icons.logout_rounded;

  // ==========================================================================
  // Divers
  // ==========================================================================

  static const calendar = Icons.calendar_today_rounded;
  static const clock = Icons.schedule_rounded;
  static const person = Icons.person_outline_rounded;
  static const email = Icons.email_outlined;
  static const phone = Icons.phone_rounded;
  static const camera = Icons.photo_camera_rounded;
  static const image = Icons.image_rounded;
  static const empty = Icons.inbox_rounded;
}