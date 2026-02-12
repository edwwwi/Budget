import 'package:budgify/core/database_helper.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  static void _onNotificationResponse(NotificationResponse response) {
    // Handle foreground notification tap if needed
  }

  @pragma('vm:entry-point')
  static void notificationTapBackground(NotificationResponse response) {
    // This will be handled in the background
    // We'll need to save the transaction to the database based on the action selected
    if (response.payload != null) {
      final payloadData = response.payload!.split('|');
      if (payloadData.length >= 3) {
        final category = response.actionId; // Food, Petrol, etc.
        final amount = double.tryParse(payloadData[0]) ?? 0.0;
        final merchant = payloadData[1];
        final smsId = int.tryParse(payloadData[2]);

        // We'll call a static method to save to DB since this is a top-level function
        _saveTransactionInBackground(amount, merchant, category, smsId);
      }
    }
  }

  static Future<void> _saveTransactionInBackground(
    double amount,
    String merchant,
    String? category,
    int? smsId,
  ) async {
    final dbHelper = DatabaseHelper();
    final timestamp = DateTime.now().toIso8601String();

    await dbHelper.insertTransaction({
      'amount': amount,
      'merchant': merchant,
      'category': category ?? 'Other',
      'type': 'Debit', // Federal Bank pattern used is for 'sent'
      'sms_id': smsId,
      'timestamp': timestamp,
    });
  }

  Future<void> showTransactionNotification({
    required int id,
    required double amount,
    required String merchant,
    required int smsId,
  }) async {
    final String payload = '$amount|$merchant|$smsId';

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'transaction_id',
          'Transactions',
          channelDescription: 'Notifications for new transactions',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          styleInformation: BigTextStyleInformation(''),
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction('Food', 'Food'),
            AndroidNotificationAction('Petrol', 'Petrol'),
            AndroidNotificationAction('Entertainment', 'Entertainment'),
            AndroidNotificationAction('Other', 'Other'),
          ],
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      'New Transaction Detected',
      'Rs $amount spent at $merchant. Categorize now:',
      platformChannelSpecifics,
      payload: payload,
    );
  }
}
