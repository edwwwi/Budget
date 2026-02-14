import '../data/models/transaction_model.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class SmsParser {
  // Regex for Federal Bank
  // Example: Your Ac XXXXXX1234 is debited with INR 500.00 on 12-Feb-25. Info: UPI/12345/MerchantName. Bal: INR 10000.00
  static final RegExp _amountRegex = RegExp(
      r'(?:INR|Rs\.?)\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
      caseSensitive: false);
  static final RegExp _accountRegex =
      RegExp(r'Ac\s+[X\d]*(\d{4})', caseSensitive: false);
  static final RegExp _merchantRegex = RegExp(r'Info:\s*(.*?)(?:\.|Bal|$)');
  static final RegExp _balanceRegex = RegExp(
      r'Bal:?\s*(?:INR|Rs\.?)\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
      caseSensitive: false);

  static TransactionModel? parse(String? body, int? timestamp) {
    if (body == null) return null;

    // Detect Transaction Type
    String type = 'DEBIT';
    if (body.toLowerCase().contains('credited')) {
      type = 'CREDIT';
    } else if (!body.toLowerCase().contains('debited')) {
      // If neither credited nor debited, might be an alert, ignore for now or log
      // But typical transactional SMS contains these words.
      // Strict filter: return null if not transactional
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
        merchant = parts.last; // Try to get the last part or the 3rd part
      }
    } else if (merchant.startsWith('NEFT') || merchant.startsWith('IMPS')) {
      // Keep as is or refine
    }

    // Extract Balance
    final balanceMatch = _balanceRegex.firstMatch(body);
    double? balance = balanceMatch != null
        ? double.parse(balanceMatch.group(1)!.replaceAll(',', ''))
        : null;

    // Generate Hash for deduplication
    // Concatenate important fields and hash
    String raw =
        '${amount}_${type}_${accountNumber}_${timestamp ?? DateTime.now().millisecondsSinceEpoch}';
    var bytes = utf8.encode(raw);
    String hash = sha256.convert(bytes).toString();

    return TransactionModel(
      amount: amount,
      merchant: merchant,
      timestamp:
          DateTime.now(), // Use current time of receipt, or parse date from SMS
      type: type,
      smsBody: body,
      accountNumber: accountNumber,
      balance: balance,
      source: 'SMS',
      smsHash: hash,
    );
  }
}
