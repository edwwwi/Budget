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
      RegExp(r'(?:Ac|A/c)\s+[*xX\-\d]*(\d{4})', caseSensitive: false);

  static final RegExp _merchantRegex = RegExp(
      r'(?:Info:|\bto\b)\s*(.*?)(?:\.|Ref:|Bal|\n|On|$)',
      caseSensitive: false);

  static final RegExp _balanceRegex = RegExp(
      r'(?:Bal|Balance)[:\-]?\s*(?:INR|Rs\.?)\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
      caseSensitive: false);

  static TransactionModel? parse(String? body, int? timestamp) {
    if (body == null) return null;

    final lowerBody = body.toLowerCase();

    // Explicitly ignore credit/income keywords
    if (lowerBody.contains('credited') || 
        lowerBody.contains('refund') || 
        lowerBody.contains('cashback') || 
        lowerBody.contains('received') ||
        lowerBody.contains('salary') ||
        lowerBody.contains('deposit') ||
        lowerBody.contains('reversal')) {
      return null;
    }

    // Explicitly ignore OTP and verification messages
    if (lowerBody.contains('otp') ||
        lowerBody.contains('one time password') ||
        lowerBody.contains('verification code') ||
        lowerBody.contains('do not share') ||
        lowerBody.contains('login')) {
      return null;
    }

    // Detect Transaction Type
    bool isDebit = lowerBody.contains('debited') ||
        lowerBody.contains('spent') ||
        lowerBody.contains('paid') ||
        lowerBody.contains('purchase') ||
        lowerBody.contains('pos transaction') ||
        lowerBody.contains('upi payment') ||
        lowerBody.contains('bill payment') ||
        lowerBody.contains('withdrawal') ||
        lowerBody.contains('payment made') ||
        lowerBody.contains('transaction at merchant') ||
        lowerBody.contains('online purchase') ||
        lowerBody.contains('sent');

    if (!isDebit) {
      return null;
    }
    String type = 'DEBIT';

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
      List<String> parts = merchant.split('/');
      if (parts.length > 2) {
        merchant = parts.last;
      }
    } else if (merchant.toLowerCase().contains('your a/c')) {
      merchant = 'Unknown';
    } else if (RegExp(r'^\d{10}').hasMatch(merchant)) {
      merchant = 'Unknown';
    }

    // Smart Auto-Categorization
    int categoryId = 6; // Default to Other
    bool isCategorized = false;
    final lowerMerchant = merchant.toLowerCase();

    if (lowerMerchant.contains('swiggy') || lowerMerchant.contains('zomato')) {
      categoryId = 1; // Food
      isCategorized = true;
    } else if (lowerMerchant.contains('indian oil') || lowerMerchant.contains('hpcl') || lowerMerchant.contains('petrol')) {
      categoryId = 2; // Petrol
      isCategorized = true;
    } else if (lowerMerchant.contains('bookmyshow') || lowerMerchant.contains('movie')) {
      categoryId = 4; // Entertainment
      isCategorized = true;
    } else if (lowerMerchant.contains('irctc') || lowerMerchant.contains('uber') || lowerMerchant.contains('ola') || lowerMerchant.contains('ticket')) {
      categoryId = 3; // Travel
      isCategorized = true;
    } else if (lowerMerchant.contains('electricity') || lowerMerchant.contains('asianet') || lowerMerchant.contains('jio fiber') || lowerMerchant.contains('rent') || lowerMerchant.contains('broadband') || lowerMerchant.contains('water bill')) {
      categoryId = 5; // Maintenance
      isCategorized = true;
    }

    // Extract Balance
    final balanceMatch = _balanceRegex.firstMatch(body);
    double? balance = balanceMatch != null
        ? double.parse(balanceMatch.group(1)!.replaceAll(',', ''))
        : null;

    // Generate Hash for deduplication
    String raw = '${amount}_${type}_${accountNumber}_${timestamp ?? DateTime.now().millisecondsSinceEpoch}';
    var bytes = utf8.encode(raw);
    String hash = sha256.convert(bytes).toString();

    return TransactionModel(
      amount: amount,
      merchant: merchant,
      timestamp: DateTime.now(),
      type: type,
      categoryId: categoryId,
      isCategorized: isCategorized,
      smsBody: body,
      accountNumber: accountNumber,
      balance: balance,
      source: 'SMS',
      smsHash: hash,
    );
  }
}
