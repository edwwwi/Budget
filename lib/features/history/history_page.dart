import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/transaction_provider.dart';
import '../../core/constants.dart';
import '../../data/models/transaction_model.dart';
import '../../widgets/transaction_edit_sheet.dart';

class HistoryPage extends ConsumerStatefulWidget {
  final String initialFilter;
  const HistoryPage({super.key, this.initialFilter = 'All'});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage>
    with WidgetsBindingObserver {
  String _searchQuery = '';
  late String _selectedFilter;

  final List<String> _filters = [
    'All',
    'Categorized',
    'Uncategorized',
    'Food',
    'Petrol',
    'Travel',
    'Entertainment',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
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

  Future<void> _exportTransactions(List<TransactionModel> transactions) async {
    try {
      if (transactions.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No transactions to export')),
        );
        return;
      }

      final StringBuffer csvBuffer = StringBuffer();
      csvBuffer.writeln('Date,Amount,Merchant,Type,Category,Note');

      for (var t in transactions) {
        final date = DateFormat('yyyy-MM-dd HH:mm:ss').format(t.timestamp);
        final amount = t.amount.toStringAsFixed(2);
        final merchant = t.merchant.replaceAll('"', '""');
        final type = t.type;
        final category = t.category.replaceAll('"', '""');
        final note = (t.note ?? '').replaceAll('"', '""');

        csvBuffer.writeln(
            '"$date","$amount","$merchant","$type","$category","$note"');
      }

      final directory = await getTemporaryDirectory();
      final String timestampStr =
          DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final String filePath =
          '${directory.path}/transactions_$timestampStr.csv';
      final File file = File(filePath);

      await file.writeAsString(csvBuffer.toString());

      if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
        await Share.shareXFiles([XFile(filePath)], text: 'Budify Transactions');
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export: $e')),
      );
    }
  }

  List<TransactionModel> _applyFiltersAndSearch(List<TransactionModel> list) {
    // Note: Budify is now an Expense tracker, but we'll show all in history just in case,
    // or maybe only DEBIT? For history, users might want to see all sms parsed.
    // We will show DEBIT by default, or all? Let's show all, since history is comprehensive.
    return list.where((t) {
      // Filter logic
      bool matchesFilter = true;
      if (_selectedFilter == 'Categorized') {
        matchesFilter = t.isCategorized;
      } else if (_selectedFilter == 'Uncategorized') {
        matchesFilter = !t.isCategorized;
      } else if (_selectedFilter != 'All') {
        matchesFilter = t.category == _selectedFilter;
      }

      // Search logic
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        matchesSearch = t.merchant.toLowerCase().contains(query) ||
            t.category.toLowerCase().contains(query) ||
            t.amount.toString().contains(query);
      }

      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('History',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          transactionsAsync.maybeWhen(
            data: (transactions) => IconButton(
              icon: const Icon(Icons.download, color: AppColors.textDark),
              tooltip: 'Export to CSV',
              onPressed: () => _exportTransactions(transactions),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search merchant, amount, or category...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(height: 12),

          // Filter Chips
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter,
                        style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textDark,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      }
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Colors.transparent),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Transaction List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                return ref.read(transactionListProvider.notifier).refresh();
              },
              child: transactionsAsync.when(
                data: (allTransactions) {
                  final filtered = _applyFiltersAndSearch(allTransactions);

                  if (filtered.isEmpty) {
                    return ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              const Text('No transactions found',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textLight)),
                              const SizedBox(height: 8),
                              const Text('Try adjusting your search or filters.',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final transaction = filtered[index];
                      return Dismissible(
                        key: Key(transaction.id.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: AppColors.error,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                      child: const Text("DELETE", style: TextStyle(color: AppColors.error))),
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
          ),
        ],
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
    final Color amountColor = isDebit ? AppColors.textDark : AppColors.secondary;
    final bool isUncategorized = !transaction.isCategorized;
    final Color categoryColor = _getColorForCategory(transaction.category, isUncategorized);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
        border: Border.all(
          color: isUncategorized ? Colors.amber.withValues(alpha: 0.3) : Colors.transparent,
          width: 1,
        )
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: categoryColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(_getIconForCategory(transaction.category, isUncategorized),
              color: categoryColor),
        ),
        title: Text(transaction.merchant,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isUncategorized ? 'Uncategorized' : transaction.category,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: categoryColor),
                  ),
                ),
                const SizedBox(width: 8),
                Text(DateFormat('dd MMM, hh:mm a').format(transaction.timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ],
        ),
        trailing: Text(
          '${isDebit ? '' : '+'}${AppStrings.currency}${transaction.amount.toStringAsFixed(0)}',
          style: TextStyle(
              color: amountColor, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) {
              return TransactionEditSheet(transaction: transaction);
            },
          );
        },
      ),
    );
  }

  Color _getColorForCategory(String category, bool isUncategorized) {
    if (isUncategorized) return Colors.amber;
    switch (category) {
      case 'Food':
        return Colors.orange;
      case 'Petrol':
        return Colors.blue;
      case 'Travel':
        return Colors.green;
      case 'Entertainment':
        return Colors.purple;
      case 'Maintenance':
        return Colors.teal;
      case 'Other':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForCategory(String category, bool isUncategorized) {
    if (isUncategorized) return Icons.help_outline;
    switch (category) {
      case 'Food':
        return Icons.fastfood;
      case 'Petrol':
        return Icons.local_gas_station;
      case 'Travel':
        return Icons.flight_takeoff;
      case 'Entertainment':
        return Icons.movie;
      case 'Maintenance':
        return Icons.home_repair_service;
      case 'Other':
        return Icons.category;
      default:
        return Icons.help_outline;
    }
  }
}
