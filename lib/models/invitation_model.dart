import 'package:cloud_firestore/cloud_firestore.dart';

class InvitationModel {
  final String id;
  final String groupId;
  final String groupName;
  final String email;
  final String? invitedUserId;
  final String invitedBy;
  final String invitedByName;
  final String status;
  final DateTime createdAt;
  final DateTime? acceptedAt;

  InvitationModel({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.email,
    this.invitedUserId,
    required this.invitedBy,
    required this.invitedByName,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
  });

  factory InvitationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return InvitationModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      groupName: data['groupName'] ?? '',
      email: data['email'] ?? '',
      invitedUserId: data['invitedUserId'],
      invitedBy: data['invitedBy'] ?? '',
      invitedByName: data['invitedByName'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'email': email,
      'invitedUserId': invitedUserId,
      'invitedBy': invitedBy,
      'invitedByName': invitedByName,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt == null ? null : Timestamp.fromDate(acceptedAt!),
    };
  }
}