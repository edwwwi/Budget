import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../models/transaction_category.dart';
import '../models/transaction_type.dart';
import '../core/database/database_helper.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static final StreamController<Map<String, dynamic>>
  _notificationActionController =
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get notificationActionStream =>
      _notificationActionController.stream;

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationTapped,
    );

    await _createNotificationChannels();
  }

  static Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'budify_transactions',
      'Budify Transactions',
      description: 'Transaction alerts and categorization',
      importance: Importance.max,
      enableVibration: true,
      enableLights: true,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  static void _onNotificationTapped(NotificationResponse response) {
    if (response.actionId != null && response.payload != null) {
      _handleAction(response.actionId!, response.payload!);
    }
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    if (response.actionId != null && response.payload != null) {
      _handleAction(response.actionId!, response.payload!);
    }
  }

  static Future<void> _handleAction(String actionId, String payload) async {
    // payload: amount|merchant|type|timestamp
    final parts = payload.split('|');
    if (parts.length < 4) return;

    final amount = double.parse(parts[0]);
    final merchant = parts[1];
    final type = TransactionType.values[int.parse(parts[2])];
    final timestamp = DateTime.parse(parts[3]);

    TransactionCategory? category;
    if (actionId == 'food')
      category = TransactionCategory.food;
    else if (actionId == 'petrol')
      category = TransactionCategory.petrol;
    else if (actionId == 'entertainment')
      category = TransactionCategory.entertainment;
    else if (actionId == 'other')
      category = TransactionCategory.other;

    if (category != null) {
      final transaction = TransactionModel(
        amount: amount,
        category: category,
        merchant: merchant,
        type: type,
        timestamp: timestamp,
      );

      await DatabaseHelper().insertTransaction(transaction);

      // Notify listeners if app is in foreground
      _notificationActionController.add({
        'action': 'transaction_added',
        'transaction': transaction,
      });

      // Dismiss notification (automatically happens for actions usually, but to be sure)
      await _notifications.cancel(transaction.hashCode);
    }
  }

  static Future<void> showSmartNotification(
    TransactionModel transaction,
  ) async {
    final List<AndroidNotificationAction> actions = [
      const AndroidNotificationAction(
        'food',
        'Food',
        showsUserInterface: false,
      ),
      const AndroidNotificationAction(
        'petrol',
        'Petrol',
        showsUserInterface: false,
      ),
      const AndroidNotificationAction(
        'entertainment',
        'Entertainment',
        showsUserInterface: false,
      ),
      const AndroidNotificationAction(
        'other',
        'Other',
        showsUserInterface: false,
      ),
    ];

    final String payload =
        '${transaction.amount}|${transaction.merchant}|${transaction.type.index}|${transaction.timestamp.toIso8601String()}';

    final AndroidNotificationDetails
    androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'budify_transactions',
      'Budify Transactions',
      channelDescription: 'Transaction alerts and categorization',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Budify SMS detected',
      styleInformation: BigTextStyleInformation(
        '${transaction.type == TransactionType.debit ? "Sent" : "Received"} <b>Rs ${transaction.amount.toStringAsFixed(2)}</b> to ${transaction.merchant}',
        htmlFormatBigText: true,
        contentTitle: 'New Transaction',
        htmlFormatContentTitle: true,
        summaryText: 'Categorization Required',
        htmlFormatSummaryText: true,
      ),
      actions: actions,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notifications.show(
      transaction.hashCode,
      'New Transaction',
      'Rs ${transaction.amount.toStringAsFixed(2)} to ${transaction.merchant}',
      platformChannelSpecifics,
      payload: payload,
    );
  }

  static void dispose() {
    _notificationActionController.close();
  }
}
