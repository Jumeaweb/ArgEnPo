import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/activity_model.dart';
import '../models/repayment_model.dart';
import 'activity_service.dart';
import 'notification_service.dart';

class RepaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final ActivityService _activityService = ActivityService();

  Future<void> addRepayment(
    String groupId,
    RepaymentModel repayment,
  ) async {
    final repaymentRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('repayments')
        .doc();

    await repaymentRef.set(repayment.toMap());

    await _activityService.addActivity(
      groupId: groupId,
      type: ActivityType.repaymentCreated,
      targetUserId: repayment.to,
      repaymentId: repaymentRef.id,
      amount: repayment.amount,
    );

    await _notificationService.createRepaymentNotifications(
      groupId: groupId,
      repaymentId: repaymentRef.id,
      repayment: repayment,
    );
  }

  Future<List<RepaymentModel>> getRepayments(
    String groupId,
  ) async {
    final snapshot = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('repayments')
        .get();

    return snapshot.docs
        .map(
          (doc) => RepaymentModel.fromMap(
            doc.data(),
            doc.id,
          ),
        )
        .toList();
  }

  Stream<List<RepaymentModel>> watchRepayments(
    String groupId,
  ) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('repayments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => RepaymentModel.fromMap(
                  doc.data(),
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  Future<void> deleteRepayment(
    String groupId,
    String repaymentId,
  ) async {
    final repaymentRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('repayments')
        .doc(repaymentId);

    final repaymentDoc = await repaymentRef.get();
    final repaymentData = repaymentDoc.data();

    await repaymentRef.delete();

    await _activityService.addActivity(
      groupId: groupId,
      type: ActivityType.repaymentDeleted,
      targetUserId: repaymentData?['to'] as String?,
      repaymentId: repaymentId,
      amount: (repaymentData?['amount'] as num?)?.toDouble(),
    );
  }
}
