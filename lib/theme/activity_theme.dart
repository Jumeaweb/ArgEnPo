import 'package:flutter/material.dart';

import '../models/activity_model.dart';

class ActivityStyle {
  final Color color;
  final IconData icon;

  const ActivityStyle({
    required this.color,
    required this.icon,
  });
}

ActivityStyle activityStyle(ActivityType type) {
  switch (type) {
    case ActivityType.groupCreated:
      return const ActivityStyle(
        color: Color(0xFF3949AB),
        icon: Icons.group_add_rounded,
      );

    case ActivityType.groupRenamed:
      return const ActivityStyle(
        color: Color(0xFF00838F),
        icon: Icons.edit_rounded,
      );

    case ActivityType.memberAdded:
      return const ActivityStyle(
        color: Color(0xFF1E88E5),
        icon: Icons.person_add_alt_1_rounded,
      );

    case ActivityType.memberJoined:
      return const ActivityStyle(
        color: Color(0xFF43A047),
        icon: Icons.login_rounded,
      );

    case ActivityType.memberLeft:
      return const ActivityStyle(
        color: Color(0xFF757575),
        icon: Icons.person_remove_rounded,
      );

    case ActivityType.expenseCreated:
      return const ActivityStyle(
        color: Color(0xFF1565C0),
        icon: Icons.add_card_rounded,
      );

    case ActivityType.expenseUpdated:
      return const ActivityStyle(
        color: Color(0xFFEF6C00),
        icon: Icons.edit_note_rounded,
      );

    case ActivityType.expenseDeleted:
      return const ActivityStyle(
        color: Color(0xFFC62828),
        icon: Icons.delete_outline_rounded,
      );

    case ActivityType.repaymentCreated:
      return const ActivityStyle(
        color: Color(0xFF2E7D32),
        icon: Icons.payments_outlined,
      );

    case ActivityType.repaymentDeleted:
      return const ActivityStyle(
        color: Color(0xFFD32F2F),
        icon: Icons.money_off_csred_outlined,
      );

    case ActivityType.invitationSent:
      return const ActivityStyle(
        color: Color(0xFF7B1FA2),
        icon: Icons.mail_outline_rounded,
      );

    case ActivityType.invitationAccepted:
      return const ActivityStyle(
        color: Color(0xFF388E3C),
        icon: Icons.mark_email_read_outlined,
      );

    case ActivityType.invitationDeclined:
      return const ActivityStyle(
        color: Color(0xFFAD1457),
        icon: Icons.unsubscribe_outlined,
      );
  }
}
