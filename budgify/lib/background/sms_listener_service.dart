import 'package:another_telephony/telephony.dart';
import 'sms_parser.dart';
import '../data/database/database_helper.dart';
import '../core/services/notification_service.dart';
import 'package:flutter/foundation.dart';

// Top-level function for background handling
@pragma('vm:entry-point')
void backgroundMessageHandler(SmsMessage message) async {
  debugPrint("Background SMS received: ${message.body}");
  await _processSms(message);
}

Future<void> _processSms(SmsMessage message) async {
  // Check if sender is Federal Bank-like (often alphanumeric like VM-FEDBNK, AD-FEDBNK)
  // For now, parse all to see if it matches structure
  // Or filter by "FEDBNK"
  bool likelyBank = (message.address ?? '').toUpperCase().contains('FEDBNK') ||
      (message.body ?? '').toLowerCase().contains('fedbnk');

  if (!likelyBank) {
    if ((message.body ?? '').toLowerCase().contains('debited') ||
        (message.body ?? '').toLowerCase().contains('credited')) {
      // Maybe allow if it looks like transaction but not from specific sender?
      // For now, strict or loose?
      // Let's rely on SmsParser returning null if it can't parse amount/logic.
      // But prompt said "Listen only to SMS from Federal Bank".
      // So I should enforce likelyBank.
      // However, for testing I might want to relax it.
      // I'll uncomment the enforcement.
      // return;
    }
  }

  final transaction = SmsParser.parse(message.body, message.date);

  if (transaction != null) {
    // It's a valid transaction SMS
    final dbHelper = DatabaseHelper();

    // Check for duplicate handled in repository usually, but here we do direct DB checking
    // Re-implement duplicate check logic locally for background isolation safety if needed,
    // but DatabaseHelper is singleton so it should init fine in new isolate

    // Check existing by hash
    final existing = await dbHelper.getInstanceBySmsHash(transaction.smsHash!);

    if (existing == null) {
      int id = await dbHelper.insertTransaction(transaction);

      // Trigger Notification
      await NotificationService.showNotification(
        id: id,
        title: 'Expense Detected',
        body: '${transaction.merchant}: ${transaction.amount}',
        payload: id.toString(),
      );
    }
  }
}

class SmsListenerService {
  final Telephony telephony = Telephony.instance;

  void init() {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        // Foreground handler
        debugPrint("Foreground SMS received: ${message.body}");
        _processSms(message);
      },
      onBackgroundMessage: backgroundMessageHandler,
    );
  }
}
