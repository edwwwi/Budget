import 'package:budgify/domain/entities/transaction.dart';

class RegexEngine {
  // Pattern for Federal Bank: Rs 600.00 sent via UPI on 11-02-2026 at 16:58:50 to JXXL MAXU JXXXP.
  static final RegExp _federalBankPattern = RegExp(
    r'Rs\s?([\d,]+\.?\d*)\s+(sent|received|debited|credited)\s+via\s+UPI\s+on\s+[\d-]+\s+at\s+[\d:]+\s+to\s+(.+)\.',
    caseSensitive: false,
  );

  static Map<String, dynamic>? parseSms(String body) {
    final match = _federalBankPattern.firstMatch(body);
    if (match != null) {
      final amountStr = match.group(1)?.replaceAll(',', '') ?? '0.0';
      final typeStr = match.group(2)?.toLowerCase() ?? '';
      final recipient = match.group(3)?.trim() ?? 'Unknown';

      TransactionType type;
      if (typeStr == 'sent' || typeStr == 'debited') {
        type = TransactionType.debit;
      } else {
        type = TransactionType.credit;
      }

      return {
        'amount': double.tryParse(amountStr) ?? 0.0,
        'type': type,
        'merchant': recipient,
      };
    }
    return null;
  }
}
