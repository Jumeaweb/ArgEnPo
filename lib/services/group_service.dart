import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/group_model.dart';

class GroupService {
  final SupabaseClient _db = Supabase.instance.client;

  Future<String> createGroup(GroupModel group) async {
    final row = await _db
        .from('groups')
        .insert({
          'name': group.name,
          'created_by': group.createdBy,
          'members': group.members,
          'created_at': group.createdAt.toIso8601String(),
        })
        .select('id')
        .single();

    return row['id'] as String;
  }

  Future<List<GroupModel>> getUserGroups(String uid) async {
    final rows = await _db
        .from('groups')
        .select()
        .contains('members', [uid]);

    return rows
        .map((row) => GroupModel.fromMap(row, row['id'] as String))
        .toList();
  }

  Future<void> addMember(String groupId, String uid) async {
    final row = await _db
        .from('groups')
        .select('members')
        .eq('id', groupId)
        .single();

    final members = List<String>.from(row['members'] as List);

    if (members.contains(uid)) return;

    members.add(uid);

    await _db
        .from('groups')
        .update({'members': members})
        .eq('id', groupId);
  }

  Future<bool> addMemberByEmail(
    String groupId,
    String email,
  ) async {
    final result = await _db.rpc(
      'find_profile_id_by_email',
      params: {'search_email': email.trim()},
    );

    final uid = result as String?;

    if (uid == null || uid.isEmpty) {
      return false;
    }

    await addMember(groupId, uid);

    return true;
  }

  Future<void> updateGroupName(
    String groupId,
    String newName,
  ) async {
    await _db
        .from('groups')
        .update({'name': newName})
        .eq('id', groupId);
  }

  Future<void> deleteGroup(String groupId) async {
    await _db.from('groups').delete().eq('id', groupId);
  }
}
