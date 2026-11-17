import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/expense_model.dart';

class ExpenseService {
  final SupabaseClient _db = Supabase.instance.client;

  Future<void> addExpense(
    String groupId,
    ExpenseModel expense,
  ) async {
    await _db.from('expenses').insert({
      'group_id': groupId,
      ...expense.toMap(),
    });
  }

  Future<void> updateExpense(
    String groupId,
    ExpenseModel expense,
  ) async {
    await _db
        .from('expenses')
        .update({
          'group_id': groupId,
          ...expense.toMap(),
        })
        .eq('id', expense.id);
  }

  Future<void> deleteExpense(
    String groupId,
    String expenseId,
  ) async {
    await _db.from('expenses').delete().eq('id', expenseId);
  }

  Future<List<ExpenseModel>> getExpenses(
    String groupId,
  ) async {
    final rows = await _db
        .from('expenses')
        .select()
        .eq('group_id', groupId);

    return rows
        .map((row) => ExpenseModel.fromMap(row, row['id'] as String))
        .toList();
  }

  Future<int> getExpenseCount(String groupId) async {
    final response = await _db
        .from('expenses')
        .select('id')
        .eq('group_id', groupId)
        .count();

    return response.count;
  }

  Future<double> getTotalAmount(String groupId) async {
    final rows = await _db
        .from('expenses')
        .select('amount')
        .eq('group_id', groupId);

    double total = 0;

    for (final row in rows) {
      total += (row['amount'] as num?)?.toDouble() ?? 0;
    }

    return total;
  }
}
