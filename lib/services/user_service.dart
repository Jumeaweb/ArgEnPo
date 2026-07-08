import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createUser({
    required String uid,
    required String name,
    required String email,
  }) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email.trim().toLowerCase(),
      'createdAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

final Map<String, String> _cache = {};

Future<String> getUserDisplayName(String uid) async {
  if (_cache.containsKey(uid)) return _cache[uid]!;

  final doc = await _db.collection('users').doc(uid).get();

  final name = doc.data()?['displayName']
      ?? doc.data()?['name']
      ?? 'Utilisateur';

  _cache[uid] = name;

  return name;
}
Future<UserModel?> getUser(String uid) async {
  final doc = await _db.collection('users').doc(uid).get();

  if (!doc.exists || doc.data() == null) {
    return null;
  }

  return UserModel.fromMap(doc.data()!);
}

Stream<UserModel?> watchUser(String uid) {
  return _db.collection('users').doc(uid).snapshots().map((doc) {
    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return UserModel.fromMap(doc.data()!);
  });
}
}