import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'models/transaction.dart';

class TestSmsScreen extends StatefulWidget {
  const TestSmsScreen({super.key});

  @override
  _TestSmsScreenState createState() => _TestSmsScreenState();
}

class _TestSmsScreenState extends State<TestSmsScreen> {
  final TextEditingController _smsController = TextEditingController();
  String _result = '';

  @override
  void initState() {
    super.initState();
    // Set a default test SMS message
    _smsController.text = 'Test Bank: Rs.1000.00 credited to your account on 20/08/2025 at 10:30. Avl Bal: Rs.5000.00';
  }

  void _testSmsProcessing() {
    final smsBody = _smsController.text;
    if (smsBody.isEmpty) {
      setState(() {
        _result = 'Please enter an SMS message';
      });
      return;
    }

    try {
      // Get the app provider
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      
      // Create a test transaction directly
      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: 1000.00,
        type: TransactionType.credit,
        category: 'uncategorized',
        description: 'Test Transaction',
        date: DateTime.now(),
        balance: 5000.00,
        bankName: 'Test Bank',
        isCategorized: false,
        smsBody: smsBody,
      );
      
      // Add the transaction directly to the provider
      appProvider.addTransaction(transaction);
      
      setState(() {
        _result = 'Test transaction added successfully. Check if it appears in the transactions list.';
      });
    } catch (e) {
      setState(() {
        _result = 'Error adding test transaction: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test SMS Processing'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter a test SMS message to process:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _smsController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter SMS content here...',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testSmsProcessing,
              child: const Text('Process Test SMS'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Result:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_result),
            ),
            const SizedBox(height: 24),
            const Text(
              'Transaction Count:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Consumer<AppProvider>(
              builder: (context, provider, child) {
                return Text(
                  'Current transactions: ${provider.transactions.length}',
                  style: const TextStyle(fontSize: 16),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _smsController.dispose();
    super.dispose();
  }
}