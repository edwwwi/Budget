import 'package:flutter/material.dart';
import '../models/transaction.dart';

class DashboardCard extends StatelessWidget {
  final List<Transaction> transactions;
  final DateTime selectedMonth;

  const DashboardCard({
    super.key,
    required this.transactions,
    required this.selectedMonth,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate total income, expense, and balance
    double totalIncome = 0;
    double totalExpense = 0;

    // Filter transactions for the selected month
    final filteredTransactions = transactions.where((t) =>
        t.date.year == selectedMonth.year && t.date.month == selectedMonth.month);

    // Calculate totals
    for (var transaction in filteredTransactions) {
      if (transaction.type == TransactionType.credit) {
        totalIncome += transaction.amount;
      } else {
        totalExpense += transaction.amount;
      }
    }

    final balance = totalIncome - totalExpense;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.dashboard_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Financial Overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    context,
                    'Income',
                    totalIncome,
                    Icons.arrow_upward,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoCard(
                    context,
                    'Expense',
                    totalExpense,
                    Icons.arrow_downward,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoCard(
              context,
              'Balance',
              balance,
              balance >= 0 ? Icons.account_balance_wallet : Icons.warning,
              balance >= 0 ? Colors.blue : Colors.orange,
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    double amount,
    IconData icon,
    Color color, {
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment:
            isFullWidth ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: isFullWidth
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}