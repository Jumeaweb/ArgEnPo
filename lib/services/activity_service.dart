import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/activity_model.dart';

class ActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _activitiesReference(
    String groupId,
  ) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('activities');
  }

  Future<void> addActivity({
    required String groupId,
    required ActivityType type,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? targetUserId,
    String? targetUserName,
    String? expenseId,
    String? repaymentId,
    String? invitationId,
    String? title,
    double? amount,
  }) async {
    if (groupId.trim().isEmpty) {
      throw ArgumentError('Le groupId ne peut pas être vide');
    }

    final currentUser = _auth.currentUser;
    final actorId = userId ?? currentUser?.uid ?? '';

    if (actorId.isEmpty) {
      throw Exception('Utilisateur non connecté');
    }

    final resolvedUserName = userName?.trim().isNotEmpty == true
        ? userName!.trim()
        : currentUser?.displayName?.trim().isNotEmpty == true
            ? currentUser!.displayName!.trim()
            : currentUser?.email?.trim().isNotEmpty == true
                ? currentUser!.email!.trim()
                : await _getUserDisplayName(actorId);

    final resolvedPhotoUrl = userPhotoUrl ??
        currentUser?.photoURL ??
        await _getUserPhotoUrl(actorId);

    final activityRef = _activitiesReference(groupId).doc();

    final activity = ActivityModel(
      id: activityRef.id,
      groupId: groupId,
      type: type,
      userId: actorId,
      userName: resolvedUserName,
      userPhotoUrl: resolvedPhotoUrl,
      targetUserId: targetUserId,
      targetUserName: targetUserName,
      expenseId: expenseId,
      repaymentId: repaymentId,
      invitationId: invitationId,
      title: title,
      amount: amount,
      createdAt: DateTime.now(),
    );

    await activityRef.set(activity.toMap());
  }

  Stream<List<ActivityModel>> watchActivities(
    String groupId, {
    int limit = 100,
  }) {
    if (groupId.trim().isEmpty) {
      return Stream.value(const []);
    }

    return _activitiesReference(groupId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(ActivityModel.fromFirestore)
              .toList(),
        );
  }

  Future<List<ActivityModel>> getActivities(
    String groupId, {
    int limit = 100,
  }) async {
    if (groupId.trim().isEmpty) {
      return [];
    }

    final snapshot = await _activitiesReference(groupId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map(ActivityModel.fromFirestore)
        .toList();
  }

  Future<void> deleteActivity(
    String groupId,
    String activityId,
  ) async {
    if (groupId.trim().isEmpty || activityId.trim().isEmpty) {
      return;
    }

    await _activitiesReference(groupId).doc(activityId).delete();
  }

  Future<int> deleteOldActivities(
    String groupId, {
    Duration retention = const Duration(days: 365),
  }) async {
    if (groupId.trim().isEmpty) {
      return 0;
    }

    final cutoffDate = DateTime.now().subtract(retention);
    var deletedCount = 0;

    while (true) {
      final snapshot = await _activitiesReference(groupId)
          .where(
            'createdAt',
            isLessThan: Timestamp.fromDate(cutoffDate),
          )
          .limit(400)
          .get();

      if (snapshot.docs.isEmpty) {
        break;
      }

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      deletedCount += snapshot.docs.length;

      if (snapshot.docs.length < 400) {
        break;
      }
    }

    return deletedCount;
  }

  Future<String> _getUserDisplayName(String userId) async {
    final userDoc =
        await _firestore.collection('users').doc(userId).get();

    final data = userDoc.data();

    if (data == null) {
      return 'Utilisateur';
    }

    final displayName = data['displayName'] as String?;
    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName.trim();
    }

    final name = data['name'] as String?;
    if (name != null && name.trim().isNotEmpty) {
      return name.trim();
    }

    final email = data['email'] as String?;
    if (email != null && email.trim().isNotEmpty) {
      return email.trim();
    }

    return 'Utilisateur';
  }

  Future<String?> _getUserPhotoUrl(String userId) async {
    final userDoc =
        await _firestore.collection('users').doc(userId).get();

    final data = userDoc.data();

    if (data == null) {
      return null;
    }

    final photoUrl = data['photoUrl'] as String?;
    if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      return photoUrl.trim();
    }

    final photoURL = data['photoURL'] as String?;
    if (photoURL != null && photoURL.trim().isNotEmpty) {
      return photoURL.trim();
    }

    return null;
  }
}
