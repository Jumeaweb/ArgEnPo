import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String groupId;
  final String title;
  final double amount;
  final String paidBy;
  final List<String> participants;
  final String category;
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.groupId,
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.participants,
    required this.category,
    required this.createdAt,
  });

  List<String> get sharedWith => participants;

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'title': title,
      'amount': amount,
      'paidBy': paidBy,
      'participants': participants,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> data, String id) {
    return ExpenseModel(
      id: id,
      groupId: data['groupId'] ?? '',
      title: data['title'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      paidBy: data['paidBy'] ?? '',
      participants: List<String>.from(
        data['participants'] ?? data['sharedWith'] ?? [],
      ),
      category: data['category'] ?? 'Autre',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExpenseModel.fromMap(data, doc.id);
  }
}