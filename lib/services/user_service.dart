import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final Map<String, String> _cache = {};

  Future<void> createOrUpdateUser({
    required String uid,
    required String name,
    required String email,
  }) async {
    final userRef = _db.collection('users').doc(uid);
    final userDoc = await userRef.get();

    final normalizedName = name.trim();
    final normalizedEmail = email.trim().toLowerCase();

    if (!userDoc.exists) {
      await userRef.set({
        'uid': uid,
        'name': normalizedName,
        'email': normalizedEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _cache.remove(uid);
      return;
    }

    final updates = <String, dynamic>{
      'uid': uid,
      'email': normalizedEmail,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (normalizedName.isNotEmpty) {
      updates['name'] = normalizedName;
    }

    await userRef.set(
      updates,
      SetOptions(merge: true),
    );

    _cache.remove(uid);
  }

  Future<void> createUser({
    required String uid,
    required String name,
    required String email,
  }) async {
    await createOrUpdateUser(
      uid: uid,
      name: name,
      email: email,
    );
  }

  Future<String> getUserDisplayName(String uid) async {
    if (_cache.containsKey(uid)) {
      return _cache[uid]!;
    }

    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();

    final name = data?['displayName'] as String? ??
        data?['name'] as String? ??
        'Utilisateur';

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
