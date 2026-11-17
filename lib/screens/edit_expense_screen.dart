import 'package:flutter/material.dart';

import '../models/expense_model.dart';
import '../services/expense_service.dart';
import '../services/user_service.dart';

import '../theme/theme.dart';
import '../constants/constants.dart';
import '../widgets/widgets.dart';

class EditExpenseScreen extends StatefulWidget {
  final String groupId;
  final ExpenseModel expense;
  final List<String> members;

  const EditExpenseScreen({
    super.key,
    required this.groupId,
    required this.expense,
    this.members = const [],
  });

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  late TextEditingController titleController;
  late TextEditingController amountController;

  final ExpenseService _expenseService = ExpenseService();

  late String selectedCategory;

  final List<String> categories =
      List.from(ExpenseCategories.all);

  final UserService _userService = UserService();

  late List<String> selectedParticipants;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(
      text: widget.expense.title,
    );

    amountController = TextEditingController(
      text: widget.expense.amount.toString(),
    );

    selectedCategory = categories.contains(widget.expense.category)
        ? widget.expense.category
        : 'Autre';

    selectedParticipants = List.from(widget.expense.participants);
  }

  void toggleParticipant(String uid, bool? value) {
    setState(() {
      if (value == true) {
        if (!selectedParticipants.contains(uid)) {
          selectedParticipants.add(uid);
        }
      } else {
        selectedParticipants.remove(uid);
      }
    });
  }

  Future<void> save() async {
    final amountText = amountController.text.replaceAll(',', '.');
    final amount = double.tryParse(amountText);

    if (titleController.text.trim().isEmpty || amount == null) {
      _showMessage('Titre ou montant invalide');
      return;
    }

    if (selectedParticipants.isEmpty) {
      _showMessage('Sélectionne au moins un participant');
      return;
    }

    final updatedExpense = ExpenseModel(
      id: widget.expense.id,
      title: titleController.text.trim(),
      amount: amount,
      paidBy: widget.expense.paidBy,
      participants: selectedParticipants,
      category: selectedCategory,
      createdAt: widget.expense.createdAt,
    );

    await _expenseService.updateExpense(
      widget.groupId,
      updatedExpense,
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> deleteExpense() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer la dépense ?'),
        content: Text(
          'Supprimer "${widget.expense.title}" ?',
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

    await _expenseService.deleteExpense(
      widget.groupId,
      widget.expense.id,
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        title: const Text(
          'Modifier dépense',
          style: AppTextStyles.appBarTitle,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.padding),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSectionTitle('Informations'),

                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titre',
                    prefixIcon: Icon(Icons.receipt_long),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Montant',
                    prefixIcon: Icon(Icons.euro),
                  ),
                ),

                const SizedBox(height: 20),

                const AppSectionTitle('Catégorie'),

                DropdownButton<String>(
                  value: selectedCategory,
                  isExpanded: true,
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                ),

                const SizedBox(height: 24),

                const AppSectionTitle('Participants'),

                FutureBuilder<List<Map<String, String>>>(
                  future: Future.wait(
                    widget.members.map((uid) async {
                      final name =
                          await _userService.getUserDisplayName(uid);

                      return {
                        'uid': uid,
                        'name': name,
                      };
                    }),
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: Padding(
                          padding:
                              EdgeInsets.all(AppDimensions.paddingLarge),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    return Column(
                      children: snapshot.data!.map((member) {
                        final uid = member['uid']!;
                        final name = member['name']!;

                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: selectedParticipants.contains(uid),
                          title: Text(
                            name,
                            style: AppTextStyles.subtitle,
                          ),
                          onChanged: (value) =>
                              toggleParticipant(uid, value),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 24),

                AppButton(
                  text: 'Enregistrer',
                  icon: Icons.save,
                  onPressed: save,
                ),

                const SizedBox(height: 12),

                AppButton(
                  text: 'Supprimer',
                  icon: Icons.delete,
                  backgroundColor: AppColors.danger,
                  onPressed: deleteExpense,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}