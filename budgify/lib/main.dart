import 'package:flutter/material.dart';
import 'package:budgify/core/notification_service.dart';
import 'package:budgify/core/sms_service.dart';
import 'package:budgify/presentation/pages/main_page.dart';
import 'package:budgify/presentation/pages/history_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final notificationService = NotificationService();
  await notificationService.init();

  final smsService = SmsService();
  await smsService.init();

  runApp(const BudgifyApp());
}

class BudgifyApp extends StatelessWidget {
  const BudgifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budgify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MainPage(),
        '/history': (context) => const HistoryPage(),
      },
    );
  }
}
