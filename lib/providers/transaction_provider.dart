import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/transaction_model.dart';
import '../data/models/category_model.dart';
import '../data/repositories/transaction_repository.dart';
import 'categories_provider.dart';

enum TimeFilter { today, month, custom }

final timeFilterProvider = StateProvider<TimeFilter>((ref) => TimeFilter.month);
final customDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

final dateRangeProvider = Provider<DateTimeRange>((ref) {
  final filter = ref.watch(timeFilterProvider);
  final now = DateTime.now();

  switch (filter) {
    case TimeFilter.today:
      return DateTimeRange(
        start: DateTime(now.year, now.month, now.day),
        end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      );
    case TimeFilter.month:
      return DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
      );
    case TimeFilter.custom:
      final customRange = ref.watch(customDateRangeProvider);
      if (customRange != null) return customRange;
      return DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
      );
  }
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

final transactionListProvider =
    AsyncNotifierProvider<TransactionNotifier, List<TransactionModel>>(() {
  return TransactionNotifier();
});

class TransactionNotifier extends AsyncNotifier<List<TransactionModel>> {
  late TransactionRepository _repository;

  @override
  Future<List<TransactionModel>> build() async {
    _repository = ref.read(transactionRepositoryProvider);
    return _fetchTransactions();
  }

  Future<List<TransactionModel>> _fetchTransactions() async {
    return await _repository.getAllTransactions();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchTransactions());
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await _repository.addTransaction(transaction);
    ref.invalidateSelf(); // Refresh list
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _repository.updateTransaction(transaction);
    ref.invalidateSelf();
  }

  Future<void> deleteTransaction(int id) async {
    await _repository.deleteTransaction(id);
    ref.invalidateSelf();
  }

  Future<void> categorizeTransaction(int id, int categoryId) async {
    final currentList = state.value;
    if (currentList != null) {
      final index = currentList.indexWhere((t) => t.id == id);
      if (index != -1) {
        final transaction = currentList[index].copyWith(
          categoryId: categoryId,
          isCategorized: true,
        );
        await _repository.updateTransaction(transaction);
        ref.invalidateSelf();
      }
    }
  }
}

// Filtered and Categorized Transactions ONLY (Expenses)
final filteredExpensesProvider = Provider<AsyncValue<List<TransactionModel>>>((ref) {
  final transactions = ref.watch(transactionListProvider);
  final dateRange = ref.watch(dateRangeProvider);

  return transactions.whenData((list) {
    return list.where((t) {
      bool isExpense = t.type == 'DEBIT';
      bool categorized = t.isCategorized;
      bool matchesTime = t.timestamp.isAfter(dateRange.start.subtract(const Duration(seconds: 1))) &&
          t.timestamp.isBefore(dateRange.end.add(const Duration(seconds: 1)));
      
      return isExpense && categorized && matchesTime;
    }).toList();
  });
});

final totalExpenseProvider = Provider<AsyncValue<double>>((ref) {
  final expenses = ref.watch(filteredExpensesProvider);
  return expenses.whenData((list) {
    return list.fold(0.0, (sum, item) => sum + item.amount);
  });
});

final categoryBreakdownProvider = Provider<AsyncValue<Map<String, double>>>((ref) {
  final expenses = ref.watch(filteredExpensesProvider);
  final categories = ref.watch(categoriesProvider);

  return expenses.whenData((list) {
    final Map<String, double> breakdown = {};
    for (var t in list) {
      final category = categories.firstWhere(
        (c) => c.id == t.categoryId,
        orElse: () => CategoryModel(id: 6, name: 'Other', icon: '📦', color: '0xFF9E9E9E', isDefault: true),
      );
      breakdown[category.name] = (breakdown[category.name] ?? 0) + t.amount;
    }
    return breakdown;
  });
});

// Analytics Summary Providers
final mostSpendingCategoryProvider = Provider<AsyncValue<MapEntry<String, double>?>>((ref) {
  final breakdown = ref.watch(categoryBreakdownProvider);
  return breakdown.whenData((map) {
    if (map.isEmpty) return null;
    return map.entries.reduce((a, b) => a.value > b.value ? a : b);
  });
});

