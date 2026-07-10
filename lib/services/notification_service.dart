import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/expense_model.dart';
import '../models/notification_model.dart';
import '../models/repayment_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

  String? get _currentUserId => _auth.currentUser?.uid;

  Stream<List<AppNotificationModel>> watchCurrentUserNotifications() {
    final userId = _currentUserId;

    if (userId == null || userId.isEmpty) {
      return Stream.value(const []);
    }

    return _notifications
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs
          .map(AppNotificationModel.fromFirestore)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return notifications;
    });
  }

  Stream<int> watchUnreadCount() {
    return watchCurrentUserNotifications().map(
      (notifications) =>
          notifications.where((notification) => !notification.isRead).length,
    );
  }

  Future<void> markAsRead(String notificationId) async {
    await _notifications.doc(notificationId).update({
      'isRead': true,
    });
  }

  Future<void> markAllAsRead() async {
    final userId = _currentUserId;

    if (userId == null || userId.isEmpty) {
      return;
    }

    final snapshot = await _notifications
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isRead': true,
      });
    }

    await batch.commit();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _notifications.doc(notificationId).delete();
  }

  Future<void> createInvitationNotification({
    required String userId,
    required String invitationId,
    required String groupId,
    required String groupName,
    required String invitedByName,
  }) async {
    if (userId.isEmpty) {
      return;
    }

    final notificationId = 'invitation_${invitationId}_$userId';

    final notification = AppNotificationModel(
      id: notificationId,
      userId: userId,
      type: 'invitation',
      title: 'Nouvelle invitation',
      message: '$invitedByName vous invite à rejoindre le groupe $groupName.',
      groupId: groupId,
      invitationId: invitationId,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await _notifications.doc(notificationId).set(
          notification.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> markInvitationNotificationAsRead({
    required String invitationId,
    required String userId,
  }) async {
    final notificationId = 'invitation_${invitationId}_$userId';
    final notificationRef = _notifications.doc(notificationId);
    final notificationDoc = await notificationRef.get();

    if (!notificationDoc.exists) {
      return;
    }

    await notificationRef.update({
      'isRead': true,
    });
  }

  Future<void> createExpenseNotifications({
    required String expenseId,
    required ExpenseModel expense,
  }) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return;
    }

    final groupDoc = await _firestore.collection('groups').doc(expense.groupId).get();

    if (!groupDoc.exists) {
      return;
    }

    final groupData = groupDoc.data() ?? <String, dynamic>{};
    final groupName = groupData['name'] as String? ?? 'le groupe';
    final members = List<String>.from(groupData['members'] ?? const <String>[]);
    final actorName = currentUser.displayName ?? currentUser.email ?? 'Un membre';
    final recipients = members.where((memberId) => memberId != currentUser.uid);

    final batch = _firestore.batch();
    var hasNotification = false;

    for (final userId in recipients) {
      if (userId.isEmpty) {
        continue;
      }

      hasNotification = true;
      final notificationId = 'expense_${expenseId}_$userId';
      final notification = AppNotificationModel(
        id: notificationId,
        userId: userId,
        type: 'expense',
        title: 'Nouvelle dépense',
        message:
            '$actorName a ajouté « ${expense.title} » (${expense.amount.toStringAsFixed(2)} €) dans $groupName.',
        groupId: expense.groupId,
        expenseId: expenseId,
        isRead: false,
        createdAt: DateTime.now(),
      );

      batch.set(
        _notifications.doc(notificationId),
        notification.toMap(),
        SetOptions(merge: true),
      );
    }

    if (hasNotification) {
      await batch.commit();
    }
  }

  Future<void> createRepaymentNotifications({
    required String groupId,
    required String repaymentId,
    required RepaymentModel repayment,
  }) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return;
    }

    final groupDoc = await _firestore.collection('groups').doc(groupId).get();
    final groupData = groupDoc.data() ?? <String, dynamic>{};
    final groupName = groupData['name'] as String? ?? 'le groupe';
    final actorName = currentUser.displayName ?? currentUser.email ?? 'Un membre';
    final recipients = <String>{repayment.from, repayment.to}
      ..remove(currentUser.uid)
      ..removeWhere((userId) => userId.isEmpty);

    if (recipients.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final userId in recipients) {
      final notificationId = 'repayment_${repaymentId}_$userId';
      final notification = AppNotificationModel(
        id: notificationId,
        userId: userId,
        type: 'repayment',
        title: 'Nouveau remboursement',
        message:
            '$actorName a enregistré un remboursement de ${repayment.amount.toStringAsFixed(2)} € dans $groupName.',
        groupId: groupId,
        repaymentId: repaymentId,
        isRead: false,
        createdAt: DateTime.now(),
      );

      batch.set(
        _notifications.doc(notificationId),
        notification.toMap(),
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }
}
