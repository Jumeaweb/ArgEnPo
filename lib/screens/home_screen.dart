import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/group_model.dart';
import '../services/auth_service.dart';
import '../services/expense_service.dart';
import '../services/group_service.dart';

import '../theme/theme.dart';
import '../widgets/widgets.dart';

import 'create_group_screen.dart';
import 'group_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GroupService _groupService = GroupService();
  final ExpenseService _expenseService = ExpenseService();

  List<GroupModel> groups = [];

  @override
  void initState() {
    super.initState();
    loadGroups();
  }

  Future<void> loadGroups() async {
    final uid = Supabase.instance.client.auth.currentUser!.id;
    final data = await _groupService.getUserGroups(uid);

    if (!mounted) return;

    setState(() {
      groups = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        toolbarHeight: 80,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: AppColors.textLight,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ArgEnPo', style: AppTextStyles.appBarTitle),
                Text('Argent Entre Potes', style: AppTextStyles.appBarSubtitle),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textLight),
            onPressed: () async {
              await AuthService().signOut();

              if (!context.mounted) return;

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
          );

          loadGroups();
        },
        child: const Icon(Icons.add, size: 32),
      ),
      body: Column(
        children: [
          Expanded(
            child: groups.isEmpty
                ? Center(
                    child: Text(
                      'Aucun groupe pour le moment',
                      style: AppTextStyles.subtitle,
                    ),
                  )
                : ListView.builder(
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
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GroupScreen(
                                    groupId: g.id,
                                    groupName: g.name,
                                    members: g.members,
                                  ),
                                ),
                              );

                              loadGroups();
                            },
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
          const AppFooter(),
        ],
      ),
    );
  }
}
