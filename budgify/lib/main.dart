import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/theme.dart';
import 'features/home/main_page.dart';
import 'core/services/notification_service.dart';
import 'background/sms_listener_service.dart';
import 'core/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Services
  await NotificationService().init();
  SmsListenerService().init();

  runApp(const ProviderScope(child: BudifyApp()));
}

class BudifyApp extends StatefulWidget {
  const BudifyApp({super.key});

  @override
  State<BudifyApp> createState() => _BudifyAppState();
}

class _BudifyAppState extends State<BudifyApp> {
  @override
  void initState() {
    super.initState();
    _requestPermissions();
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
    return MaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.lightTheme,
      home: const MainPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
