import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance/main.dart';
import 'package:finance/providers/app_provider.dart';
import 'package:finance/models/transaction.dart';
import 'package:finance/services/sms_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Budget Tracker Tests', () {
    setUp(() async {
      // Skip storage initialization for tests that don't need it
    });


    testWidgets('App loads and displays transactions screen', (WidgetTester tester) async {
      // Initialize the app provider
      final appProvider = AppProvider();
      await appProvider.initialize();
      
      // Build our app and trigger a frame
      await tester.pumpWidget(MyApp(appProvider: appProvider));

      // Verify that the app title is displayed
      expect(find.text('Transactions'), findsOneWidget);
      
      // Verify that the bottom navigation bar is displayed
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });
    
    testWidgets('Navigation works correctly', (WidgetTester tester) async {
      // Initialize the app provider
      final appProvider = AppProvider();
      await appProvider.initialize();
      
      // Build our app and trigger a frame
      await tester.pumpWidget(MyApp(appProvider: appProvider));

      // Verify that we're on the transactions screen
      expect(find.text('Transactions'), findsOneWidget);
      
      // Tap the categories tab
      await tester.tap(find.text('Categories'));
      await tester.pumpAndSettle();
      
      // Verify that we're on the categories screen
      expect(find.text('Categories'), findsOneWidget);
      
      // Tap the charts tab
      await tester.tap(find.text('Charts'));
      await tester.pumpAndSettle();
      
      // Verify that we're on the charts screen
      expect(find.text('Analytics'), findsOneWidget);
      
      // Tap the settings tab
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      
      // Verify that we're on the settings screen
      expect(find.text('Settings'), findsOneWidget);
    });
    
    test('Transaction parsing works correctly', () {
      // Create a mock SMS message
      const String smsBody = 'Your account XX1234 has been debited with INR 1000.00 on 01/01/2023. Available balance is INR 5000.00.';
      const String sender = 'HDFCBANK';
      
      // Parse the transaction
      final transaction = SmsService.instance.parseTransactionFromSms(smsBody, sender);
      
      // Verify that the transaction was parsed correctly
      expect(transaction, isNotNull);
      expect(transaction!.amount, 1000.00);
      expect(transaction.type, TransactionType.debit);
      expect(transaction.bankName, 'HDFC Bank');
      expect(transaction.balance, 5000.00);
    });
  });
}