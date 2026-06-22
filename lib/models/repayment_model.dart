class RepaymentModel {
  final String id;
  final String from;
  final String to;
  final double amount;
  final DateTime createdAt;

  RepaymentModel({
    required this.id,
    required this.from,
    required this.to,
    required this.amount,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'from': from,
      'to': to,
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RepaymentModel.fromMap(
    Map<String, dynamic> map,
    String id,
  ) {
    return RepaymentModel(
      id: id,
      from: map['from'],
      to: map['to'],
      amount: (map['amount'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}