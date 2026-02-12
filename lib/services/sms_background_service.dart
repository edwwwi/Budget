import 'package:telephony/telephony.dart';
import '../core/utils/sms_parser.dart';
import '../core/database/database_helper.dart';
import '../models/sms_log_model.dart';
import 'notification_service.dart';

class SmsBackgroundService {
  static final Telephony telephony = Telephony.instance;

  static Future<void> initialize() async {
    bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted != null && permissionsGranted) {
      telephony.listenIncomingSms(
        onNewMessage: _onMessage,
        onBackgroundMessage: _backgroundMessageHandler,
      );
    }
  }

  static void _onMessage(SmsMessage message) {
    _processMessage(message);
  }

  @pragma('vm:entry-point')
  static void _backgroundMessageHandler(SmsMessage message) {
    _processMessage(message);
  }

  static Future<void> _processMessage(SmsMessage message) async {
    final body = message.body ?? '';
    final sender = message.address ?? 'Unknown';

    // Log all SMS from "Federal Bank" (case insensitive check for address)
    if (sender.toLowerCase().contains('federal') ||
        sender.toLowerCase().contains('fed') ||
        body.toLowerCase().contains('federal bank')) {
      final log = SmsLogModel(
        sender: sender,
        body: body,
        timestamp: DateTime.now(),
      );

      await DatabaseHelper().insertSmsLog(log);

      final transaction = SmsParser.parseFederalBankSms(body);
      if (transaction != null) {
        await NotificationService.showSmartNotification(transaction);
      }
    }
  }
}
