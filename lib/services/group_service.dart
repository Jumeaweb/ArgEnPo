import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_model.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _collection = 'groups';

  Future<String> createGroup(GroupModel group) async {
    final doc = await _firestore
        .collection(_collection)
        .add(group.toMap());

    return doc.id;
  }

  Future<List<GroupModel>> getUserGroups(String uid) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('members', arrayContains: uid)
        .get();

    return snapshot.docs
        .map((doc) => GroupModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> addMember(String groupId, String uid) async {
    await _firestore.collection(_collection).doc(groupId).update({
      'members': FieldValue.arrayUnion([uid]),
    });
  }

  Future<bool> addMemberByEmail(
    String groupId,
    String email,
  ) async {
    final userQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) {
      return false;
    }

    final uid = userQuery.docs.first.id;

    await _firestore.collection(_collection).doc(groupId).update({
      'members': FieldValue.arrayUnion([uid]),
    });

    return true;
  }

  Future<void> updateGroupName(
    String groupId,
    String newName,
  ) async {
    await _firestore.collection(_collection).doc(groupId).update({
      'name': newName,
    });
  }

  Future<void> deleteGroup(String groupId) async {
    await _firestore
        .collection(_collection)
        .doc(groupId)
        .delete();
  }
}