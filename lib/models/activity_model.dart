import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType {
  groupCreated,
  groupRenamed,
  memberAdded,
  memberJoined,
  memberLeft,
  expenseCreated,
  expenseUpdated,
  expenseDeleted,
  repaymentCreated,
  repaymentDeleted,
  invitationSent,
  invitationAccepted,
  invitationDeclined,
}

extension ActivityTypeExtension on ActivityType {
  String get value {
    switch (this) {
      case ActivityType.groupCreated:
        return 'group_created';
      case ActivityType.groupRenamed:
        return 'group_renamed';
      case ActivityType.memberAdded:
        return 'member_added';
      case ActivityType.memberJoined:
        return 'member_joined';
      case ActivityType.memberLeft:
        return 'member_left';
      case ActivityType.expenseCreated:
        return 'expense_created';
      case ActivityType.expenseUpdated:
        return 'expense_updated';
      case ActivityType.expenseDeleted:
        return 'expense_deleted';
      case ActivityType.repaymentCreated:
        return 'repayment_created';
      case ActivityType.repaymentDeleted:
        return 'repayment_deleted';
      case ActivityType.invitationSent:
        return 'invitation_sent';
      case ActivityType.invitationAccepted:
        return 'invitation_accepted';
      case ActivityType.invitationDeclined:
        return 'invitation_declined';
    }
  }

  static ActivityType fromValue(String value) {
    switch (value) {
      case 'group_created':
        return ActivityType.groupCreated;
      case 'group_renamed':
        return ActivityType.groupRenamed;
      case 'member_added':
        return ActivityType.memberAdded;
      case 'member_joined':
        return ActivityType.memberJoined;
      case 'member_left':
        return ActivityType.memberLeft;
      case 'expense_created':
        return ActivityType.expenseCreated;
      case 'expense_updated':
        return ActivityType.expenseUpdated;
      case 'expense_deleted':
        return ActivityType.expenseDeleted;
      case 'repayment_created':
        return ActivityType.repaymentCreated;
      case 'repayment_deleted':
        return ActivityType.repaymentDeleted;
      case 'invitation_sent':
        return ActivityType.invitationSent;
      case 'invitation_accepted':
        return ActivityType.invitationAccepted;
      case 'invitation_declined':
        return ActivityType.invitationDeclined;
      default:
        return ActivityType.groupCreated;
    }
  }
}

class ActivityModel {
  final String id;
  final String groupId;
  final ActivityType type;

  final String userId;
  final String userName;
  final String? userPhotoUrl;

  final String? targetUserId;
  final String? targetUserName;

  final String? expenseId;
  final String? repaymentId;
  final String? invitationId;

  final String? title;
  final double? amount;

  final DateTime createdAt;

  const ActivityModel({
    required this.id,
    required this.groupId,
    required this.type,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    this.targetUserId,
    this.targetUserName,
    this.expenseId,
    this.repaymentId,
    this.invitationId,
    this.title,
    this.amount,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'type': type.value,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'targetUserId': targetUserId,
      'targetUserName': targetUserName,
      'expenseId': expenseId,
      'repaymentId': repaymentId,
      'invitationId': invitationId,
      'title': title,
      'amount': amount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ActivityModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    return ActivityModel(
      id: doc.id,
      groupId: data['groupId'] as String? ?? '',
      type: ActivityTypeExtension.fromValue(
        data['type'] as String? ?? '',
      ),
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Utilisateur',
      userPhotoUrl: data['userPhotoUrl'] as String?,
      targetUserId: data['targetUserId'] as String?,
      targetUserName: data['targetUserName'] as String?,
      expenseId: data['expenseId'] as String?,
      repaymentId: data['repaymentId'] as String?,
      invitationId: data['invitationId'] as String?,
      title: data['title'] as String?,
      amount: (data['amount'] as num?)?.toDouble(),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  ActivityModel copyWith({
    String? id,
    String? groupId,
    ActivityType? type,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? targetUserId,
    String? targetUserName,
    String? expenseId,
    String? repaymentId,
    String? invitationId,
    String? title,
    double? amount,
    DateTime? createdAt,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      targetUserId: targetUserId ?? this.targetUserId,
      targetUserName: targetUserName ?? this.targetUserName,
      expenseId: expenseId ?? this.expenseId,
      repaymentId: repaymentId ?? this.repaymentId,
      invitationId: invitationId ?? this.invitationId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
