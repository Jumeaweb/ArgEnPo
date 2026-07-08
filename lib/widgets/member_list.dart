import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/group_service.dart';
import '../theme/theme.dart';

class MemberList extends StatelessWidget {
  final String groupId;

  const MemberList({
    super.key,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserModel>>(
      future: GroupService().getMembers(groupId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final members = snapshot.data!;

        if (members.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text("Aucun membre"),
          );
        }

        return Column(
          children: members.map((member) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: member.photoUrl != null &&
                          member.photoUrl!.isNotEmpty
                      ? NetworkImage(member.photoUrl!)
                      : null,
                  child: member.photoUrl == null ||
                          member.photoUrl!.isEmpty
                      ? Text(
                          member.displayName.isNotEmpty
                              ? member.displayName[0].toUpperCase()
                              : "?",
                        )
                      : null,
                ),
                title: Text(
                  member.displayName,
                  style: AppTextStyles.title,
                ),
                subtitle: Text(member.email),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}