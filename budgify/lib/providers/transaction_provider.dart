import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/transaction_model.dart';
import '../data/repositories/transaction_repository.dart';

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
    // Optimistic update or fetch-update
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

// Derived providers
final uncategorizedTransactionsProvider =
    Provider<AsyncValue<List<TransactionModel>>>((ref) {
  final transactions = ref.watch(transactionListProvider);
  return transactions
      .whenData((list) => list.where((t) => !t.isCategorized).toList());
});

final recentTransactionsProvider =
    Provider<AsyncValue<List<TransactionModel>>>((ref) {
  final transactions = ref.watch(transactionListProvider);
  return transactions.whenData((list) => list.take(5).toList());
});

// Insights Providers
final categoryBreakdownProvider =
    Provider<AsyncValue<Map<String, double>>>((ref) {
  final transactions = ref.watch(transactionListProvider);
  return transactions.whenData((list) {
    final Map<String, double> breakdown = {};
    for (var t in list) {
      if (t.type == 'DEBIT' && t.category != 'Uncategorized') {
        breakdown[t.category] = (breakdown[t.category] ?? 0) + t.amount;
      }
    }
    return breakdown;
  });
});

final incomeExpenseProvider = Provider<AsyncValue<Map<String, double>>>((ref) {
  final transactions = ref.watch(transactionListProvider);
  return transactions.whenData((list) {
    double income = 0;
    double expense = 0;
    for (var t in list) {
      if (t.type == 'CREDIT') income += t.amount;
      if (t.type == 'DEBIT') expense += t.amount;
    }
    return {'income': income, 'expense': expense};
  });
});
