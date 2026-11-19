import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification_model.dart';

/// Les notifications sont créées côté serveur (triggers Postgres) :
/// ce service ne fait que les lire, les marquer comme lues et les
/// supprimer.
class NotificationService {
  final SupabaseClient _db = Supabase.instance.client;

  String? get _currentUserId => _db.auth.currentUser?.id;

  Future<List<NotificationModel>> getNotifications({
    int limit = 50,
  }) async {
    final userId = _currentUserId;

    if (userId == null || userId.isEmpty) return [];

    final rows = await _db
        .from('notifications')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);

    return rows.map(NotificationModel.fromMap).toList();
  }

  Future<int> getUnreadCount() async {
    final userId = _currentUserId;

    if (userId == null || userId.isEmpty) return 0;

    final rows = await _db
        .from('notifications')
        .select('id')
        .eq('is_read', false);

    return rows.length;
  }

  Future<void> markAsRead(String notificationId) async {
    await _db
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead() async {
    final userId = _currentUserId;

    if (userId == null || userId.isEmpty) return;

    await _db
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  Future<void> deleteNotification(String notificationId) async {
    await _db.from('notifications').delete().eq('id', notificationId);
  }
}
