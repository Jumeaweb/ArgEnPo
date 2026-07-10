import 'package:flutter/material.dart';

import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../theme/theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  bool _isMarkingAllAsRead = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAllAsRead();
    });
  }

  Future<void> _markAllAsRead() async {
    if (_isMarkingAllAsRead) {
      return;
    }

    _isMarkingAllAsRead = true;

    try {
      await _notificationService.markAllAsRead();
    } finally {
      _isMarkingAllAsRead = false;
    }
  }

  Future<void> _deleteNotification(
    AppNotificationModel notification,
  ) async {
    await _notificationService.deleteNotification(notification.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification supprimée'),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'invitation':
        return Icons.mail_outline;
      case 'expense':
        return Icons.receipt_long_outlined;
      case 'repayment':
        return Icons.currency_exchange;
      default:
        return Icons.notifications_none;
    }
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.isNegative || difference.inSeconds < 60) {
      return 'À l’instant';
    }

    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;

      return minutes == 1
          ? 'Il y a 1 min'
          : 'Il y a $minutes min';
    }

    if (difference.inHours < 24) {
      final hours = difference.inHours;

      return hours == 1
          ? 'Il y a 1 h'
          : 'Il y a $hours h';
    }

    if (difference.inDays == 1) {
      return 'Hier';
    }

    if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.55),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune notification',
              style: AppTextStyles.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Les invitations, dépenses et remboursements apparaîtront ici.',
              style: AppTextStyles.subtitle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(
    AppNotificationModel notification,
  ) {
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: Colors.red,
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) {
        _deleteNotification(notification);
      },
      child: Material(
        color: notification.isRead
            ? Colors.transparent
            : AppColors.primary.withValues(alpha: 0.06),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.padding,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            foregroundColor: AppColors.primary,
            child: Icon(
              _getNotificationIcon(notification.type),
            ),
          ),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  notification.title,
                  style: AppTextStyles.title,
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(
                    left: 8,
                    top: 6,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.message,
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: 6),
                Text(
                  _formatRelativeDate(notification.createdAt),
                  style: AppTextStyles.subtitle.copyWith(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          onTap: () async {
            if (!notification.isRead) {
              await _notificationService.markAsRead(notification.id);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        title: const Text(
          'Notifications',
          style: AppTextStyles.appBarTitle,
        ),
        actions: [
          IconButton(
            tooltip: 'Tout marquer comme lu',
            onPressed: _markAllAsRead,
            icon: const Icon(Icons.done_all),
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotificationModel>>(
        stream: _notificationService.watchCurrentUserNotifications(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.padding),
                child: Text(
                  'Impossible de charger les notifications.',
                  style: AppTextStyles.subtitle,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final notifications =
              snapshot.data ?? const <AppNotificationModel>[];

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              await _markAllAsRead();
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
              ),
              itemBuilder: (context, index) {
                return _buildNotificationTile(
                  notifications[index],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
