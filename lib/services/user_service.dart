import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final Map<String, String> _displayNameCache = {};

  Future<void> createOrUpdateUser({
    required String uid,
    required String name,
    required String email,
    String? photoUrl,
  }) async {
    final userRef = _db.collection('users').doc(uid);
    final userDoc = await userRef.get();

    final normalizedName = name.trim();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPhotoUrl = photoUrl?.trim();

    if (!userDoc.exists) {
      final storedPhotoUrl = normalizedPhotoUrl != null &&
              normalizedPhotoUrl.isNotEmpty
          ? normalizedPhotoUrl
          : null;

      await userRef.set({
        'uid': uid,
        'displayName': normalizedName,
        'name': normalizedName,
        'email': normalizedEmail,
        'photoUrl': storedPhotoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _displayNameCache.remove(uid);
      return;
    }

    final currentData = userDoc.data() ?? <String, dynamic>{};

    final currentDisplayName =
        (currentData['displayName'] as String?)?.trim() ??
            (currentData['name'] as String?)?.trim() ??
            '';

    final currentEmail =
        (currentData['email'] as String?)?.trim().toLowerCase() ?? '';

    final currentPhotoUrl =
        (currentData['photoUrl'] as String?)?.trim() ?? '';

    final effectiveDisplayName = normalizedName.isNotEmpty
        ? normalizedName
        : currentDisplayName;

    final effectivePhotoUrl = normalizedPhotoUrl != null &&
            normalizedPhotoUrl.isNotEmpty
        ? normalizedPhotoUrl
        : currentPhotoUrl;

    final updates = <String, dynamic>{};

    if ((currentData['uid'] as String?) != uid) {
      updates['uid'] = uid;
    }

    if (effectiveDisplayName != currentDisplayName) {
      updates['displayName'] = effectiveDisplayName;
      updates['name'] = effectiveDisplayName;
    } else {
      if (!currentData.containsKey('displayName')) {
        updates['displayName'] = effectiveDisplayName;
      }

      if (!currentData.containsKey('name')) {
        updates['name'] = effectiveDisplayName;
      }
    }

    if (normalizedEmail != currentEmail) {
      updates['email'] = normalizedEmail;
    }

    final storedPhotoUrl =
        effectivePhotoUrl.isEmpty ? null : effectivePhotoUrl;

    final currentStoredPhotoUrl =
        currentPhotoUrl.isEmpty ? null : currentPhotoUrl;

    if (storedPhotoUrl != currentStoredPhotoUrl) {
      updates['photoUrl'] = storedPhotoUrl;
    } else if (!currentData.containsKey('photoUrl')) {
      updates['photoUrl'] = storedPhotoUrl;
    }

    if (updates.isEmpty) {
      return;
    }

    updates['updatedAt'] = FieldValue.serverTimestamp();

    await userRef.set(
      updates,
      SetOptions(merge: true),
    );

    _displayNameCache.remove(uid);
  }

  Future<void> createUser({
    required String uid,
    required String name,
    required String email,
    String? photoUrl,
  }) async {
    await createOrUpdateUser(
      uid: uid,
      name: name,
      email: email,
      photoUrl: photoUrl,
    );
  }

  Future<String> getUserDisplayName(String uid) async {
    final cachedName = _displayNameCache[uid];

    if (cachedName != null) {
      return cachedName;
    }

    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();

    final displayName =
        (data?['displayName'] as String?)?.trim() ??
            (data?['name'] as String?)?.trim() ??
            '';

    final resolvedName =
        displayName.isNotEmpty ? displayName : 'Utilisateur';

    _displayNameCache[uid] = resolvedName;

    return resolvedName;
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return _userFromData(doc.data()!);
  }

  Stream<UserModel?> watchUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return _userFromData(doc.data()!);
    });
  }

  UserModel _userFromData(Map<String, dynamic> data) {
    final displayName =
        (data['displayName'] as String?)?.trim() ??
            (data['name'] as String?)?.trim() ??
            '';

    return UserModel(
      uid: data['uid'] as String? ?? '',
      email: data['email'] as String? ?? '',
      displayName: displayName,
      photoUrl: data['photoUrl'] as String?,
    );
  }
}
