import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'presentation/screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appProvider = AppProvider();
  await appProvider.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => appProvider,
      child: const BudifyApp(),
    ),
  );
}

class BudifyApp extends StatelessWidget {
  const BudifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
          surface: const Color(0xFFFBFBFE),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFFBFBFE),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          color: Colors.white,
        ),
      ),
      home: const MainScreen(),
    );
  }
}
