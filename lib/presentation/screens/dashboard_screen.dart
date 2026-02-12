import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../widgets/donut_chart.dart';
import '../widgets/summary_card.dart';
import '../../models/transaction_model.dart';
import '../../models/transaction_category.dart';
import '../../models/transaction_type.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Budify',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Spending Habits',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                BudifyDonutChart(data: provider.categorySpending),
                const SizedBox(height: 30),
                Row(
                  children: [
                    BudifySummaryCard(
                      title: 'Income',
                      amount: provider.totalIncome,
                      color: Colors.green,
                      icon: Icons.arrow_downward,
                    ),
                    const SizedBox(width: 16),
                    BudifySummaryCard(
                      title: 'Outcome',
                      amount: provider.totalOutcome,
                      color: Colors.red,
                      icon: Icons.arrow_upward,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showManualEntry(context),
        child: const Icon(Icons.add),
        shape: const CircleBorder(),
      ),
    );
  }

  void _showManualEntry(BuildContext context) {
    final amountController = TextEditingController();
    final merchantController = TextEditingController();
    TransactionCategory selectedCategory = TransactionCategory.other;
    TransactionType selectedType = TransactionType.debit;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manual Entry',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (Rs)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: merchantController,
              decoration: const InputDecoration(
                labelText: 'Merchant',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Type'),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<TransactionType>(
                    title: const Text('Debit'),
                    value: TransactionType.debit,
                    groupValue: selectedType,
                    onChanged: (v) => selectedType = v!,
                  ),
                ),
                Expanded(
                  child: RadioListTile<TransactionType>(
                    title: const Text('Credit'),
                    value: TransactionType.credit,
                    groupValue: selectedType,
                    onChanged: (v) => selectedType = v!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text) ?? 0;
                  if (amount > 0 && merchantController.text.isNotEmpty) {
                    final transaction = TransactionModel(
                      amount: amount,
                      category: selectedCategory,
                      merchant: merchantController.text,
                      type: selectedType,
                      timestamp: DateTime.now(),
                    );
                    context.read<AppProvider>().addManualTransaction(
                      transaction,
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save Transaction'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
