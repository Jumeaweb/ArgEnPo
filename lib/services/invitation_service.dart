import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/group_member.dart';
import '../models/invitation_model.dart';

class InvitationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  Future<void> createInvitation({
    required String groupId,
    required String groupName,
    required String email,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    final normalizedEmail = email.trim().toLowerCase();

    final existingInvitation = await _firestore
        .collection('invitations')
        .where('groupId', isEqualTo: groupId)
        .where('email', isEqualTo: normalizedEmail)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (existingInvitation.docs.isNotEmpty) {
      throw Exception('Une invitation est déjà en attente pour cet email');
    }

    final invitationRef = _firestore.collection('invitations').doc();

    final invitation = InvitationModel(
      id: invitationRef.id,
      groupId: groupId,
      groupName: groupName,
      email: normalizedEmail,
      invitedUserId: null,
      invitedBy: user.uid,
      invitedByName: user.displayName ?? user.email ?? 'Utilisateur',
      status: 'pending',
      createdAt: DateTime.now(),
      acceptedAt: null,
    );

    await invitationRef.set(invitation.toMap());
  }

  Future<void> linkPendingInvitationsForCurrentUser() async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    final email = user.email?.trim().toLowerCase();

    if (email == null || email.isEmpty) {
      return;
    }

    final snapshot = await _firestore
        .collection('invitations')
        .where('email', isEqualTo: email)
        .where('status', isEqualTo: 'pending')
        .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final currentInvitedUserId = data['invitedUserId'];

      if (currentInvitedUserId == null || currentInvitedUserId == '') {
        batch.update(doc.reference, {
          'invitedUserId': user.uid,
        });
      }
    }

    await batch.commit();
  }

  Stream<List<InvitationModel>> watchPendingInvitationsForCurrentUser() {
    final userId = _currentUserId;

    if (userId == null || userId.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('invitations')
        .where('invitedUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(InvitationModel.fromFirestore)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  Future<List<InvitationModel>> getPendingInvitationsForCurrentUser() async {
    await linkPendingInvitationsForCurrentUser();

    final userId = _currentUserId;

    if (userId == null || userId.isEmpty) {
      return [];
    }

    final snapshot = await _firestore
        .collection('invitations')
        .where('invitedUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .get();

    final invitations = snapshot.docs
        .map(InvitationModel.fromFirestore)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return invitations;
  }

  Future<void> acceptInvitation(InvitationModel invitation) async {
    final userId = _currentUserId;

    if (userId == null) {
      throw Exception('Utilisateur non connecté');
    }

    final invitationRef =
        _firestore.collection('invitations').doc(invitation.id);

    final groupRef = _firestore.collection('groups').doc(invitation.groupId);
    final memberRef = groupRef.collection('members').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final invitationDoc = await transaction.get(invitationRef);
      final groupDoc = await transaction.get(groupRef);

      if (!invitationDoc.exists) {
        throw Exception('Invitation introuvable');
      }

      if (!groupDoc.exists) {
        throw Exception('Groupe introuvable');
      }

      final invitationData = invitationDoc.data();
      final groupData = groupDoc.data();

      if (invitationData == null || groupData == null) {
        throw Exception('Données invalides');
      }

      final status = invitationData['status'];

      if (status != 'pending') {
        throw Exception('Cette invitation n’est plus disponible');
      }

      final members = List<String>.from(groupData['members'] ?? []);

      if (!members.contains(userId)) {
        transaction.update(groupRef, {
          'members': FieldValue.arrayUnion([userId]),
        });

        transaction.set(
          memberRef,
          GroupMember(
            uid: userId,
            role: GroupRole.member,
            joinedAt: DateTime.now(),
          ).toMap(),
        );
      }

      transaction.update(invitationRef, {
        'invitedUserId': userId,
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> declineInvitation(String invitationId) async {
    await _firestore.collection('invitations').doc(invitationId).update({
      'status': 'declined',
    });
  }
}