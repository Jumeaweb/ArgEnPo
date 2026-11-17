import 'package:supabase_flutter/supabase_flutter.dart';

import 'user_service.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;
  final UserService _userService = UserService();

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    return response.user!;
  }

  Future<User> createAccountWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'name': name.trim()},
    );

    final user = response.user!;

    // Avec confirmation d'email obligatoire, signUp n'ouvre pas de session :
    // le profil est alors créé par le déclencheur SQL côté serveur.
    if (response.session != null) {
      await _userService.createUser(
        uid: user.id,
        name: name.trim(),
        email: email.trim(),
      );
    }

    return user;
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
