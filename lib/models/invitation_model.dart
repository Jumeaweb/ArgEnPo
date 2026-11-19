class InvitationModel {
  final String id;
  final String groupId;
  final String groupName;
  final String email;
  final String? invitedUserId;
  final String invitedBy;
  final String status;
  final DateTime createdAt;
  final DateTime? acceptedAt;

  InvitationModel({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.email,
    required this.invitedUserId,
    required this.invitedBy,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
  });

  factory InvitationModel.fromMap(Map<String, dynamic> map, String id) {
    return InvitationModel(
      id: id,
      groupId: map['group_id'] ?? '',
      groupName: map['group_name'] ?? '',
      email: map['email'] ?? '',
      invitedUserId: map['invited_user_id'],
      invitedBy: map['invited_by'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: DateTime.parse(map['created_at']),
      acceptedAt: map['accepted_at'] == null
          ? null
          : DateTime.parse(map['accepted_at']),
    );
  }
}
