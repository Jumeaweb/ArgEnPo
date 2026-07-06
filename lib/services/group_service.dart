import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/group_model.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  Future<void> createGroup({
    required String name,
  }) async {
    final userId = _currentUserId;

    if (userId == null) {
      throw Exception('Utilisateur non connecté');
    }

    final group = GroupModel(
      id: '',
      name: name.trim(),
      createdBy: userId,
      members: [userId],
      createdAt: DateTime.now(),
    );

    await _firestore.collection('groups').add(group.toMap());
  }

  Future<List<GroupModel>> getUserGroups(String userId) async {
    final byMemberSnapshot = await _firestore
        .collection('groups')
        .where('members', arrayContains: userId)
        .get();

    final byCreatorSnapshot = await _firestore
        .collection('groups')
        .where('createdBy', isEqualTo: userId)
        .get();

    final Map<String, GroupModel> groupsById = {};

    for (final doc in byMemberSnapshot.docs) {
      groupsById[doc.id] = GroupModel.fromMap(doc.data(), doc.id);
    }

    for (final doc in byCreatorSnapshot.docs) {
      groupsById[doc.id] = GroupModel.fromMap(doc.data(), doc.id);
    }

    final groups = groupsById.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return groups;
  }

  Future<void> updateGroupName(
    String groupId,
    String newName,
  ) async {
    await _firestore.collection('groups').doc(groupId).update({
      'name': newName.trim(),
    });
  }

  Future<bool> addMemberByEmail(
    String groupId,
    String email,
  ) async {
    final normalizedEmail = email.trim().toLowerCase();

    final userSnapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    if (userSnapshot.docs.isEmpty) {
      return false;
    }

    final userId = userSnapshot.docs.first.id;

    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([userId]),
    });

    return true;
  }

  Future<void> deleteGroup(String groupId) async {
    await _deleteSubcollection(groupId, 'expenses');
    await _deleteSubcollection(groupId, 'repayments');

    await _firestore.collection('groups').doc(groupId).delete();
  }

  Future<void> _deleteSubcollection(
    String groupId,
    String subcollectionName,
  ) async {
    final snapshot = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection(subcollectionName)
        .get();

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}