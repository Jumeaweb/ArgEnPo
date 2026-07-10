import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/activity_model.dart';
import '../models/group_model.dart';
import '../models/group_member.dart';
import '../models/user_model.dart';
import 'activity_service.dart';
import 'invitation_service.dart';

enum AddMemberResult {
  added,
  invited,
  alreadyMember,
}

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final InvitationService _invitationService = InvitationService();
  final ActivityService _activityService = ActivityService();

  String? get _currentUserId => _auth.currentUser?.uid;

  Future<void> createGroup({
    required String name,
  }) async {
    final userId = _currentUserId;

    if (userId == null) {
      throw Exception('Utilisateur non connecté');
    }

    final groupDoc = _firestore.collection('groups').doc();

    final group = GroupModel(
      id: groupDoc.id,
      name: name,
      ownerId: userId,
      admins: [userId],
      members: [userId],
      createdAt: DateTime.now(),
    );

    await groupDoc.set(group.toMap());

    await groupDoc.collection('members').doc(userId).set(
      GroupMember(
        uid: userId,
        role: GroupRole.owner,
        joinedAt: DateTime.now(),
      ).toMap(),
    );

    await _activityService.addActivity(
      groupId: groupDoc.id,
      type: ActivityType.groupCreated,
      title: name.trim(),
    );
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
      ..sort((a, b) {
        final dateA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });

    return groups;
  }

  Future<void> updateGroupName(
    String groupId,
    String newName,
  ) async {
    await _firestore.collection('groups').doc(groupId).update({
      'name': newName.trim(),
    });

    await _activityService.addActivity(
      groupId: groupId,
      type: ActivityType.groupRenamed,
      title: newName.trim(),
    );
  }

  Future<AddMemberResult> addMemberByEmail(
    String groupId,
    String email,
  ) async {
    final userId = _currentUserId;

    if (userId == null) {
      throw Exception('Utilisateur non connecté');
    }

    final canManage = await canManageMembers(groupId);

    if (!canManage) {
      throw Exception('Vous n’avez pas les droits pour ajouter un membre');
    }

    final normalizedEmail = email.trim().toLowerCase();

    final groupDoc = await _firestore.collection('groups').doc(groupId).get();

    final userSnapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    if (userSnapshot.docs.isEmpty) {
      await _invitationService.createInvitation(
        groupId: groupId,
        groupName: groupDoc.data()?['name'] ?? 'Groupe',
        email: normalizedEmail,
      );

      return AddMemberResult.invited;
    }

    final newMemberDoc = userSnapshot.docs.first;
    final newMemberId = newMemberDoc.id;

    final members = List<String>.from(
      groupDoc.data()?['members'] ?? [],
    );

    if (members.contains(newMemberId)) {
      return AddMemberResult.alreadyMember;
    }

    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([newMemberId]),
    });

    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .doc(newMemberId)
        .set(
          GroupMember(
            uid: newMemberId,
            role: GroupRole.member,
            joinedAt: DateTime.now(),
          ).toMap(),
          SetOptions(merge: true),
        );

    final newMemberData = newMemberDoc.data();
    final newMemberName =
        newMemberData['displayName'] as String? ??
        newMemberData['name'] as String? ??
        newMemberData['email'] as String? ??
        normalizedEmail;

    await _activityService.addActivity(
      groupId: groupId,
      type: ActivityType.memberAdded,
      targetUserId: newMemberId,
      targetUserName: newMemberName,
    );

    return AddMemberResult.added;
  }

  Future<List<UserModel>> getMembers(String groupId) async {
    final groupDoc =
        await _firestore.collection('groups').doc(groupId).get();

    final memberIds = List<String>.from(
      groupDoc.data()?['members'] ?? [],
    );

    if (memberIds.isEmpty) {
      return [];
    }

    final members = <UserModel>[];

    for (final uid in memberIds) {
      final userDoc =
          await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        members.add(UserModel.fromMap(userDoc.data()!));
      }
    }

    return members;
  }

  Future<bool> isOwner(String groupId) async {
    final userId = _currentUserId;

    if (userId == null) {
      return false;
    }

    final groupDoc =
        await _firestore.collection('groups').doc(groupId).get();

    final data = groupDoc.data();

    if (data == null) {
      return false;
    }

    final ownerId = data['ownerId'] as String?;

    return ownerId == userId;
  }

  Future<bool> isAdmin(String groupId) async {
    final userId = _currentUserId;

    if (userId == null) {
      return false;
    }

    final groupDoc =
        await _firestore.collection('groups').doc(groupId).get();

    final data = groupDoc.data();

    if (data == null) {
      return false;
    }

    final ownerId = data['ownerId'] as String?;
    final admins = List<String>.from(data['admins'] ?? []);

    return ownerId == userId || admins.contains(userId);
  }

  Future<bool> canManageMembers(String groupId) async {
    return isAdmin(groupId);
  }

  Future<void> deleteGroup(String groupId) async {
    await _deleteSubcollection(groupId, 'expenses');
    await _deleteSubcollection(groupId, 'repayments');
    await _deleteSubcollection(groupId, 'activities');
    await _deleteSubcollection(groupId, 'members');

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

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
