import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final List<String> members;
  final String ownerId;
  final List<String> admins;
  final DateTime? createdAt;

  GroupModel({
    required this.id,
    required this.name,
    required this.members,
    String? ownerId,
    List<String>? admins,
    String? createdBy,
    this.createdAt,
  })  : ownerId = ownerId ?? createdBy ?? (members.isNotEmpty ? members.first : ''),
        admins = admins ??
            [
              ownerId ?? createdBy ?? (members.isNotEmpty ? members.first : ''),
            ];

  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupModel.fromMap(data, doc.id);
  }

  factory GroupModel.fromMap(Map<String, dynamic> data, String id) {
    final members = List<String>.from(data['members'] ?? []);

    final ownerId = data['ownerId'] as String? ??
        data['createdBy'] as String? ??
        (members.isNotEmpty ? members.first : '');

    final admins = List<String>.from(
      data['admins'] ?? (ownerId.isNotEmpty ? [ownerId] : []),
    );

    DateTime? createdAt;
    final rawCreatedAt = data['createdAt'];

    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is DateTime) {
      createdAt = rawCreatedAt;
    }

    return GroupModel(
      id: id,
      name: data['name'] ?? '',
      members: members,
      ownerId: ownerId,
      admins: admins,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'members': members,
      'ownerId': ownerId,
      'admins': admins,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  bool isOwner(String uid) {
    return ownerId == uid;
  }

  bool isAdmin(String uid) {
    return ownerId == uid || admins.contains(uid);
  }

  bool isMember(String uid) {
    return members.contains(uid);
  }
}