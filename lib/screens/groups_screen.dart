import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/group_model.dart';
import '../services/expense_service.dart';
import '../services/group_service.dart';
import '../services/refresh_bus.dart';

import '../theme/theme.dart';
import '../widgets/widgets.dart';

import 'create_group_screen.dart';
import 'group_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final GroupService _groupService = GroupService();
  final ExpenseService _expenseService = ExpenseService();

  List<GroupModel> groups = [];
  StreamSubscription<void>? _refreshSubscription;

  @override
  void initState() {
    super.initState();
    _refreshSubscription = RefreshBus.instance.stream.listen(
      (_) => loadGroups(),
    );
    loadGroups();
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadGroups() async {
    final uid = Supabase.instance.client.auth.currentUser!.id;
    final data = await _groupService.getUserGroups(uid);

    if (!mounted) return;

    setState(() {
      groups = data;
    });
  }

  Future<void> _openCreateGroupScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
    );

    loadGroups();
  }

  Future<void> _openGroup(GroupModel group) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupScreen(
          groupId: group.id,
          groupName: group.name,
          members: group.members,
        ),
      ),
    );

    loadGroups();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        toolbarHeight: 72,
        title: const Row(
          children: [
            Icon(Icons.group, size: 28),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Groupes', style: AppTextStyles.appBarTitle),
                Text('Mes groupes de partage', style: AppTextStyles.appBarSubtitle),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        onPressed: _openCreateGroupScreen,
        child: const Icon(Icons.add, size: 32),
      ),
      body: groups.isEmpty
          ? Center(
              child: Text(
                'Aucun groupe pour le moment',
                style: AppTextStyles.subtitle,
              ),
            )
          : RefreshIndicator(
              onRefresh: loadGroups,
              child: ListView.builder(
                padding: const EdgeInsets.all(AppDimensions.padding),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final g = groups[index];

                  return FutureBuilder<List<Object>>(
                    future: Future.wait<Object>([
                      _expenseService.getExpenseCount(g.id),
                      _expenseService.getTotalAmount(g.id),
                    ]),
                    builder: (context, snapshot) {
                      final expenseCount = snapshot.hasData
                          ? snapshot.data![0] as int
                          : 0;

                      final totalAmount = snapshot.hasData
                          ? snapshot.data![1] as double
                          : 0.0;

                      return AppCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        onTap: () => _openGroup(g),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: AppDimensions.iconCircleRadius,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                g.name.isNotEmpty
                                    ? g.name[0].toUpperCase()
                                    : '?',
                                style: AppTextStyles.avatarInitial,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(g.name, style: AppTextStyles.title),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${g.members.length} amis • $expenseCount dépenses',
                                    style: AppTextStyles.subtitle,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${totalAmount.toStringAsFixed(2)} €',
                                  style: AppTextStyles.amount,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Total',
                                  style: AppTextStyles.subtitle,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}
