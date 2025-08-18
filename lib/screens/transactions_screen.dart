import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../widgets/transaction_card.dart';
import '../widgets/budget_overview_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/dashboard_card.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  TransactionType? _filterType;
  String? _filterCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.error.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.initialize(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Transactions',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _showAddTransactionDialog(context),
                  ),
                ],
              ),

              // Dashboard Overview
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DashboardCard(
                    transactions: provider.transactions,
                    selectedMonth: provider.selectedDate,
                  ),
                ),
              ),
              
              // Budget Overview
              if (provider.currentBudget != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: BudgetOverviewCard(budget: provider.currentBudget!),
                  ),
                ),

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SearchBarWidget(
                    controller: _searchController,
                    onChanged: (query) {
                      setState(() {
                        _searchQuery = query;
                      });
                    },
                  ),
                ),
              ),

              // Filter Chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildFilterChips(provider),
                ),
              ),

              // Unlabeled Transactions Section
              SliverToBoxAdapter(
                child: _buildUnlabeledTransactionsSection(provider),
              ),
              
              // Transactions List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: _buildTransactionsList(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChips(AppProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Type filters
          FilterChip(
            label: const Text('All'),
            selected: _filterType == null,
            onSelected: (selected) {
              setState(() {
                _filterType = null;
              });
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Income'),
            selected: _filterType == TransactionType.credit,
            onSelected: (selected) {
              setState(() {
                _filterType = selected ? TransactionType.credit : null;
              });
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Expenses'),
            selected: _filterType == TransactionType.debit,
            onSelected: (selected) {
              setState(() {
                _filterType = selected ? TransactionType.debit : null;
              });
            },
          ),
          const SizedBox(width: 16),
          
          // Category filters
          ...provider.categories.take(5).map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(category.name),
                selected: _filterCategory == category.id,
                onSelected: (selected) {
                  setState(() {
                    _filterCategory = selected ? category.id : null;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildUnlabeledTransactionsSection(AppProvider provider) {
    // Get uncategorized transactions
    List<Transaction> unlabeledTransactions = provider.transactions
        .where((t) => !t.isCategorized)
        .toList();
    
    if (unlabeledTransactions.isEmpty) {
      return const SizedBox.shrink(); // Don't show section if no unlabeled transactions
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.label_off_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Unlabeled Transactions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: unlabeledTransactions.length,
              itemBuilder: (context, index) {
                return TransactionCard(
                  transaction: unlabeledTransactions[index],
                  onTap: () => _showCategorySelectionDialog(context, unlabeledTransactions[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(AppProvider provider) {
    List<Transaction> transactions = provider.transactions;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      transactions = transactions.where((transaction) {
        return transaction.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               transaction.bankName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply type filter
    if (_filterType != null) {
      transactions = transactions.where((transaction) => transaction.type == _filterType).toList();
    }

    // Apply category filter
    if (_filterCategory != null) {
      transactions = transactions.where((transaction) => transaction.category == _filterCategory).toList();
    }

    if (transactions.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No transactions found',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your transactions will appear here',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Group transactions by date
    Map<String, List<Transaction>> groupedTransactions = {};
    for (Transaction transaction in transactions) {
      String dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
      if (!groupedTransactions.containsKey(dateKey)) {
        groupedTransactions[dateKey] = [];
      }
      groupedTransactions[dateKey]!.add(transaction);
    }

    List<String> sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          String dateKey = sortedDates[index];
          List<Transaction> dayTransactions = groupedTransactions[dateKey]!;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  _formatDate(dateKey),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              ...dayTransactions.map((transaction) => 
                TransactionCard(
                  transaction: transaction,
                  category: provider.getCategoryById(transaction.category),
                  onTap: () => _showTransactionDetails(context, transaction),
                ),
              ),
            ],
          );
        },
        childCount: sortedDates.length,
      ),
    );
  }

  String _formatDate(String dateKey) {
    DateTime date = DateTime.parse(dateKey);
    DateTime now = DateTime.now();
    DateTime yesterday = now.subtract(const Duration(days: 1));

    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, MMMM d').format(date);
    }
  }

  void _showAddTransactionDialog(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    TransactionType selectedType = TransactionType.debit;
    Category? selectedCategory;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Transaction'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '₹',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Type: '),
                      Expanded(
                        child: SegmentedButton<TransactionType>(
                          segments: const [
                            ButtonSegment(
                              value: TransactionType.debit,
                              label: Text('Debit'),
                              icon: Icon(Icons.remove),
                            ),
                            ButtonSegment(
                              value: TransactionType.credit,
                              label: Text('Credit'),
                              icon: Icon(Icons.add),
                            ),
                          ],
                          selected: {selectedType},
                          onSelectionChanged: (Set<TransactionType> selection) {
                            setState(() {
                              selectedType = selection.first;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Category>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                    ),
                    items: context.read<AppProvider>().categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            Icon(category.iconData, color: category.colorValue),
                            const SizedBox(width: 8),
                            Text(category.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (Category? value) {
                      setState(() {
                        selectedCategory = value;
                      });
                    },
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (amountController.text.isNotEmpty && 
                  descriptionController.text.isNotEmpty &&
                  selectedCategory != null) {
                final transaction = Transaction(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  amount: double.parse(amountController.text),
                  type: selectedType,
                  category: selectedCategory!.id,
                  description: descriptionController.text,
                  date: DateTime.now(),
                  balance: 0, // Will be calculated
                  bankName: 'Manual Entry',
                  isCategorized: true,
                  smsBody: '',
                );
                
                context.read<AppProvider>().addTransaction(transaction);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(BuildContext context, Transaction transaction) {
    final provider = context.read<AppProvider>();
    final category = provider.getCategoryById(transaction.category);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            if (category != null) 
              Icon(category.iconData, color: category.colorValue),
            const SizedBox(width: 8),
            const Text('Transaction Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Amount', '₹${transaction.amount.toStringAsFixed(2)}', 
              color: transaction.type == TransactionType.credit ? Colors.green : Colors.red),
            _buildDetailRow('Type', transaction.type.name.toUpperCase()),
            _buildDetailRow('Category', category?.name ?? 'Uncategorized'),
            _buildDetailRow('Description', transaction.description),
            _buildDetailRow('Date', DateFormat('MMM d, yyyy HH:mm').format(transaction.date)),
            _buildDetailRow('Balance', '₹${transaction.balance.toStringAsFixed(2)}'),
            if (transaction.bankName.isNotEmpty)
              _buildDetailRow('Bank', transaction.bankName),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (!transaction.isCategorized)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showCategorySelectionDialog(context, transaction);
              },
              child: const Text('Categorize'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: color),
            ),
          ),
        ],
      ),
    );
  }

  void _showCategorySelectionDialog(BuildContext context, Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer<AppProvider>(builder: (context, provider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Category',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${transaction.amount.toStringAsFixed(2)} ${transaction.type == TransactionType.credit ? 'Credit' : 'Debit'} - ${transaction.description}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: provider.categories.map((category) {
                    return InkWell(
                      onTap: () {
                        provider.categorizeTransaction(transaction.id, category.id);
                        Navigator.pop(context);
                      },
                      child: Chip(
                        avatar: Icon(
                          category.iconData,
                          size: 18,
                          color: Color(category.color),
                        ),
                        label: Text(category.name),
                        backgroundColor: Color(category.color).withOpacity(0.2),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}
