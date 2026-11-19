import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/group_model.dart';
import '../services/auth_service.dart';
import '../services/debt_service.dart';
import '../services/expense_service.dart';
import '../services/group_service.dart';
import '../services/repayment_service.dart';
import '../services/user_service.dart';

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
  final RepaymentService _repaymentService = RepaymentService();
  final DebtService _debtService = DebtService();
  final UserService _userService = UserService();

  List<GroupModel> groups = [];
  double owedToMe = 0;
  double iOwe = 0;
  String displayName = '';

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser!.id;

    final name = await _userService.getUserDisplayName(uid);
    final data = await _groupService.getUserGroups(uid);

    double totalDueToMe = 0;
    double totalOwedByMe = 0;

    for (final g in data) {
      final expenses = await _expenseService.getExpenses(g.id);
      final repayments = await _repaymentService.getRepayments(g.id);

      final balances = _debtService.applyRepayments(
        _debtService.calculateBalances(expenses),
        repayments,
      );

      final mine = balances[uid] ?? 0;

      if (mine > 0) {
        totalDueToMe += mine;
      } else {
        totalOwedByMe += -mine;
      }
    }

    if (!mounted) return;

    setState(() {
      displayName = name;
      groups = data;
      owedToMe = totalDueToMe;
      iOwe = totalOwedByMe;
    });
  }

  Future<void> _openCreateGroupScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
    );

    loadDashboard();
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

    loadDashboard();
  }

  Future<void> _signOut() async {
    await AuthService().signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _buildBalanceCard({
    required String label,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.all(AppDimensions.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              '${amount.toStringAsFixed(2)} €',
              style: AppTextStyles.amount.copyWith(color: color),
            ),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.subtitle),
          ],
        ),
      ),
    );
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
              await _signOut();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        onPressed: _openCreateGroupScreen,
        child: const Icon(Icons.add, size: 32),
      ),
      body: RefreshIndicator(
        onRefresh: loadDashboard,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.padding),
          children: [
            Text(
              displayName.isEmpty
                  ? 'Bonjour !'
                  : 'Bonjour, $displayName !',
              style: AppTextStyles.title,
            ),
            const SizedBox(height: AppDimensions.padding),
            if (groups.isEmpty)
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.padding),
                  child: Text(
                    'Créez votre premier groupe pour commencer à partager vos dépenses.',
                    style: AppTextStyles.subtitle,
                  ),
                ),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBalanceCard(
                    label: 'On me doit',
                    amount: owedToMe,
                    icon: Icons.south_west,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppDimensions.padding),
                  _buildBalanceCard(
                    label: 'Je dois',
                    amount: iOwe,
                    icon: Icons.north_east,
                    color: const Color(0xFFC62828),
                  ),
                ],
              ),
            const SizedBox(height: AppDimensions.padding),
            Text('Mes groupes', style: AppTextStyles.title),
            const SizedBox(height: AppDimensions.padding),
            if (groups.isEmpty)
              Text(
                'Aucun groupe pour le moment',
                style: AppTextStyles.subtitle,
              )
            else
              ...groups.map(
                (g) => AppCard(
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
                          g.name.isNotEmpty ? g.name[0].toUpperCase() : '?',
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
                              '${g.members.length} amis',
                              style: AppTextStyles.subtitle,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}
