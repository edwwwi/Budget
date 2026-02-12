import 'transaction_type.dart';
import 'transaction_category.dart';

class TransactionModel {
  final int? id;
  final double amount;
  final TransactionCategory category;
  final String merchant;
  final TransactionType type;
  final DateTime timestamp;

  TransactionModel({
    this.id,
    required this.amount,
    required this.category,
    required this.merchant,
    required this.type,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category.index,
      'merchant': merchant,
      'type': type.index,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      amount: map['amount'],
      category: TransactionCategory.values[map['category']],
      merchant: map['merchant'],
      type: TransactionType.values[map['type']],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
