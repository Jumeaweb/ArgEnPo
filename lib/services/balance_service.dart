class BalanceService {
  /// expenses format:
  /// {
  ///   paidBy: userId,
  ///   amount: total,
  ///   splits: { userId: amount }
  /// }

  Map<String, double> calculateBalances(List<Map<String, dynamic>> expenses) {
    final Map<String, double> balances = {};

    for (final expense in expenses) {
      final String paidBy = expense['paidBy'];
      final double amount = expense['amount'];
      final Map<String, dynamic> splits = expense['splits'];

      // 👤 init payer
      balances.putIfAbsent(paidBy, () => 0);
      balances[paidBy] = balances[paidBy]! + amount;

      // 👥 subtract shares
      splits.forEach((userId, value) {
        balances.putIfAbsent(userId, () => 0);
        balances[userId] = balances[userId]! - (value as num).toDouble();
      });
    }

    return balances;
  }
}

class Settlement {
  final String from;
  final String to;
  final double amount;

  Settlement(this.from, this.to, this.amount);
}

List<Settlement> optimizeDebts(Map<String, double> balances) {
  final creditors = <MapEntry<String, double>>[];
  final debtors = <MapEntry<String, double>>[];

  balances.forEach((user, amount) {
    if (amount > 0) {
      creditors.add(MapEntry(user, amount));
    } else if (amount < 0) {
      debtors.add(MapEntry(user, amount));
    }
  });

  creditors.sort((a, b) => b.value.compareTo(a.value));
  debtors.sort((a, b) => a.value.compareTo(b.value));

  final settlements = <Settlement>[];

  int i = 0, j = 0;

  while (i < debtors.length && j < creditors.length) {
    final debtor = debtors[i];
    final creditor = creditors[j];

    final debt = debtor.value.abs();
    final credit = creditor.value;

    final payment = debt < credit ? debt : credit;

    settlements.add(
      Settlement(debtor.key, creditor.key, payment),
    );

    debtors[i] = MapEntry(debtor.key, debtor.value + payment);
    creditors[j] = MapEntry(creditor.key, creditor.value - payment);

    if (debtors[i].value == 0) i++;
    if (creditors[j].value == 0) j++;
  }

  return settlements;
}

