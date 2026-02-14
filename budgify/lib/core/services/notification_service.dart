import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../data/database/database_helper.dart';

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
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  // Expose for background usage if needed (static method)
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    final FlutterLocalNotificationsPlugin flnp =
        FlutterLocalNotificationsPlugin();
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'budgify_channel_id',
      'Budify Transactions',
      channelDescription: 'Notifications for detected transactions',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('FOOD', 'Food'),
        AndroidNotificationAction('PETROL', 'Petrol'),
        AndroidNotificationAction('ENTERTAINMENT', 'Entertainment'),
        AndroidNotificationAction('OTHER', 'Other'),
      ],
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flnp.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  static void onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) async {
    // Handle foreground taps
    // payload contains transaction timestamp or ID or hash
    if (notificationResponse.actionId != null) {
      // User tapped an action button
      handleAction(
          notificationResponse.actionId!, notificationResponse.payload);
    }
  }

  @pragma('vm:entry-point')
  static void notificationTapBackground(
      NotificationResponse notificationResponse) {
    // Handle background taps
    if (notificationResponse.actionId != null) {
      handleAction(
          notificationResponse.actionId!, notificationResponse.payload);
    }
  }

  static void handleAction(String actionId, String? payload) async {
    if (payload == null) return;

    final int? transactionId = int.tryParse(payload);
    if (transactionId == null) return;

    final dbHelper = DatabaseHelper();
    // Fetch transaction first? Or just update specific field if possible.
    // Since we need to update category and is_categorized, but keep other fields, fetch is safer.
    // However, for efficiency, just raw update query is better, but our db helper uses updateTransaction(model).
    // So we fetch, modify, update.

    // We need to get the transaction by ID. We don't have getById method in DB helper yet,
    // let's assume we can fetch all or query by ID.
    // Let's add getById to DbHelper or just query here for now using raw query if needed,
    // but cleaner to add method to helper.
    // For now, I'll update using raw update for speed/simplicity in this context or wait.
    // Actually, I'll use the repository/helper if available.
    // Let's assume getTransactionById exists or I'll add it.
    // Or I can just execute raw SQL:
    try {
      final db = await dbHelper.database;
      String category = 'Uncategorized';
      switch (actionId) {
        case 'FOOD':
          category = 'Food';
          break;
        case 'PETROL':
          category = 'Petrol';
          break;
        case 'ENTERTAINMENT':
          category = 'Entertainment';
          break;
        case 'OTHER':
          category = 'Other';
          break;
      }

      await db.update(
        'transactions',
        {'category': category, 'is_categorized': 1},
        where: 'id = ?',
        whereArgs: [transactionId],
      );
      print('Updated Transaction $transactionId to $category');
    } catch (e) {
      print('Error updating transaction from notification: $e');
    }
  }
}
