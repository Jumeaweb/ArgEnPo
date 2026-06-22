import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addExpense(
    String groupId,
    ExpenseModel expense,
  ) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .add(expense.toMap());
  }

  Future<void> updateExpense(
    String groupId,
    ExpenseModel expense,
  ) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .doc(expense.id)
        .update(expense.toMap());
  }

  Future<void> deleteExpense(
    String groupId,
    String expenseId,
  ) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .doc(expenseId)
        .delete();
  }

  Future<List<ExpenseModel>> getExpenses(
    String groupId,
  ) async {
    final snapshot = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .get();

    return snapshot.docs
        .map((doc) => ExpenseModel.fromMap(
              doc.data(),
              doc.id,
            ))
        .toList();
  }
  Future<int> getExpenseCount(String groupId) async {
  final snapshot = await _firestore
      .collection('groups')
      .doc(groupId)
      .collection('expenses')
      .get();

  return snapshot.docs.length;
}

  Future<double> getTotalAmount(String groupId) async {
    final snapshot = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .get();

    double total = 0;

    for (final doc in snapshot.docs) {
      final amount =
          (doc.data()['amount'] as num?)?.toDouble() ?? 0;

      total += amount;
    }

    return total;
  }
  
}