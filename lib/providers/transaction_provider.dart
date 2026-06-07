import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/transaction_model.dart';
import '../data/repositories/transaction_repository.dart';

enum TimeFilter { today, thisWeek, thisMonth, customDate, allTime }

final timeFilterProvider = StateProvider<TimeFilter>((ref) => TimeFilter.thisMonth);

final customDateProvider = StateProvider<DateTime?>((ref) => null);

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

  Future<void> categorizeTransaction(int id, String category) async {
    final currentList = state.value;
    if (currentList != null) {
      final index = currentList.indexWhere((t) => t.id == id);
      if (index != -1) {
        final transaction = currentList[index].copyWith(
          category: category,
          isCategorized: true,
        );
        await _repository.updateTransaction(transaction);
        ref.invalidateSelf();
      }
    }
  }
}

bool _matchesTimeFilter(DateTime timestamp, TimeFilter filter) {
  final now = DateTime.now();
  switch (filter) {
    case TimeFilter.today:
      return timestamp.year == now.year &&
          timestamp.month == now.month &&
          timestamp.day == now.day;
    case TimeFilter.thisWeek:
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      return timestamp.isAfter(start.subtract(const Duration(seconds: 1)));
    case TimeFilter.thisMonth:
      return timestamp.year == now.year && timestamp.month == now.month;
    case TimeFilter.allTime:
      return true;
    case TimeFilter.customDate:
      return true; // we will handle custom date logic in the provider
  }
}

// Filtered and Categorized Transactions ONLY (Expenses)
final filteredExpensesProvider = Provider<AsyncValue<List<TransactionModel>>>((ref) {
  final transactions = ref.watch(transactionListProvider);
  final timeFilter = ref.watch(timeFilterProvider);
  final customDate = ref.watch(customDateProvider);

  return transactions.whenData((list) {
    return list.where((t) {
      bool isExpense = t.type == 'DEBIT';
      bool categorized = t.isCategorized;
      bool matchesTime = _matchesTimeFilter(t.timestamp, timeFilter);
      if (timeFilter == TimeFilter.customDate && customDate != null) {
        matchesTime = t.timestamp.year == customDate.year &&
            t.timestamp.month == customDate.month &&
            t.timestamp.day == customDate.day;
      }
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
  return expenses.whenData((list) {
    final Map<String, double> breakdown = {};
    for (var t in list) {
      breakdown[t.category] = (breakdown[t.category] ?? 0) + t.amount;
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
  final timeFilter = ref.watch(timeFilterProvider);
  
  return expenses.whenData((list) {
    if (list.isEmpty) return 0.0;
    
    final total = list.fold(0.0, (sum, item) => sum + item.amount);
    int days = 1;
    final now = DateTime.now();
    
    switch (timeFilter) {
      case TimeFilter.today:
        days = 1;
        break;
      case TimeFilter.thisWeek:
        days = now.weekday; // days elapsed in current week
        break;
      case TimeFilter.thisMonth:
        days = now.day; // days elapsed in current month
        break;
      case TimeFilter.customDate:
        days = 1;
        break;
      case TimeFilter.allTime:
        // calculate from oldest transaction
        if (list.isNotEmpty) {
          final oldest = list.map((e) => e.timestamp).reduce((a, b) => a.isBefore(b) ? a : b);
          days = now.difference(oldest).inDays + 1;
        }
        break;
    }
    
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
// Precomputes the total expenses for each day of the current month.
final monthlyDailyAggregatesProvider = Provider<AsyncValue<Map<int, double>>>((ref) {
  final transactions = ref.watch(transactionListProvider);
  final customDate = ref.watch(customDateProvider);
  final filter = ref.watch(timeFilterProvider);
  
  return transactions.whenData((list) {
    final Map<int, double> dailyTotals = {};
    final targetDate = (filter == TimeFilter.customDate && customDate != null) 
        ? customDate 
        : DateTime.now();
        
    for (var t in list) {
      if (t.type == 'DEBIT' && t.timestamp.year == targetDate.year && t.timestamp.month == targetDate.month) {
        dailyTotals[t.timestamp.day] = (dailyTotals[t.timestamp.day] ?? 0.0) + t.amount;
      }
    }
    return dailyTotals;
  });
});

final monthlyInsightsProvider = Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final aggregates = ref.watch(monthlyDailyAggregatesProvider);
  final breakdown = ref.watch(categoryBreakdownProvider); // based on current filter (usually This Month)
  
  return aggregates.whenData((map) {
    double highest = 0.0;
    int highestDay = 1;
    double lowest = double.infinity;
    int lowestDay = 1;
    
    final now = DateTime.now();
    int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    int noSpendDays = daysInMonth - map.length;
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
      'avg_daily_spend': totalSpend / daysInMonth,
      'most_expensive_category': highestCategoryName,
      'most_expensive_category_amount': highestCategoryAmount,
    };
  });
});
