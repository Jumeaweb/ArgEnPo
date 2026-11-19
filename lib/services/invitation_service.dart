import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/invitation_model.dart';

class InvitationService {
  final SupabaseClient _db = Supabase.instance.client;

  String? get _currentUserId => _db.auth.currentUser?.id;

  String? get _currentUserEmail => _db.auth.currentUser?.email;

  /// Envoie une invitation à rejoindre un groupe, par email exact.
  ///
  /// Si le compte existe déjà, l'invitation est directement rattachée
  /// à son profil, sinon elle sera rattachée à la première connexion.
  Future<void> createInvitation({
    required String groupId,
    required String groupName,
    required String email,
  }) async {
    final user = _db.auth.currentUser;

    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    final normalizedEmail = email.trim().toLowerCase();

    final existing = await _db
        .from('invitations')
        .select('id')
        .eq('group_id', groupId)
        .eq('email', normalizedEmail)
        .eq('status', 'pending')
        .limit(1);

    if (existing.isNotEmpty) {
      throw Exception('Une invitation est déjà en attente pour cet email');
    }

    // Le compte existe-t-il déjà ?
    final profileId = await _db.rpc(
      'find_profile_id_by_email',
      params: {'search_email': normalizedEmail},
    );

    await _db.from('invitations').insert({
      'group_id': groupId,
      'email': normalizedEmail,
      'group_name': groupName,
      'invited_user_id': profileId,
      'invited_by': user.id,
      'status': 'pending',
    });
  }

  /// Rattache à l'utilisateur courant les invitations envoyées à son
  /// email avant qu'il ne crée son compte.
  Future<void> linkPendingInvitations() async {
    final email = _currentUserEmail;

    if (email == null || email.isEmpty) return;

    await _db.rpc('link_pending_invitations');
  }

  /// Invitations en attente pour l'utilisateur courant.
  Future<List<InvitationModel>> getPendingInvitations() async {
    final userId = _currentUserId;

    if (userId == null || userId.isEmpty) return [];

    // Les invitations envoyées avant la création du compte sont
    // d'abord rattachées au profil.
    await linkPendingInvitations();

    final rows = await _db
        .from('invitations')
        .select()
        .eq('invited_user_id', userId)
        .eq('status', 'pending');

    final invitations = rows
        .map((row) =>
            InvitationModel.fromMap(row, row['id'] as String))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return invitations;
  }

  /// Invitations en attente pour un groupe (visibles par ses membres).
  Future<List<InvitationModel>> getPendingInvitationsForGroup(
    String groupId,
  ) async {
    final rows = await _db
        .from('invitations')
        .select()
        .eq('group_id', groupId)
        .eq('status', 'pending');

    final invitations = rows
        .map((row) =>
            InvitationModel.fromMap(row, row['id'] as String))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return invitations;
  }

  /// Accepte une invitation : l'utilisateur rejoint le groupe.
  /// Renvoie l'id du groupe rejoint.
  Future<String> acceptInvitation(InvitationModel invitation) async {
    final groupId = await _db.rpc(
      'accept_invitation',
      params: {'p_invitation_id': invitation.id},
    );

    return groupId as String;
  }

  /// Refuse une invitation.
  Future<void> declineInvitation(String invitationId) async {
    final userId = _currentUserId;

    final rows = await _db
        .from('invitations')
        .select('invited_user_id')
        .eq('id', invitationId)
        .limit(1);

    if (rows.isEmpty) {
      throw Exception('Invitation introuvable');
    }

    final invitedUserId = rows.first['invited_user_id'] as String?;

    if (userId != null && (invitedUserId == null || invitedUserId.isEmpty)) {
      await _db
          .from('invitations')
          .update({'invited_user_id': userId})
          .eq('id', invitationId);
    }

    await _db
        .from('invitations')
        .update({'status': 'declined'})
        .eq('id', invitationId);
  }
}
