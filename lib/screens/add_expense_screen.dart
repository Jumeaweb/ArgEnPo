import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/expense_model.dart';
import '../services/expense_service.dart';
import '../services/user_service.dart';

import '../theme/theme.dart';
import '../constants/constants.dart';
import '../widgets/widgets.dart';

class AddExpenseScreen extends StatefulWidget {
  final String groupId;
  final List<String> members;

  const AddExpenseScreen({
    super.key,
    required this.groupId,
    required this.members,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final titleController = TextEditingController();
  final amountController = TextEditingController();

  final ExpenseService _service = ExpenseService();
  final UserService _userService = UserService();

  String? selectedPayer;
  List<String> selectedParticipants = [];

  String selectedCategory = 'Autre';

  final List<String> categories =
      List.from(ExpenseCategories.all);

  @override
  void initState() {
    super.initState();

    if (widget.members.isNotEmpty) {
      selectedPayer = widget.members.first;
    }

    selectedParticipants = List.from(widget.members);
  }

  Future<void> save() async {
    final user = FirebaseAuth.instance.currentUser!;

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

    final expense = ExpenseModel(
      id: '',
      title: titleController.text.trim(),
      amount: amount,
      paidBy: selectedPayer ?? user.uid,
      participants: selectedParticipants,
      category: selectedCategory,
      createdAt: DateTime.now(),
    );

    await _service.addExpense(widget.groupId, expense);

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
          'Ajouter dépense',
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

                const SizedBox(height: 20),

                const AppSectionTitle('Payé par'),

                FutureBuilder<List<DropdownMenuItem<String>>>(
                  future: Future.wait(
                    widget.members.map((uid) async {
                      final name =
                          await _userService.getUserDisplayName(uid);

                      return DropdownMenuItem<String>(
                        value: uid,
                        child: Text(name),
                      );
                    }),
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    return DropdownButton<String>(
                      value: selectedPayer,
                      isExpanded: true,
                      items: snapshot.data!,
                      onChanged: (value) {
                        setState(() {
                          selectedPayer = value;
                        });
                      },
                    );
                  },
                ),

                const SizedBox(height: 20),

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
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final members = snapshot.data!;

                    return Column(
                      children: members.map((member) {
                        final uid = member['uid']!;
                        final name = member['name']!;

                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: selectedParticipants.contains(uid),
                          title: Text(
                            name,
                            style: AppTextStyles.subtitle,
                          ),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                if (!selectedParticipants.contains(uid)) {
                                  selectedParticipants.add(uid);
                                }
                              } else {
                                selectedParticipants.remove(uid);
                              }
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 20),

                AppButton(
                  text: 'Ajouter',
                  icon: Icons.add,
                  onPressed: save,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}