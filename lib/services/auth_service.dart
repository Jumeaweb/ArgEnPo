import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

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

    final result =
        await _auth.signInWithCredential(credential);

    final user = result.user!;

await _userService.createUser(
  uid: user.uid,
  name: user.displayName ?? '',
  email: user.email ?? '',
);

    return result;
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

 Future<UserCredential> signInWithEmail({
  required String email,
  required String password,
}) async {
  final result = await _auth.signInWithEmailAndPassword(
    email: email.trim(),
    password: password,
  );

  return result;
}

Future<UserCredential> createAccountWithEmail({
  required String email,
  required String password,
  required String name,
}) async {
  final result = await _auth.createUserWithEmailAndPassword(
    email: email.trim(),
    password: password,
  );

  final user = result.user!;

  await user.updateDisplayName(name.trim());

  await _userService.createUser(
    uid: user.uid,
    name: name.trim(),
    email: email.trim(),
  );

  return result;
}

Future<void> resetPassword(String email) async {
  await _auth.sendPasswordResetEmail(
    email: email.trim(),
  );
} 
}