import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:isolate';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../data/database/database_helper.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  
  if (notificationResponse.payload == 'daily_summary') {
    final SendPort? sendPort = IsolateNameServer.lookupPortByName('budgify_refresh');
    if (sendPort != null) {
      sendPort.send('show_today_summary');
    }
    return;
  }

  if (notificationResponse.actionId != null) {
    NotificationService.handleAction(
        notificationResponse.id,
        notificationResponse.actionId!,
        notificationResponse.payload,
        notificationResponse.input);
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
//File for Nofication Sevice
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

  static Future<void> showNotification({
    required int id,
    required double amount,
    required String merchant,
  }) async {
    final FlutterLocalNotificationsPlugin flnp =
        FlutterLocalNotificationsPlugin();
    
    final amountString = '₹${amount.toStringAsFixed(0)}';

    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> favMaps = await db.query(
      'categories',
      where: 'is_favorite = ?',
      whereArgs: [1],
      limit: 3,
    );

    List<AndroidNotificationAction> actions = [];
    for (var cat in favMaps) {
      actions.add(AndroidNotificationAction(
        cat['id'].toString(), 
        '${cat['icon']} ${cat['name']}', 
        cancelNotification: false,
      ));
    }
    
    if (actions.isEmpty) {
      // Fallback if no favorites selected
      actions.add(const AndroidNotificationAction('1', '🍔 Food', cancelNotification: false));
      actions.add(const AndroidNotificationAction('2', '⛽ Petrol', cancelNotification: false));
      actions.add(const AndroidNotificationAction('3', '✈️ Travel', cancelNotification: false));
    }

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'budgify_channel_id',
      'Budify Transactions',
      channelDescription: 'Notifications for detected transactions',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Expense Detected',
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF6C63FF), // Primary Brand Color
      styleInformation: BigTextStyleInformation(
        '<br><b>Select Category</b>',
        htmlFormatBigText: true,
        contentTitle: '<b>$amountString</b><br><small>$merchant</small>',
        htmlFormatContentTitle: true,
        summaryText: '💸 Expense Detected',
        htmlFormatSummaryText: true,
      ),
      actions: actions,
    );
    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flnp.show(
      id,
      'Expense Detected',
      '$merchant: $amountString',
      platformChannelSpecifics,
      payload: id.toString(),
    );
  }
  
  static Future<void> showSuccessNotification({
    required int id,
    required String amountString,
    required String merchant,
    required String category,
  }) async {
    final FlutterLocalNotificationsPlugin flnp =
        FlutterLocalNotificationsPlugin();

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'budgify_channel_id',
      'Budify Transactions',
      channelDescription: 'Notifications for detected transactions',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF4CAF50), // Green Accent for success
      styleInformation: BigTextStyleInformation(
        '<br>Category:<br><b>$category</b><br><br>Saved Successfully',
        htmlFormatBigText: true,
        contentTitle: '<b>$amountString</b><br><small>$merchant</small>',
        htmlFormatContentTitle: true,
        summaryText: '✓ Expense Categorized',
        htmlFormatSummaryText: true,
      ),
    );
    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flnp.show(
      id,
      '✓ Expense Categorized',
      'Saved Successfully',
      platformChannelSpecifics,
    );
    
    // Auto dismiss after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      flnp.cancel(id);
    });
  }

  static void onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) async {
    if (notificationResponse.payload == 'daily_summary') {
      final SendPort? sendPort = IsolateNameServer.lookupPortByName('budgify_refresh');
      if (sendPort != null) {
        sendPort.send('show_today_summary');
      }
      return;
    }
    
    if (notificationResponse.actionId != null) {
      handleAction(
          notificationResponse.id,
          notificationResponse.actionId!,
          notificationResponse.payload,
          notificationResponse.input);
    }
  }

  static void handleAction(
      int? notifId, String actionId, String? payload, String? input) async {
    
    final int? transactionId = notifId ?? (payload != null ? int.tryParse(payload) : null);
    
    if (transactionId == null) {
      debugPrint("ERROR: transactionId is null in handleAction. Payload: $payload");
      return;
    }

    final dbHelper = DatabaseHelper();
    final FlutterLocalNotificationsPlugin flnp =
        FlutterLocalNotificationsPlugin();

    try {
      final db = await dbHelper.database;
      bool success = false;
      String category = 'Uncategorized';
      String categoryIcon = '';

      if (actionId == 'ADD_NOTE') {
        if (input != null && input.isNotEmpty) {
          await db.update(
            'transactions',
            {'note': input},
            where: 'id = ?',
            whereArgs: [transactionId],
          );
          success = true;
        }
      } else {
        final int? catId = int.tryParse(actionId);
        if (catId != null) {
          final List<Map<String, dynamic>> catMap = await db.query(
            'categories',
            where: 'id = ?',
            whereArgs: [catId],
          );
          if (catMap.isNotEmpty) {
            categoryIcon = '${catMap.first['icon']} ${catMap.first['name']}';
          }
          
          int updated = await db.update(
            'transactions',
            {'category_id': catId, 'is_categorized': 1},
            where: 'id = ?',
            whereArgs: [transactionId],
          );
          if (updated > 0) {
            success = true;
          } else {
            debugPrint("WARNING: DB update returned 0 rows affected for ID $transactionId");
          }
        }
      }

      if (success) {
        // Notify main isolate to refresh Riverpod IMMEDIATELY so the UI reflects the change
        final SendPort? sendPort = IsolateNameServer.lookupPortByName('budgify_refresh');
        if (sendPort != null) {
          sendPort.send('refresh');
        } else {
          debugPrint("WARNING: budgify_refresh port not found!");
        }

        // Fetch transaction to display correct values in success notification
        final List<Map<String, dynamic>> maps = await db.query(
          'transactions',
          where: 'id = ?',
          whereArgs: [transactionId],
        );
        
        if (maps.isNotEmpty && actionId != 'ADD_NOTE') {
           // Use (num).toDouble() to prevent type error when SQLite returns int for whole numbers
           final double amount = (maps.first['amount'] as num).toDouble();
           final String merchant = maps.first['merchant'] as String;
           
           await showSuccessNotification(
             id: transactionId, 
             amountString: '₹${amount.toStringAsFixed(0)}', 
             merchant: merchant, 
             category: categoryIcon
           );
           
           debugPrint("Transaction Updated: $category");
        } else {
           await flnp.cancel(transactionId);
        }
      } else {
         // Force cancel to prevent it from being stuck
         await flnp.cancel(transactionId);
      }
    } catch (e) {
      debugPrint('Error updating transaction from notification: $e');
      await flnp.cancel(transactionId);
    }
  }
}

