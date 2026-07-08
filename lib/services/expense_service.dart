import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense_model.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addExpense(dynamic groupIdOrExpense, [ExpenseModel? expense]) async {
    final ExpenseModel finalExpense =
        expense ?? groupIdOrExpense as ExpenseModel;

    await _firestore
        .collection('groups')
        .doc(finalExpense.groupId)
        .collection('expenses')
        .add(finalExpense.toMap());
  }

  Future<void> updateExpense(
    dynamic groupIdOrExpense, [
    ExpenseModel? expense,
  ]) async {
    final ExpenseModel finalExpense =
        expense ?? groupIdOrExpense as ExpenseModel;

    await _firestore
        .collection('groups')
        .doc(finalExpense.groupId)
        .collection('expenses')
        .doc(finalExpense.id)
        .update(finalExpense.toMap());
  }

  Future<void> deleteExpense(String groupId, String expenseId) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .doc(expenseId)
        .delete();
  }

  Stream<List<ExpenseModel>> watchExpenses(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<List<ExpenseModel>> getExpenses(String groupId) async {
    final snapshot = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<int> getExpenseCount(String groupId) async {
    final expenses = await getExpenses(groupId);
    return expenses.length;
  }

  Future<double> getTotalAmount(String groupId) async {
    final expenses = await getExpenses(groupId);

    return expenses.fold<double>(
      0,
      (total, expense) => total + expense.amount,
    );
  }
}