import '../data/models/transaction_model.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class SmsParser {
  // Regex for Federal Bank
  // Example: Your Ac XXXXXX1234 is debited with INR 500.00 on 12-Feb-25. Info: UPI/12345/MerchantName. Bal: INR 10000.00
  // Example 2: Rs 35.00 sent via UPI... to ATHUL T A.Ref:...
  // Example 3: ...credited to your A/c... BAL-Rs.649...

  static final RegExp _amountRegex = RegExp(
      r'(?:INR|Rs\.?)\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
      caseSensitive: false);

  static final RegExp _accountRegex =
      RegExp(r'(?:Ac|A/c)\s+[X\d]*(\d{4})', caseSensitive: false);

  static final RegExp _merchantRegex = RegExp(
      r'(?:Info:|\bto\b)\s*(.*?)(?:\.|Ref:|Bal|$)',
      caseSensitive: false);

  static final RegExp _balanceRegex = RegExp(
      r'(?:Bal|Balance)[:\-]?\s*(?:INR|Rs\.?)\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
      caseSensitive: false);

  static TransactionModel? parse(String? body, int? timestamp) {
    if (body == null) return null;

    // Detect Transaction Type
    String type = 'DEBIT';
    final lowerBody = body.toLowerCase();
    if (lowerBody.contains('credited')) {
      type = 'CREDIT';
    } else if (lowerBody.contains('debited') ||
        lowerBody.contains('sent') ||
        lowerBody.contains('spent')) {
      type = 'DEBIT';
    } else {
      // Return null if not a recognized transaction type
      return null;
    }

    // Extract Amount
    final amountMatch = _amountRegex.firstMatch(body);
    if (amountMatch == null) return null;
    double amount = double.parse(amountMatch.group(1)!.replaceAll(',', ''));

    // Extract Account
    final accountMatch = _accountRegex.firstMatch(body);
    String? accountNumber = accountMatch?.group(1);

    // Extract Merchant/Info
    final merchantMatch = _merchantRegex.firstMatch(body);
    String merchant = merchantMatch?.group(1)?.trim() ?? 'Unknown';

    // Cleanup Merchant string
    if (merchant.startsWith('UPI/')) {
      // Typical UPI: UPI/ID/MERCHANT -> extract merchant
      List<String> parts = merchant.split('/');
      if (parts.length > 2) {
        merchant = parts.last;
      }
    } else if (merchant.toLowerCase().contains('your a/c')) {
      // "credited to your A/c" -> "your A/c" captured by 'to'
      merchant = 'Unknown';
    }

    // Extract Balance
    final balanceMatch = _balanceRegex.firstMatch(body);
    double? balance = balanceMatch != null
        ? double.parse(balanceMatch.group(1)!.replaceAll(',', ''))
        : null;

    // Generate Hash for deduplication
    String raw =
        '${amount}_${type}_${accountNumber}_${timestamp ?? DateTime.now().millisecondsSinceEpoch}';
    var bytes = utf8.encode(raw);
    String hash = sha256.convert(bytes).toString();

    return TransactionModel(
      amount: amount,
      merchant: merchant,
      timestamp: DateTime.now(),
      type: type,
      smsBody: body,
      accountNumber: accountNumber,
      balance: balance,
      source: 'SMS',
      smsHash: hash,
    );
  }
}
