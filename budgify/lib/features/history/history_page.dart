import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../core/constants.dart';
import '../../data/models/transaction_model.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(child: Text('No transactions found'));
          }
          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return _TransactionTile(transaction: transaction);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show manual entry form
          // Navigate or Show Dialog
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  final TransactionModel transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDebit = transaction.type == 'DEBIT';
    final Color amountColor = isDebit ? AppColors.expense : AppColors.income;
    final bool isUncategorized = !transaction.isCategorized;

    return Card(
      color: isUncategorized ? Colors.amber[50] : Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isUncategorized
              ? Colors.orange
              : AppColors.primary.withValues(alpha: 0.1),
          child: Icon(_getIconForCategory(transaction.category),
              color: isUncategorized ? Colors.white : AppColors.primary),
        ),
        title: Text(transaction.merchant,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            DateFormat('dd MMM yyyy, hh:mm a').format(transaction.timestamp)),
        trailing: Text(
          '${isDebit ? '-' : '+'}${AppStrings.currency}${transaction.amount.toStringAsFixed(2)}',
          style: TextStyle(
              color: amountColor, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        onTap: () {
          _showEditBottomSheet(context, ref, transaction);
        },
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Food':
        return Icons.fastfood;
      case 'Petrol':
        return Icons.local_gas_station;
      case 'Entertainment':
        return Icons.movie;
      case 'Other':
        return Icons.category;
      default:
        return Icons.help_outline;
    }
  }

  void _showEditBottomSheet(
      BuildContext context, WidgetRef ref, TransactionModel transaction) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _EditTransactionSheet(transaction: transaction);
      },
    );
  }
}

class _EditTransactionSheet extends ConsumerStatefulWidget {
  final TransactionModel transaction;
  const _EditTransactionSheet({required this.transaction});

  @override
  ConsumerState<_EditTransactionSheet> createState() =>
      _EditTransactionSheetState();
}

class _EditTransactionSheetState extends ConsumerState<_EditTransactionSheet> {
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.transaction.category;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Categorize Transaction',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children:
                ['Food', 'Petrol', 'Entertainment', 'Other'].map((category) {
              final isSelected = _selectedCategory == category;
              return FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                selectedColor: AppColors.primary.withOpacity(0.2),
                checkmarkColor: AppColors.primary,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                ref
                    .read(transactionListProvider.notifier)
                    .categorizeTransaction(
                        widget.transaction.id!, _selectedCategory);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          )
        ],
      ),
    );
  }
}
