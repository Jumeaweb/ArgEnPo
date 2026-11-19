import 'package:flutter/material.dart';

import '../models/expense_model.dart';
import '../models/repayment_model.dart';

import '../services/debt_service.dart';
import '../services/expense_service.dart';
import '../services/group_service.dart';
import '../services/invitation_service.dart';
import '../services/repayment_service.dart';
import '../services/user_service.dart';

import '../theme/theme.dart';
import '../constants/constants.dart';
import '../widgets/widgets.dart';

import 'add_expense_screen.dart';
import 'edit_expense_screen.dart';

class GroupScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final List<String> members;

  const GroupScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.members,
  });

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final DebtService _debtService = DebtService();
  final UserService _userService = UserService();
  final RepaymentService _repaymentService = RepaymentService();

  List<ExpenseModel> expenses = [];
  List<RepaymentModel> repayments = [];

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    final expenseData =
        await _expenseService.getExpenses(widget.groupId);

    final repaymentData =
        await _repaymentService.getRepayments(widget.groupId);

    if (!mounted) return;

    setState(() {
      expenses = expenseData;
      repayments = repaymentData;
    });
  }

  String _categoryIcon(String category) {
    return ExpenseCategoryIcons.get(category);
  }

  Future<void> _renameGroup() async {
    final controller = TextEditingController(text: widget.groupName);

    final newName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Renommer le groupe'),
        content: TextField(
          controller: controller,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (newName == null || newName.trim().isEmpty) return;

    await GroupService().updateGroupName(
      widget.groupId,
      newName.trim(),
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _deleteGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer le groupe ?'),
        content: Text(
          'Cette action supprimera le groupe "${widget.groupName}".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await GroupService().deleteGroup(widget.groupId);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _addMember() async {
    final controller = TextEditingController();

    final email = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Inviter un ami'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'La personne recevra une invitation dans son application '
              'et devra l\'accepter pour rejoindre le groupe.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'email@gmail.com',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Inviter'),
          ),
        ],
      ),
    );

    if (email == null || email.trim().isEmpty) return;

    if (!mounted) return;

    try {
      await InvitationService().createInvitation(
        groupId: widget.groupId,
        groupName: widget.groupName,
        email: email.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invitation envoyée à ${email.trim()}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().contains('déjà en attente')
          ? 'Une invitation est déjà en attente pour cet email'
          : e.toString().contains('déjà partie du groupe')
              ? 'Cette personne fait déjà partie du groupe'
              : 'Erreur : $e';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawBalances = _debtService.calculateBalances(expenses);

    final balances = _debtService.applyRepayments(
      rawBalances,
      repayments,
    );

    final settlements =
        _debtService.calculateSettlements(balances);

    final totalAmount = expenses.fold<double>(
      0,
      (sum, e) => sum + e.amount,
    );

    final remainingToSettle = settlements.fold<double>(
      0,
      (sum, s) => sum + s.amount,
    );

    final totalRepaid = repayments.fold<double>(
      0,
      (sum, r) => sum + r.amount,
    );
    final sortedExpenses = [...expenses]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final sortedRepayments = [...repayments]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        toolbarHeight: 56,
        title: Text(
          widget.groupName,
          style: AppTextStyles.appBarTitle,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _addMember,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _renameGroup,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteGroup,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddExpenseScreen(
                groupId: widget.groupId,
                members: widget.members,
              ),
            ),
          );

          loadExpenses();
        },
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.padding),
        children: [
          AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.savings_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'TOTAL',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${totalAmount.toStringAsFixed(2)} €',
                        style: AppTextStyles.summaryAmount.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  height: 70,
                  width: 1,
                  color: AppColors.textSecondary.withValues(alpha: 0.25),
                ),

                Expanded(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.success,
                        size: 24,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'REMBOURSÉ',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${totalRepaid.toStringAsFixed(2)} €',
                        style: AppTextStyles.summaryAmount.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  height: 70,
                  width: 1,
                  color: AppColors.textSecondary.withValues(alpha: 0.25),
                ),

                Expanded(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.balance,
                        color: AppColors.warning,
                        size: 24,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'RESTE',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${remainingToSettle.toStringAsFixed(2)} €',
                        style: AppTextStyles.summaryAmount.copyWith(
                          color: remainingToSettle == 0
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          /*AppCard(
            child: Column(
              children: [
                const Text(
                  'TOTAL',
                  style: AppTextStyles.subtitle,
                ),
                Text(
                  '${totalAmount.toStringAsFixed(2)} €',
                  style: AppTextStyles.summaryAmount.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'REMBOURSÉ',
                  style: AppTextStyles.subtitle,
                ),
                Text(
                  '${totalRepaid.toStringAsFixed(2)} €',
                  style: AppTextStyles.summaryAmount.copyWith(
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'RESTE À ÉQUILIBRER',
                  style: AppTextStyles.subtitle,
                ),
                Text(
                  '${remainingToSettle.toStringAsFixed(2)} €',
                  style: AppTextStyles.summaryAmount.copyWith(
                    color: remainingToSettle == 0
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
              ],
            ),
          ),*/

          const AppSectionTitle('Balances'),

          ...balances.entries.map((entry) {
            final uid = entry.key;
            final amount = entry.value;

            return FutureBuilder<String>(
              future: _userService.getUserDisplayName(uid),
              builder: (context, snapshot) {
                final name = snapshot.data ?? '...';

                return AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  child: ListTile(
                    dense: true,
                    visualDensity: const VisualDensity(
                      vertical: -4,
                    ),
                    title: Text(
                      name,
                      style: AppTextStyles.title,
                    ),
                    trailing: Text(
                      '${amount.toStringAsFixed(2)} €',
                      style: AppTextStyles.amount.copyWith(
                        color: amount >= 0
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          const AppSectionTitle('Qui rembourse qui ?'),

          if (settlements.isEmpty)
            const AppCard(
              child: ListTile(
                title: Text('Tout est équilibré'),
              ),
            )
          else
            ...settlements.map((settlement) {
              return FutureBuilder<List<String>>(
                future: Future.wait([
                  _userService.getUserDisplayName(settlement.from),
                  _userService.getUserDisplayName(settlement.to),
                ]),
                builder: (context, snapshot) {
                  final fromName = snapshot.data?[0] ?? '...';
                  final toName = snapshot.data?[1] ?? '...';

                  return AppCard(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.swap_horiz,
                          color: AppColors.primary,
                          size: 24,
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$fromName → $toName',
                                style: AppTextStyles.title,
                              ),

                              const SizedBox(height: 4),

                             Row(
                              children: [
                                Text(
                                  '${settlement.amount.toStringAsFixed(2)} €',
                                  style: AppTextStyles.amount,
                                ),

                                const SizedBox(width: 12),

                                SizedBox(
                                  height: 28,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      await _repaymentService.addRepayment(
                                        widget.groupId,
                                        RepaymentModel(
                                          id: '',
                                          from: settlement.from,
                                          to: settlement.to,
                                          amount: settlement.amount,
                                          createdAt: DateTime.now(),
                                        ),
                                      );

                                      await loadExpenses();
                                    },
                                    icon: const Icon(Icons.payments, size: 12),
                                    label: const Text(
                                      'Rembourser',
                                      style: AppTextStyles.buttonSmall,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.secondary,
                                      foregroundColor: AppColors.textLight,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 0,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ),
                              ],
                            ), 
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),

          const AppSectionTitle('Remboursements effectués'),

          if (repayments.isEmpty)
            const AppCard(
              child: ListTile(
                dense: true,
                visualDensity: VisualDensity(
                  vertical: -4,
                ),
                title: Text('Aucun remboursement enregistré'),
              ),
            )
          else
            ...sortedRepayments.map((repayment) {
              return FutureBuilder<List<String>>(
                future: Future.wait([
                  _userService.getUserDisplayName(repayment.from),
                  _userService.getUserDisplayName(repayment.to),
                ]),
                builder: (context, snapshot) {
                  final fromName = snapshot.data?[0] ?? '...';
                  final toName = snapshot.data?[1] ?? '...';

                  final date =
                      '${repayment.createdAt.day.toString().padLeft(2, '0')}/'
                      '${repayment.createdAt.month.toString().padLeft(2, '0')}/'
                      '${repayment.createdAt.year} à '
                      '${repayment.createdAt.hour.toString().padLeft(2, '0')}:'
                      '${repayment.createdAt.minute.toString().padLeft(2, '0')}';
                  return AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const AppBadge(
                          text: 'Remboursé',
                          icon: Icons.check,
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$fromName → $toName',
                                style: AppTextStyles.title,
                              ),

                              const SizedBox(height: 4),

                              Text(
                                '${repayment.amount.toStringAsFixed(2)} € • $date',
                                style: AppTextStyles.subtitle,
                              ),
                            ],
                          ),
                        ),

                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: AppColors.danger,
                            size: 20,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Supprimer le remboursement ?'),
                                content: Text(
                                  'Supprimer ce remboursement de ${repayment.amount.toStringAsFixed(2)} € ?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Annuler'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Supprimer'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm != true) return;

                            await _repaymentService.deleteRepayment(
                              widget.groupId,
                              repayment.id,
                            );

                            await loadExpenses();
                          },
                        ),
                      ],
                    ),
                  );
                  /*return AppCard(
                    child: ListTile(
                      leading: const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                      ),
                      title: Text(
                        '$fromName a remboursé $toName',
                        style: AppTextStyles.title,
                      ),
                      subtitle: Text(
                        '${repayment.amount.toStringAsFixed(2)} € • $date',
                        style: AppTextStyles.subtitle,
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: AppColors.danger,
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text(
                                'Supprimer le remboursement ?',
                              ),
                              content: Text(
                                'Supprimer ce remboursement de ${repayment.amount.toStringAsFixed(2)} € ?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Annuler'),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: const Text('Supprimer'),
                                ),
                              ],
                            ),
                          );

                          if (confirm != true) return;

                          await _repaymentService.deleteRepayment(
                            widget.groupId,
                            repayment.id,
                          );

                          await loadExpenses();
                        },
                      ),
                    ),
                  );*/
                },
              );
            }),

          const AppSectionTitle('Dépenses'),

          ...sortedExpenses.map((expense) {
            return FutureBuilder<String>(
              future: _userService.getUserDisplayName(expense.paidBy),
              builder: (context, snapshot) {
                final payer = snapshot.data ?? '...';

                return AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditExpenseScreen(
                          groupId: widget.groupId,
                          expense: expense,
                          members: widget.members,
                        ),
                      ),
                    );

                    loadExpenses();
                  },
                  child: ListTile(
                    dense: true,
                    visualDensity: const VisualDensity(vertical: -4),
                    contentPadding: EdgeInsets.zero,
                    leading: Text(
                      _categoryIcon(expense.category),
                      style: AppTextStyles.categoryIcon,
                    ),
                    title: Text(
                      expense.title,
                      style: AppTextStyles.title,
                    ),
                    subtitle: Text(
                      '${expense.category} • Payé par $payer',
                      style: AppTextStyles.subtitle,
                    ),
                    trailing: Text(
                      '${expense.amount.toStringAsFixed(2)} €',
                      style: AppTextStyles.amount.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}