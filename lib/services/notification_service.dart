import 'dart:async';
import 'dart:collection';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/category.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  static final StreamController<Map<String, dynamic>> _notificationActionController = 
      StreamController<Map<String, dynamic>>.broadcast();

  // Set to track transaction IDs that have already been notified
  static final HashSet<String> _notifiedTransactions = HashSet<String>();
  
  // Maximum number of transaction IDs to keep in memory
  static const int _maxStoredTransactions = 100;

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
    );
    
    // Create notification channels for Android
    await _createNotificationChannels();
    
    // Request notification permissions
    await requestNotificationPermissions();
  }

  static Future<void> _createNotificationChannels() async {
    // Transaction notification channel
    const AndroidNotificationChannel transactionChannel = AndroidNotificationChannel(
      'transaction_channel',
      'Transaction Notifications',
      description: 'Notifications for new bank transactions',
      importance: Importance.high,
      enableVibration: true,
      enableLights: true,
    );

    // Category selection channel
    const AndroidNotificationChannel categoryChannel = AndroidNotificationChannel(
      'category_channel',
      'Category Selection',
      description: 'Quick category selection for transactions',
      importance: Importance.defaultImportance,
      enableVibration: false,
      enableLights: false,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(transactionChannel);
        
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(categoryChannel);
  }

  static Future<void> requestNotificationPermissions() async {
    // Request notification permissions for Android 13+
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.id}, action: ${response.actionId}, payload: ${response.payload}');
    
    // Handle category selection from notification actions
    if (response.actionId != null && response.payload != null) {
      // The actionId is the category ID
      String categoryId = response.actionId!;
      
      // Parse the payload to get transaction ID
      List<String> parts = response.payload!.split('|');
      if (parts.length >= 2) {
        String transactionId = parts[1]; // The transaction ID is the second part
        
        print('Category selected: $categoryId for transaction: $transactionId');
        
        // Send to stream for processing
        _notificationActionController.add({
          'transactionId': transactionId,
          'categoryId': categoryId,
          'action': 'categorize',
        });
      }
    }
    // Handle regular notification tap
    else if (response.payload != null) {
      List<String> parts = response.payload!.split('|');
      if (parts.length >= 2) {
        String type = parts[0]; // 'transaction'
        String transactionId = parts[1];
        
        // Send to stream for processing
        _notificationActionController.add({
          'transactionId': transactionId,
          'action': 'view',
        });
      }
    }
  }

  static Future<void> showTransactionNotification(Transaction transaction) async {
    // Check if we've already shown a notification for this transaction
    if (_notifiedTransactions.contains(transaction.id)) {
      print('Skipping duplicate notification for transaction ${transaction.id}');
      return;
    }
    
    // Add to notified transactions set
    _notifiedTransactions.add(transaction.id);
    
    // Limit the size of the set to prevent memory issues
    if (_notifiedTransactions.length > _maxStoredTransactions) {
      // Remove the oldest transaction ID (approximation since HashSet doesn't maintain order)
      _notifiedTransactions.remove(_notifiedTransactions.first);
    }
    
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'transaction_channel',
      'Transaction Notifications',
      channelDescription: 'Notifications for new bank transactions',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      enableLights: true,
      color: Colors.green,
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(''),
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Show main notification
    await _notifications.show(
      transaction.hashCode,
      'New Transaction Detected',
      '₹${transaction.amount.toStringAsFixed(2)} ${transaction.type == TransactionType.credit ? 'credited' : 'debited'}',
      platformChannelSpecifics,
      payload: 'transaction|${transaction.id}',
    );

    // Show category selection notification
    await _showCategorySelectionNotification(transaction);
  }

  static Future<void> _showCategorySelectionNotification(Transaction transaction) async {
    // Create action buttons for quick categorization
    List<AndroidNotificationAction> actions = [];
    
    // Get quick categories (first 5 default categories)
    List<Category> quickCategories = Category.defaultCategories.take(5).toList();
    
    // Add action for each category
    for (var category in quickCategories) {
      actions.add(AndroidNotificationAction(
        category.id,
        category.name,
        icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        contextual: true,
      ));
    }
    
    // Add an 'Other' action
    actions.add(AndroidNotificationAction(
      'other',
      'Other',
      icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      contextual: true,
    ));
    
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'category_channel',
      'Category Selection',
      channelDescription: 'Quick category selection for transactions',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: false,
      enableVibration: false,
      enableLights: false,
      color: Colors.blue,
      actions: actions,
      styleInformation: BigTextStyleInformation(''),
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
        
    // Show notification with category selection
    await _notifications.show(
      transaction.hashCode + 1, // Different ID from the main notification
      'Categorize Transaction',
      'Select a category for ₹${transaction.amount.toStringAsFixed(2)} ${transaction.type == TransactionType.credit ? 'credit' : 'debit'}',
      platformChannelSpecifics,
      payload: 'transaction|${transaction.id}',
    );
  }

  static Future<void> showBudgetAlert(double spent, double budget) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'budget_channel',
      'Budget Alerts',
      channelDescription: 'Notifications for budget limits',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      enableLights: true,
      color: Colors.orange,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    double percentage = (spent / budget) * 100;
    String message = percentage >= 100 
        ? 'You have exceeded your monthly budget!'
        : 'You have used ${percentage.toStringAsFixed(1)}% of your monthly budget';

    await _notifications.show(
      9999, // Fixed ID for budget alerts
      'Budget Alert',
      message,
      platformChannelSpecifics,
    );
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static void dispose() {
    _notificationActionController.close();
  }
}
