import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/repayment_model.dart';

class RepaymentService {
  final SupabaseClient _db = Supabase.instance.client;

  Future<void> addRepayment(
    String groupId,
    RepaymentModel repayment,
  ) async {
    await _db.from('repayments').insert({
      'group_id': groupId,
      ...repayment.toMap(),
    });
  }

  Future<List<RepaymentModel>> getRepayments(
    String groupId,
  ) async {
    final rows = await _db
        .from('repayments')
        .select()
        .eq('group_id', groupId);

    return rows
        .map((row) => RepaymentModel.fromMap(row, row['id'] as String))
        .toList();
  }

  Future<void> deleteRepayment(
    String groupId,
    String repaymentId,
  ) async {
    await _db.from('repayments').delete().eq('id', repaymentId);
  }
}
