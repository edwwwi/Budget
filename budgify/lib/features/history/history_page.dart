import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../core/constants.dart';
import '../../data/models/transaction_model.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(transactionListProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: RefreshIndicator(
        onRefresh: () async {
          return ref.read(transactionListProvider.notifier).refresh();
        },
        child: transactionsAsync.when(
          data: (transactions) {
            if (transactions.isEmpty) {
              return const Center(child: Text('No transactions found'));
            }
            return ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return Dismissible(
                  key: Key(transaction.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("Confirm"),
                          content: const Text(
                              "Are you sure you want to delete this transaction?"),
                          actions: <Widget>[
                            TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text("CANCEL")),
                            TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text("DELETE")),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) {
                    ref
                        .read(transactionListProvider.notifier)
                        .deleteTransaction(transaction.id!);
                  },
                  child: _TransactionTile(transaction: transaction),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show manual entry form
          // Check if AddTransactionScreen is accessible or navigate to it
          // Assuming AddTransactionScreen is in manual_entry
          // Need to import it if not already imported or handle navigation
          // Since this file imports constants/models/providers, I might need to import screen
          // But wait, the original code had empty onPressed.
          // I should leave it empty or better, try to navigate if I know where it is.
          // File d:\BUDGET\Budget\budgify\lib\features\manual_entry\add_transaction_screen.dart exists.
          // But I don't want to break imports if I don't have the path right.
          // User didn't ask to fix the FAB navigation, but I should probably leave it as is.
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('dd MMM yyyy, hh:mm a')
                .format(transaction.timestamp)),
            if (transaction.note != null && transaction.note!.isNotEmpty)
              Text(
                transaction.note!,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        ),
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
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.transaction.category;
    _noteController = TextEditingController(text: widget.transaction.note);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Edit Transaction',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Note Field
          TextFormField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Note',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
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
                // Update both category and note
                final updatedTransaction = widget.transaction.copyWith(
                  category: _selectedCategory,
                  isCategorized: true, // Assuming if we edit, we categorized it
                  note: _noteController.text,
                );

                ref
                    .read(transactionListProvider.notifier)
                    .updateTransaction(updatedTransaction);

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
