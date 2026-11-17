import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final SupabaseClient _db = Supabase.instance.client;

  final Map<String, String> _cache = {};

  Future<void> createUser({
    required String uid,
    required String name,
    required String email,
  }) async {
    await _db.from('profiles').upsert({
      'id': uid,
      'email': email,
      'display_name': name,
    });
  }

  Future<String> getUserDisplayName(String uid) async {
    if (_cache.containsKey(uid)) return _cache[uid]!;

    final row = await _db
        .from('profiles')
        .select('display_name')
        .eq('id', uid)
        .maybeSingle();

    final name = row?['display_name'] ?? 'Utilisateur';

    _cache[uid] = name;

    return name;
  }
}
