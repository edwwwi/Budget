import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../data/models/transaction_model.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../providers/categories_provider.dart';
import '../../data/models/category_model.dart';

class DayDetailModal extends ConsumerWidget {
  final DateTime date;
  final double totalSpent;

  const DayDetailModal({
    super.key,
    required this.date,
    required this.totalSpent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionListProvider);
    final categories = ref.watch(categoriesProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMMM d, yyyy').format(date),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Total Spent', style: TextStyle(color: Colors.grey)),
                ],
              ),
              Text(
                '₹${totalSpent.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          
          transactionsAsync.when(
            data: (list) {
              // Filter to today's expenses
              final todaysExpenses = list.where((t) {
                return t.type == 'DEBIT' &&
                       t.isCategorized &&
                       t.timestamp.year == date.year &&
                       t.timestamp.month == date.month &&
                       t.timestamp.day == date.day;
              }).toList();

              if (todaysExpenses.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No expenses recorded for this day.', style: TextStyle(color: Colors.grey)),
                  ),
                );
              }

              // Calculate Breakdown
              final Map<CategoryModel, double> breakdown = {};
              for (var t in todaysExpenses) {
                final category = categories.firstWhere(
                  (c) => c.id == t.categoryId,
                  orElse: () => CategoryModel(id: 6, name: 'Other', icon: '📦', color: '0xFF9E9E9E', isDefault: true),
                );
                breakdown[category] = (breakdown[category] ?? 0.0) + t.amount;
              }

              return ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                child: ListView(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    const Text('Category Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    ...breakdown.entries.map((e) => _buildCategoryRow(e.key, e.value)),
                    
                    const SizedBox(height: 24),
                    const Text('Transactions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    ...todaysExpenses.map((t) {
                      final category = categories.firstWhere(
                        (c) => c.id == t.categoryId,
                        orElse: () => CategoryModel(id: 6, name: 'Other', icon: '📦', color: '0xFF9E9E9E', isDefault: true),
                      );
                      return _buildTransactionRow(t, category);
                    }),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('Error: $e'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(CategoryModel category, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(category.icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(category.name, style: const TextStyle(fontSize: 14)),
            ],
          ),
          Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(TransactionModel t, CategoryModel category) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.grey.shade100,
        child: Text(category.icon, style: const TextStyle(fontSize: 18)),
      ),
      title: Text(t.merchant, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(DateFormat('hh:mm a').format(t.timestamp), style: const TextStyle(fontSize: 12)),
      trailing: Text('₹${t.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
