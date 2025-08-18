import 'package:hive/hive.dart';

part 'budget.g.dart';

@HiveType(typeId: 2)
class Budget extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  int year;

  @HiveField(3)
  int month;

  @HiveField(4)
  double spent;

  @HiveField(5)
  DateTime createdAt;

  Budget({
    required this.id,
    required this.amount,
    required this.year,
    required this.month,
    this.spent = 0.0,
    required this.createdAt,
  });

  double get remaining => amount - spent;
  double get progressPercentage => (spent / amount) * 100;
  bool get isOverBudget => spent > amount;

  Budget copyWith({
    String? id,
    double? amount,
    int? year,
    int? month,
    double? spent,
    DateTime? createdAt,
  }) {
    return Budget(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      year: year ?? this.year,
      month: month ?? this.month,
      spent: spent ?? this.spent,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'year': year,
      'month': month,
      'spent': spent,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      amount: json['amount'].toDouble(),
      year: json['year'],
      month: json['month'],
      spent: json['spent'].toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
