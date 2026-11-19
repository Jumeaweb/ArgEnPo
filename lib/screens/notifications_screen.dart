import 'package:flutter/material.dart';

import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/refresh_bus.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  late Future<List<NotificationModel>> _notificationsFuture;
  bool _isMarkingAllAsRead = false;

  @override
  void initState() {
    super.initState();

    _reload();

    // L'ouverture de la liste marque tout comme lu, comme en v0.8.5.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAllAsRead();
    });
  }

  void _reload() {
    _notificationsFuture = _notificationService.getNotifications();
  }

  Future<void> _markAllAsRead() async {
    if (_isMarkingAllAsRead) return;

    _isMarkingAllAsRead = true;

    try {
      await _notificationService.markAllAsRead();
      RefreshBus.instance.notify();
    } finally {
      _isMarkingAllAsRead = false;
    }
  }

  Future<void> _deleteNotification(
    NotificationModel notification,
  ) async {
    await _notificationService.deleteNotification(notification.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification supprimée'),
      ),
    );

    setState(() {
      _reload();
    });
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

      return minutes == 1 ? 'Il y a 1 min' : 'Il y a $minutes min';
    }

    if (difference.inHours < 24) {
      final hours = difference.inHours;

      return hours == 1 ? 'Il y a 1 h' : 'Il y a $hours h';
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
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppDimensions.padding * 2),
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
                'Les dépenses et remboursements de vos groupes '
                'apparaîtront ici.',
                style: AppTextStyles.subtitle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationTile(
    NotificationModel notification,
  ) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      child: Row(
        children: [
          Icon(
            _getNotificationIcon(notification.type),
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: AppTextStyles.title,
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatRelativeDate(notification.createdAt),
                  style: AppTextStyles.subtitle,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.danger,
              size: 20,
            ),
            onPressed: () => _deleteNotification(notification),
          ),
        ],
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
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _reload();
          });
        },
        child: FutureBuilder<List<NotificationModel>>(
          future: _notificationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(AppDimensions.padding),
                    child: Center(
                      child: Text(
                        'Erreur de chargement des notifications',
                        style: AppTextStyles.subtitle,
                      ),
                    ),
                  ),
                ],
              );
            }

            final notifications = snapshot.data ?? [];

            if (notifications.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.padding),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return _buildNotificationTile(notifications[index]);
              },
            );
          },
        ),
      ),
    );
  }
}
