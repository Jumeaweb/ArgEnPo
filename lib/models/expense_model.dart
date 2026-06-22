class ExpenseModel {
  final String id;
  final String title;
  final double amount;
  final String paidBy;
  final List<String> participants;
  final DateTime createdAt;
  final String category;

  ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.participants,
    required this.createdAt,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'paidBy': paidBy,
      'participants': participants,
      'createdAt': createdAt.toIso8601String(),
      'category': category,
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map, String id) {
    return ExpenseModel(
      id: id,
      title: map['title'],
      amount: (map['amount'] as num).toDouble(),
      paidBy: map['paidBy'],
      participants: List<String>.from(map['participants']),
      createdAt: DateTime.parse(map['createdAt']),
      category: map['category'] ?? 'Autre',
    );
  }
}