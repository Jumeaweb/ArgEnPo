import 'package:flutter/material.dart';

import '../models/expense_model.dart';
import '../services/expense_service.dart';

import '../theme/theme.dart';
import '../constants/constants.dart';
import '../widgets/widgets.dart';

class EditExpenseScreen extends StatefulWidget {
  final String groupId;
  final ExpenseModel expense;

  const EditExpenseScreen({
    super.key,
    required this.groupId,
    required this.expense,
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
  }

  Future<void> save() async {
    final amountText = amountController.text.replaceAll(',', '.');
    final amount = double.tryParse(amountText);

    if (titleController.text.trim().isEmpty || amount == null) {
      _showMessage('Titre ou montant invalide');
      return;
    }

    final updatedExpense = ExpenseModel(
      id: widget.expense.id,
      title: titleController.text.trim(),
      amount: amount,
      paidBy: widget.expense.paidBy,
      participants: widget.expense.participants,
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