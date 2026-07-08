import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/repayment_model.dart';

class RepaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addRepayment(
    String groupId,
    RepaymentModel repayment,
  ) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('repayments')
        .add(repayment.toMap());
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
        .map((doc) => RepaymentModel.fromMap(
              doc.data(),
              doc.id,
            ))
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
              .map((doc) => RepaymentModel.fromMap(
                    doc.data(),
                    doc.id,
                  ))
              .toList(),
        );
  }

  Future<void> deleteRepayment(
    String groupId,
    String repaymentId,
  ) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('repayments')
        .doc(repaymentId)
        .delete();
  }
}