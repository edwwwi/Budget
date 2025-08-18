import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  TransactionType type;

  @HiveField(3)
  String category;

  @HiveField(4)
  String description;

  @HiveField(5)
  DateTime date;

  @HiveField(6)
  double balance;

  @HiveField(7)
  String bankName;

  @HiveField(8)
  bool isCategorized;

  @HiveField(9)
  String? smsBody;

  Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.date,
    required this.balance,
    required this.bankName,
    this.isCategorized = false,
    this.smsBody,
  });

  Transaction copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    String? category,
    String? description,
    DateTime? date,
    double? balance,
    String? bankName,
    bool? isCategorized,
    String? smsBody,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      balance: balance ?? this.balance,
      bankName: bankName ?? this.bankName,
      isCategorized: isCategorized ?? this.isCategorized,
      smsBody: smsBody ?? this.smsBody,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'type': type.index,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'balance': balance,
      'bankName': bankName,
      'isCategorized': isCategorized,
      'smsBody': smsBody,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      amount: json['amount'].toDouble(),
      type: TransactionType.values[json['type']],
      category: json['category'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      balance: json['balance'].toDouble(),
      bankName: json['bankName'],
      isCategorized: json['isCategorized'] ?? false,
      smsBody: json['smsBody'],
    );
  }
}

@HiveType(typeId: 1)
enum TransactionType {
  @HiveField(0)
  credit,
  @HiveField(1)
  debit,
}
