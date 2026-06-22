import '../models/expense_model.dart';
import '../models/repayment_model.dart';

class Settlement {
  final String from;
  final String to;
  final double amount;

  Settlement({
    required this.from,
    required this.to,
    required this.amount,
  });
}

class DebtService {
  Map<String, double> calculateBalances(List<ExpenseModel> expenses) {
    final Map<String, double> balance = {};

    for (final e in expenses) {
      if (e.participants.isEmpty) continue;

      final share = e.amount / e.participants.length;

      for (final uid in e.participants) {
        balance[uid] = (balance[uid] ?? 0) - share;
      }

      balance[e.paidBy] = (balance[e.paidBy] ?? 0) + e.amount;
    }

    return balance;
  }

  Map<String, double> applyRepayments(
  Map<String, double> balances,
  List<RepaymentModel> repayments,
) {
  final updated = Map<String, double>.from(balances);

  for (final r in repayments) {
    updated[r.from] = (updated[r.from] ?? 0) + r.amount;
    updated[r.to] = (updated[r.to] ?? 0) - r.amount;
  }

  return updated;
}

  List<Settlement> calculateSettlements(
    Map<String, double> balances,
  ) {
    final debtors = <MapEntry<String, double>>[];
    final creditors = <MapEntry<String, double>>[];

    final settlements = <Settlement>[];

    balances.forEach((uid, amount) {
      final rounded = double.parse(amount.toStringAsFixed(2));

      if (rounded < 0) {
        debtors.add(MapEntry(uid, -rounded));
      } else if (rounded > 0) {
        creditors.add(MapEntry(uid, rounded));
      }
    });

    int i = 0;
    int j = 0;

    while (i < debtors.length && j < creditors.length) {
      final debtor = debtors[i];
      final creditor = creditors[j];

      final amount = debtor.value < creditor.value
          ? debtor.value
          : creditor.value;

      settlements.add(
        Settlement(
          from: debtor.key,
          to: creditor.key,
          amount: double.parse(amount.toStringAsFixed(2)),
        ),
      );

      debtors[i] = MapEntry(
        debtor.key,
        double.parse((debtor.value - amount).toStringAsFixed(2)),
      );

      creditors[j] = MapEntry(
        creditor.key,
        double.parse((creditor.value - amount).toStringAsFixed(2)),
      );

      if (debtors[i].value <= 0) i++;
      if (creditors[j].value <= 0) j++;
    }

    return settlements;
  }
}