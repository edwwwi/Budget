import 'package:budgify/core/regex_engine.dart';
import 'package:budgify/domain/entities/transaction.dart';

void main() {
  const sampleSms =
      "Rs 600.00 sent via UPI on 11-02-2026 at 16:58:50 to JXXL MAXU JXXXP.";
  print('Testing Regex parsing for: $sampleSms');

  final parsed = RegexEngine.parseSms(sampleSms);

  if (parsed != null) {
    print('SUCCESS: Parsed successfully');
    print('Amount: ${parsed['amount']}');
    print('Merchant: ${parsed['merchant']}');
    print('Type: ${parsed['type']}');

    if (parsed['amount'] == 600.0 &&
        parsed['merchant'] == 'JXXL MAXU JXXXP' &&
        parsed['type'] == TransactionType.debit) {
      print('VERIFIED: All fields match expected values.');
    } else {
      print('FAILED: Fields do not match expected values.');
    }
  } else {
    print('FAILED: Could not parse SMS.');
  }
}
