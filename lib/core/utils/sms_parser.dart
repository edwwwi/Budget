import '../../models/transaction_model.dart';
import '../../models/transaction_type.dart';
import '../../models/transaction_category.dart';

class SmsParser {
  // Sample: "Rs 600.00 sent via UPI on 11-02-2026 at 16:58:50 to JXXL MAXU JXXXP."
  static final RegExp _federalBankRegex = RegExp(
    r'Rs\s+(\d+\.?\d*)\s+(sent|received|debited|credited)\s+via\s+.*\s+to\s+(.*)\.',
    caseSensitive: false,
  );

  static TransactionModel? parseFederalBankSms(String body) {
    final match = _federalBankRegex.firstMatch(body);
    if (match == null) return null;

    double amount = double.tryParse(match.group(1) ?? '0') ?? 0;
    String typeStr = match.group(2)?.toLowerCase() ?? '';
    String recipient = match.group(3)?.trim() ?? 'Unknown';

    TransactionType type = (typeStr == 'sent' || typeStr == 'debited')
        ? TransactionType.debit
        : TransactionType.credit;

    return TransactionModel(
      amount: amount,
      category: TransactionCategory.other, // Default until user selects
      merchant: recipient,
      type: type,
      timestamp: DateTime.now(),
    );
  }
}
