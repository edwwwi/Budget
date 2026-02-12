import 'package:telephony/telephony.dart';
import 'package:budgify/core/database_helper.dart';
import 'package:budgify/core/regex_engine.dart';
import 'package:budgify/core/notification_service.dart';

class SmsService {
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();

  final Telephony telephony = Telephony.instance;

  Future<void> init() async {
    bool? permissionsGranted = await telephony.requestSmsPermissions;
    if (permissionsGranted ?? false) {
      telephony.listenIncomingSms(
        onNewMessage: _onMessage,
        onBackgroundMessage: backgroundMessageHandler,
      );
    }
  }

  static void _onMessage(SmsMessage message) {
    _processMessage(message);
  }

  @pragma('vm:entry-point')
  static void backgroundMessageHandler(SmsMessage message) {
    _processMessage(message);
  }

  static Future<void> _processMessage(SmsMessage message) async {
    final body = message.body ?? '';
    final sender = message.address ?? 'Unknown';

    // Check if it's from Federal Bank (or any other configured sender)
    if (sender.toUpperCase().contains('FEDBNK') ||
        sender.toUpperCase().contains('FEDERAL')) {
      final dbHelper = DatabaseHelper();

      // 1. Log the SMS
      final smsId = await dbHelper.insertSmsLog({
        'sender': sender,
        'timestamp': DateTime.now().toIso8601String(),
        'body': body,
      });

      // 2. Parse the SMS
      final parsedData = RegexEngine.parseSms(body);
      if (parsedData != null) {
        // 3. Trigger Notification
        final notificationService = NotificationService();
        await notificationService.showTransactionNotification(
          id: smsId, // Using smsId as notification id
          amount: parsedData['amount'],
          merchant: parsedData['merchant'],
          smsId: smsId,
        );
      }
    }
  }
}
