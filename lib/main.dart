import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:isolate';
import 'dart:ui';
import 'core/theme.dart';
import 'features/home/main_page.dart';
import 'core/services/notification_service.dart';
import 'background/sms_listener_service.dart';
import 'core/constants.dart';
import 'providers/transaction_provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'background/daily_summary_worker.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void _scheduleDailySummary() {
  final now = DateTime.now();
  var target = DateTime(now.year, now.month, now.day, 23, 0);
  if (now.isAfter(target)) {
    target = target.add(const Duration(days: 1));
  }
  
  // Guarantee execution exactly at 11:00 PM via Alarm Manager
  AndroidAlarmManager.periodic(
    const Duration(days: 1),
    999, // Alarm ID
    alarmDailySummaryHandler,
    startAt: target,
    exact: true,
    wakeup: true,
    rescheduleOnReboot: true,
  );
  
  // Keep workmanager as a fallback for older devices or restricted environments
  final initialDelay = target.difference(now);
  Workmanager().registerPeriodicTask(
    "daily_summary_task",
    "dailySummary",
    frequency: const Duration(days: 1),
    initialDelay: initialDelay,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
////////////////////////////////////
  // Initialize Services
  await NotificationService().init();
  SmsListenerService().init();

  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );
  
  await AndroidAlarmManager.initialize();
  
  _scheduleDailySummary();

  runApp(const ProviderScope(child: BudifyApp()));
}

class BudifyApp extends ConsumerStatefulWidget {
  const BudifyApp({super.key});

  @override
  ConsumerState<BudifyApp> createState() => _BudifyAppState();
}

class _BudifyAppState extends ConsumerState<BudifyApp> {
  ReceivePort _port = ReceivePort();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    
    // Register port for background isolate communication
    IsolateNameServer.removePortNameMapping('budgify_refresh');
    IsolateNameServer.registerPortWithName(_port.sendPort, 'budgify_refresh');
    _port.listen((dynamic data) {
      if (data == 'refresh') {
        ref.read(transactionListProvider.notifier).refresh();
      } else if (data == 'show_today_summary') {
        ref.read(timeFilterProvider.notifier).state = TimeFilter.today;
        navigatorKey.currentState?.popUntil((route) => route.isFirst);
      }
    });
  }
  
  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('budgify_refresh');
    _port.close();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    // Request SMS and Notification permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.sms,
      Permission.notification,
    ].request();

    if (statuses[Permission.sms] != PermissionStatus.granted) {
      // Handle denial - maybe show a dialog explaining why
      debugPrint("SMS Permission Denied");
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: AppStrings.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const MainPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

