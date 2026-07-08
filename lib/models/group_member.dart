enum GroupRole {
  owner,
  admin,
  member,
}

class GroupMember {
  final String uid;
  final GroupRole role;
  final DateTime joinedAt;

  const GroupMember({
    required this.uid,
    required this.role,
    required this.joinedAt,
  });

  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      uid: map['uid'] ?? '',
      role: _roleFromString(map['role']),
      joinedAt: DateTime.tryParse(map['joinedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'role': role.name,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }

  static GroupRole _roleFromString(String? value) {
    switch (value) {
      case 'owner':
        return GroupRole.owner;
      case 'admin':
        return GroupRole.admin;
      case 'member':
      default:
        return GroupRole.member;
    }
  }
}