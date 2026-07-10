import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'invitation_service.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final InvitationService _invitationService = InvitationService();

  Future<void> _synchronizeCurrentUser() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    await user.reload();

    final refreshedUser = _auth.currentUser;

    if (refreshedUser == null) {
      throw Exception('Impossible de récupérer l’utilisateur connecté');
    }

    await _userService.createOrUpdateUser(
      uid: refreshedUser.uid,
      name: refreshedUser.displayName ?? '',
      email: refreshedUser.email ?? '',
      photoUrl: refreshedUser.photoURL,
    );

    await _invitationService.linkPendingInvitationsForCurrentUser();
  }

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser =
        await GoogleSignIn().signIn();

    if (googleUser == null) {
      throw Exception('Connexion annulée');
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final result = await _auth.signInWithCredential(credential);

    await _synchronizeCurrentUser();

    return result;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await _synchronizeCurrentUser();

    return result;
  }

  Future<UserCredential> createAccountWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    final normalizedName = name.trim();
    final normalizedEmail = email.trim().toLowerCase();

    final result = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );

    final user = result.user;

    if (user == null) {
      throw Exception('Impossible de créer le compte utilisateur');
    }

    await user.updateDisplayName(normalizedName);
    await user.reload();

    await _synchronizeCurrentUser();

    return result;
  }

  Future<void> synchronizeCurrentUser() async {
    await _synchronizeCurrentUser();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(
      email: email.trim().toLowerCase(),
    );
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}