final biggestExpenseProvider = Provider<AsyncValue<double>>((ref) {
  final expenses = ref.watch(filteredExpensesProvider);
  return expenses.whenData((list) {
    if (list.isEmpty) return 0.0;
    return list.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
  });
});

final averageDailySpendingProvider = Provider<AsyncValue<double>>((ref) {
  final expenses = ref.watch(filteredExpensesProvider);
  final dateRange = ref.watch(dateRangeProvider);
  
  return expenses.whenData((list) {
    if (list.isEmpty) return 0.0;
    
    final total = list.fold(0.0, (sum, item) => sum + item.amount);
    int days = dateRange.end.difference(dateRange.start).inDays + 1;
    
    return total / (days > 0 ? days : 1);
  });
});

final transactionsCountProvider = Provider<AsyncValue<int>>((ref) {
  final expenses = ref.watch(filteredExpensesProvider);
  return expenses.whenData((list) => list.length);
});

// For history screen
final uncategorizedTransactionsProvider = Provider<AsyncValue<List<TransactionModel>>>((ref) {
  final transactions = ref.watch(transactionListProvider);
  return transactions.whenData((list) => list.where((t) => !t.isCategorized).toList());
});

final recentTransactionsProvider = Provider<AsyncValue<List<TransactionModel>>>((ref) {
  final expenses = ref.watch(filteredExpensesProvider);
  return expenses.whenData((list) => list.take(5).toList());
});

// Heatmap Calendar Providers
// Precomputes the total expenses for each day of the selected month/range.
final monthlyDailyAggregatesProvider = Provider<AsyncValue<Map<int, double>>>((ref) {
  final transactions = ref.watch(transactionListProvider);
  final dateRange = ref.watch(dateRangeProvider);
  
  return transactions.whenData((list) {
    final Map<int, double> dailyTotals = {};
        
    for (var t in list) {
      if (t.type == 'DEBIT' &&
          t.timestamp.isAfter(dateRange.start.subtract(const Duration(seconds: 1))) &&
          t.timestamp.isBefore(dateRange.end.add(const Duration(seconds: 1)))) {
        // Just storing day of month might overlap if date range > 1 month, but we assume it's for heatmap per month.
        // If they select multiple months, day overlaps. Let's use string YYYY-MM-DD or DateTime for key.
        // But existing heatmap uses `int` day. We will stick to `int` day if range is <= 1 month.
        dailyTotals[t.timestamp.day] = (dailyTotals[t.timestamp.day] ?? 0.0) + t.amount;
      }
    }
    return dailyTotals;
  });
});

final monthlyInsightsProvider = Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final aggregates = ref.watch(monthlyDailyAggregatesProvider);
  final breakdown = ref.watch(categoryBreakdownProvider); 
  final dateRange = ref.watch(dateRangeProvider);
  
  return aggregates.whenData((map) {
    double highest = 0.0;
    int highestDay = 1;
    double lowest = double.infinity;
    int lowestDay = 1;
    
    int daysInRange = dateRange.end.difference(dateRange.start).inDays + 1;
    int noSpendDays = daysInRange - map.length;
    if (noSpendDays < 0) noSpendDays = 0;
    double totalSpend = 0.0;
    
    if (map.isNotEmpty) {
      map.forEach((day, amount) {
        if (amount > highest) {
          highest = amount;
          highestDay = day;
        }
        if (amount < lowest) {
          lowest = amount;
          lowestDay = day;
        }
        totalSpend += amount;
      });
    } else {
      lowest = 0.0;
    }
    
    String highestCategoryName = 'None';
    double highestCategoryAmount = 0.0;
    
    breakdown.whenData((cats) {
      if (cats.isNotEmpty) {
        final topCat = cats.entries.reduce((a, b) => a.value > b.value ? a : b);
        highestCategoryName = topCat.key;
        highestCategoryAmount = topCat.value;
      }
    });

    return {
      'highest_day': highestDay,
      'highest_amount': highest,
      'lowest_day': lowest == double.infinity ? 0 : lowestDay,
      'lowest_amount': lowest == double.infinity ? 0.0 : lowest,
      'no_spend_days': noSpendDays,
      'avg_daily_spend': totalSpend / (daysInRange > 0 ? daysInRange : 1),
      'most_expensive_category': highestCategoryName,
      'most_expensive_category_amount': highestCategoryAmount,
    };
  });
});

