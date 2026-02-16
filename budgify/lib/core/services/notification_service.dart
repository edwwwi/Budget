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
      icon: '@mipmap/ic_launcher',
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('FOOD', 'Food'),
        AndroidNotificationAction('PETROL', 'Petrol'),
        AndroidNotificationAction('ENTERTAINMENT', 'Entertainment'),
        AndroidNotificationAction('OTHER', 'Other'),
        AndroidNotificationAction(
          'ADD_NOTE',
          'Add Note',
          inputs: <AndroidNotificationActionInput>[
            AndroidNotificationActionInput(
              label: 'Enter note...',
            ),
          ],
        ),
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
      handleAction(notificationResponse.actionId!, notificationResponse.payload,
          notificationResponse.input);
    }
  }

  @pragma('vm:entry-point')
  static void notificationTapBackground(
      NotificationResponse notificationResponse) {
    // Handle background taps
    if (notificationResponse.actionId != null) {
      handleAction(notificationResponse.actionId!, notificationResponse.payload,
          notificationResponse.input);
    }
  }

  static void handleAction(
      String actionId, String? payload, String? input) async {
    if (payload == null) return;

    final int? transactionId = int.tryParse(payload);
    if (transactionId == null) return;

    final dbHelper = DatabaseHelper();
    final FlutterLocalNotificationsPlugin flnp =
        FlutterLocalNotificationsPlugin();

    try {
      final db = await dbHelper.database;
      bool success = false;
      String updateMessage = '';

      if (actionId == 'ADD_NOTE') {
        if (input != null && input.isNotEmpty) {
          await db.update(
            'transactions',
            {'note': input},
            where: 'id = ?',
            whereArgs: [transactionId],
          );
          success = true;
          updateMessage = 'Note added';
          print('Updated Transaction $transactionId with note: $input');
        }
      } else {
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
        success = true;
        updateMessage = 'Categorized as $category';
        print('Updated Transaction $transactionId to $category');
      }

      if (success) {
        // Show success notification (Tick)
        // We reuse the same ID to update the existing notification
        const AndroidNotificationDetails androidPlatformChannelSpecifics =
            AndroidNotificationDetails(
          'budgify_channel_id',
          'Budify Transactions',
          channelDescription: 'Notifications for detected transactions',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          icon: '@mipmap/ic_launcher',
          onlyAlertOnce: true, // Don't alert again for the update
          timeoutAfter:
              1000, // Auto cancel after 1 second (native support if available)
        );
        const NotificationDetails platformChannelSpecifics =
            NotificationDetails(android: androidPlatformChannelSpecifics);

        // Determine ID. If payload was just ID, we use it directly if it was used as notification ID.
        // Assuming notification ID matches transaction ID for simplicity or passed via some mechanism.
        // In showNotification, we passed `id`. If payload is transactionId, and we used it as notification Id?
        // Let's assume transactionId IS the notificationId for 1:1 mapping.

        await flnp.show(
          transactionId,
          '✅ Success',
          updateMessage,
          platformChannelSpecifics,
          payload: payload,
        );

        // Explicit cancel after delay as backup to timeoutAfter
        await Future.delayed(const Duration(seconds: 1));
        await flnp.cancel(transactionId);
      }
    } catch (e) {
      print('Error updating transaction from notification: $e');
    }
  }
}
