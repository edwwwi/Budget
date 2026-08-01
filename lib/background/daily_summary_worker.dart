import 'package:workmanager/workmanager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../data/database/database_helper.dart';

@pragma('vm:entry-point')
void alarmDailySummaryHandler() async {
  await executeDailySummary();
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await executeDailySummary();
    return Future.value(true);
  });
}

Future<void> executeDailySummary() async {
  try {
    final dbHelper = DatabaseHelper();
    final now = DateTime.now();
    
    // We only care about Today
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    // Initialize local notifications
    final flnp = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flnp.initialize(initializationSettings);

    // Fetch all transactions
    final allTransactions = await dbHelper.getTransactions();
    
    final todaysTransactions = allTransactions.where((t) {
      return t.timestamp.isAfter(startOfDay.subtract(const Duration(seconds: 1))) && t.type == 'DEBIT';
    }).toList();

    if (todaysTransactions.isEmpty) {
      return;
    }

    final categories = await dbHelper.getCategories();
    final Map<int, String> categoryNames = {
      for (var c in categories) c.id!: '${c.icon} ${c.name}'
    };

    double totalCategorizedAmount = 0;
    Map<String, double> categoryTotals = {};
    int uncategorizedCount = 0;

    for (var t in todaysTransactions) {
      if (t.isCategorized && t.categoryId != 6) { // 6 is default 'Other' or uncategorized in this context? Let's just say if isCategorized.
        final catName = categoryNames[t.categoryId] ?? 'Unknown';
        totalCategorizedAmount += t.amount;
        categoryTotals[catName] = (categoryTotals[catName] ?? 0) + t.amount;
      } else {
        uncategorizedCount++;
      }
    }

    String body = '';
    if (categoryTotals.isNotEmpty) {
      categoryTotals.forEach((cat, amt) {
        body += '$cat: ₹${amt.toStringAsFixed(0)}<br>';
      });
    } else {
      body += 'No categorized expenses today.<br>';
    }

    String title = '<b>₹${totalCategorizedAmount.toStringAsFixed(0)}</b> Spent Today';
    if (uncategorizedCount > 0) {
      title += ' <font color="red">($uncategorizedCount ⚠️ Uncategorized)</font>';
      body += '<br><b>$uncategorizedCount expenses need categorization!</b>';
    }

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'daily_summary_id',
      'Daily Summary',
      channelDescription: 'Daily expense summary at 11 PM',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF6C63FF),
      styleInformation: BigTextStyleInformation(
        body,
        htmlFormatBigText: true,
        contentTitle: title,
        htmlFormatContentTitle: true,
        summaryText: '📊 Daily Summary',
      ),
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flnp.show(
      999, // Fixed ID for daily summary
      'Daily Summary',
      'Tap to view insights',
      platformChannelSpecifics,
      payload: 'daily_summary',
    );

  } catch (e) {
    debugPrint("Daily summary worker failed: $e");
  }
}
