import 'package:equatable/equatable.dart';

enum TransactionCategory { food, petrol, entertainment, other }

enum TransactionType { credit, debit }

class Transaction extends Equatable {
  final int? id;
  final double amount;
  final TransactionCategory category;
  final String merchant;
  final TransactionType type;
  final DateTime timestamp;
  final int? smsId;

  const Transaction({
    this.id,
    required this.amount,
    required this.category,
    required this.merchant,
    required this.type,
    required this.timestamp,
    this.smsId,
  });

  @override
  List<Object?> get props => [
    id,
    amount,
    category,
    merchant,
    type,
    timestamp,
    smsId,
  ];
}
