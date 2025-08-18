import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/category.dart';

class StorageService {
  static const String _transactionsBox = 'transactions';
  static const String _budgetsBox = 'budgets';
  static const String _categoriesBox = 'categories';

  static late Box<Transaction> _transactionsBoxInstance;
  static late Box<Budget> _budgetsBoxInstance;
  static late Box<Category> _categoriesBoxInstance;

  static Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Register adapters
    Hive.registerAdapter(TransactionAdapter());
    Hive.registerAdapter(TransactionTypeAdapter());
    Hive.registerAdapter(BudgetAdapter());
    Hive.registerAdapter(CategoryAdapter());
    
    // Open boxes
    _transactionsBoxInstance = await Hive.openBox<Transaction>(_transactionsBox);
    _budgetsBoxInstance = await Hive.openBox<Budget>(_budgetsBox);
    _categoriesBoxInstance = await Hive.openBox<Category>(_categoriesBox);
    
    // Initialize default categories if empty
    await _initializeDefaultCategories();
  }

  static Future<void> _initializeDefaultCategories() async {
    if (_categoriesBoxInstance.isEmpty) {
      for (Category category in Category.defaultCategories) {
        await _categoriesBoxInstance.put(category.id, category);
      }
    }
  }

  // Transaction operations
  static Future<void> addTransaction(Transaction transaction) async {
    await _transactionsBoxInstance.put(transaction.id, transaction);
  }

  static Future<void> updateTransaction(Transaction transaction) async {
    await _transactionsBoxInstance.put(transaction.id, transaction);
  }

  static Future<void> deleteTransaction(String id) async {
    await _transactionsBoxInstance.delete(id);
  }

  static List<Transaction> getAllTransactions() {
    return _transactionsBoxInstance.values.toList();
  }

  static List<Transaction> getTransactionsByMonth(int year, int month) {
    return _transactionsBoxInstance.values
        .where((transaction) => 
            transaction.date.year == year && transaction.date.month == month)
        .toList();
  }

  static List<Transaction> getTransactionsByCategory(String categoryId) {
    return _transactionsBoxInstance.values
        .where((transaction) => transaction.category == categoryId)
        .toList();
  }

  static Transaction? getTransactionById(String id) {
    return _transactionsBoxInstance.get(id);
  }

  // Budget operations
  static Future<void> addBudget(Budget budget) async {
    await _budgetsBoxInstance.put(budget.id, budget);
  }

  static Future<void> updateBudget(Budget budget) async {
    await _budgetsBoxInstance.put(budget.id, budget);
  }

  static Future<void> deleteBudget(String id) async {
    await _budgetsBoxInstance.delete(id);
  }

  static List<Budget> getAllBudgets() {
    return _budgetsBoxInstance.values.toList();
  }

  static Budget? getBudgetByMonth(int year, int month) {
    return _budgetsBoxInstance.values
        .where((budget) => budget.year == year && budget.month == month)
        .firstOrNull;
  }

  static Future<void> updateBudgetSpent(String budgetId, double spent) async {
    Budget? budget = _budgetsBoxInstance.get(budgetId);
    if (budget != null) {
      budget.spent = spent;
      await _budgetsBoxInstance.put(budgetId, budget);
    }
  }

  // Category operations
  static Future<void> addCategory(Category category) async {
    await _categoriesBoxInstance.put(category.id, category);
  }

  static Future<void> updateCategory(Category category) async {
    await _categoriesBoxInstance.put(category.id, category);
  }

  static Future<void> deleteCategory(String id) async {
    // Don't allow deletion of default categories
    Category? category = _categoriesBoxInstance.get(id);
    if (category != null && !category.isDefault) {
      await _categoriesBoxInstance.delete(id);
    }
  }

  static List<Category> getAllCategories() {
    return _categoriesBoxInstance.values.toList();
  }

  static Category? getCategoryById(String id) {
    return _categoriesBoxInstance.get(id);
  }

  // Analytics methods
  static Map<String, double> getCategorySpending(int year, int month) {
    List<Transaction> transactions = getTransactionsByMonth(year, month);
    Map<String, double> categorySpending = {};
    
    for (Transaction transaction in transactions) {
      if (transaction.type == TransactionType.debit) {
        categorySpending[transaction.category] = 
            (categorySpending[transaction.category] ?? 0) + transaction.amount;
      }
    }
    
    return categorySpending;
  }

  static Map<String, double> getMonthlySpending(int year) {
    Map<String, double> monthlySpending = {};
    
    for (int month = 1; month <= 12; month++) {
      List<Transaction> transactions = getTransactionsByMonth(year, month);
      double totalSpent = transactions
          .where((t) => t.type == TransactionType.debit)
          .fold(0.0, (sum, t) => sum + t.amount);
      monthlySpending[month.toString()] = totalSpent;
    }
    
    return monthlySpending;
  }

  static double getTotalIncome(int year, int month) {
    List<Transaction> transactions = getTransactionsByMonth(year, month);
    return transactions
        .where((t) => t.type == TransactionType.credit)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  static double getTotalExpenses(int year, int month) {
    List<Transaction> transactions = getTransactionsByMonth(year, month);
    return transactions
        .where((t) => t.type == TransactionType.debit)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  static double getCurrentBalance() {
    List<Transaction> transactions = getAllTransactions();
    if (transactions.isEmpty) return 0.0;
    
    // Get the most recent transaction's balance
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions.first.balance;
  }

  // Search methods
  static List<Transaction> searchTransactions(String query) {
    return _transactionsBoxInstance.values
        .where((transaction) =>
            transaction.description.toLowerCase().contains(query.toLowerCase()) ||
            transaction.bankName.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Export/Import methods (for future use)
  static Map<String, dynamic> exportData() {
    return {
      'transactions': getAllTransactions().map((t) => t.toJson()).toList(),
      'budgets': getAllBudgets().map((b) => b.toJson()).toList(),
      'categories': getAllCategories().map((c) => c.toJson()).toList(),
    };
  }

  static Future<void> importData(Map<String, dynamic> data) async {
    // Clear existing data
    await _transactionsBoxInstance.clear();
    await _budgetsBoxInstance.clear();
    await _categoriesBoxInstance.clear();
    
    // Import new data
    if (data['transactions'] != null) {
      for (Map<String, dynamic> transactionData in data['transactions']) {
        Transaction transaction = Transaction.fromJson(transactionData);
        await addTransaction(transaction);
      }
    }
    
    if (data['budgets'] != null) {
      for (Map<String, dynamic> budgetData in data['budgets']) {
        Budget budget = Budget.fromJson(budgetData);
        await addBudget(budget);
      }
    }
    
    if (data['categories'] != null) {
      for (Map<String, dynamic> categoryData in data['categories']) {
        Category category = Category.fromJson(categoryData);
        await addCategory(category);
      }
    }
  }

  static Future<void> clearAllData() async {
    await _transactionsBoxInstance.clear();
    await _budgetsBoxInstance.clear();
    await _categoriesBoxInstance.clear();
    await _initializeDefaultCategories();
  }

  static Future<void> close() async {
    await _transactionsBoxInstance.close();
    await _budgetsBoxInstance.close();
    await _categoriesBoxInstance.close();
  }
}
