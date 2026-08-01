class TransactionModel {
  final int? id;
  final double amount;
  final String merchant;
  final DateTime timestamp;
  final String type; // 'CREDIT' or 'DEBIT'
  final int categoryId;
  final bool isCategorized;
  final String smsBody;
  final String? accountNumber;
  final double? balance;
  final String? referenceId;
  final String source; // 'SMS' or 'MANUAL'
  final String? smsHash;
  final String? note; // New field
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionModel({
    this.id,
    required this.amount,
    required this.merchant,
    required this.timestamp,
    required this.type,
    required this.categoryId,
    this.isCategorized = false,
    required this.smsBody,
    this.accountNumber,
    this.balance,
    this.referenceId,
    this.source = 'MANUAL',
    this.smsHash,
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'merchant': merchant,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'category_id': categoryId,
      'is_categorized': isCategorized ? 1 : 0,
      'sms_body': smsBody,
      'account_number': accountNumber,
      'balance': balance,
      'reference_id': referenceId,
      'source': source,
      'sms_hash': smsHash,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      amount: map['amount'],
      merchant: map['merchant'],
      timestamp: DateTime.parse(map['timestamp']),
      type: map['type'],
      categoryId: map['category_id'] ?? 6, // Default to 'Other' ID if null
      isCategorized: map['is_categorized'] == 1,
      smsBody: map['sms_body'],
      accountNumber: map['account_number'],
      balance: map['balance'],
      referenceId: map['reference_id'],
      source: map['source'],
      smsHash: map['sms_hash'],
      note: map['note'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  TransactionModel copyWith({
    int? id,
    double? amount,
    String? merchant,
    DateTime? timestamp,
    String? type,
    int? categoryId,
    bool? isCategorized,
    String? smsBody,
    String? accountNumber,
    double? balance,
    String? referenceId,
    String? source,
    String? smsHash,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      isCategorized: isCategorized ?? this.isCategorized,
      smsBody: smsBody ?? this.smsBody,
      accountNumber: accountNumber ?? this.accountNumber,
      balance: balance ?? this.balance,
      referenceId: referenceId ?? this.referenceId,
      source: source ?? this.source,
      smsHash: smsHash ?? this.smsHash,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
