import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../services/storage_service.dart';
import '../services/sms_service.dart';
import '../services/notification_service.dart';

class AppProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  List<Budget> _budgets = [];
  List<Category> _categories = [];
  Budget? _currentBudget;
  bool _isLoading = false;
  String _error = '';
  DateTime _selectedDate = DateTime.now();
  StreamSubscription<Transaction>? _smsSubscription;
  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;

  // Getters
  List<Transaction> get transactions => _transactions;
  List<Budget> get budgets => _budgets;
  List<Category> get categories => _categories;
  Budget? get currentBudget => _currentBudget;
  bool get isLoading => _isLoading;
  String get error => _error;
  DateTime get selectedDate => _selectedDate;
  
  // Getter for SmsService (for testing)
  SmsService get smsService => SmsService.instance;
  
  // Public method to add a transaction directly (for testing)
  Future<void> addTransaction(Transaction transaction) async {
    print('Adding transaction manually: ${transaction.description} - ₹${transaction.amount}');
    
    // Add transaction to storage
    await StorageService.addTransaction(transaction);
    
    // Add to current list
    _transactions.add(transaction);
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    
    // Update budget if it's a debit transaction
    if (transaction.type == TransactionType.debit && _currentBudget != null) {
      _currentBudget!.spent += transaction.amount;
      await StorageService.updateBudget(_currentBudget!);
    }
    
    // Show notification
    try {
      await NotificationService.showTransactionNotification(transaction);
      print('Notification sent for transaction');
    } catch (e) {
      print('Failed to show notification: $e');
    }
    
    notifyListeners();
  }

  // Initialize the app
  Future<void> initialize() async {
    _setLoading(true);
    try {
      print('Initializing app...');
      
      // Initialize services
      await StorageService.initialize();
      print('Storage service initialized');
      
      await NotificationService.initialize();
      print('Notification service initialized');
      
      // Load data
      await _loadData();
      print('Data loaded');
      
      // Request permissions first
      await _requestInitialPermissions();
      
      // Start SMS listening
      await _startSmsListening();
      
      // Start notification listening
      _startNotificationListening();
      
      _setError('');
      print('App initialization completed');
    } catch (e) {
      print('App initialization failed: $e');
      _setError('Failed to initialize app: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _requestInitialPermissions() async {
    try {
      print('Requesting initial permissions...');
      
      // Request SMS permissions
      bool smsGranted = await SmsService.requestPermissions();
      print('SMS permissions granted: $smsGranted');
      
      // Request notification permissions
      await NotificationService.requestNotificationPermissions();
      print('Notification permissions requested');
      
    } catch (e) {
      print('Error requesting initial permissions: $e');
    }
  }

  Future<void> _loadData() async {
    _transactions = StorageService.getAllTransactions();
    _budgets = StorageService.getAllBudgets();
    _categories = StorageService.getAllCategories();
    
    // Set current budget
    _currentBudget = StorageService.getBudgetByMonth(
      _selectedDate.year, 
      _selectedDate.month
    );
    
    notifyListeners();
  }

  Future<void> _startSmsListening() async {
    try {
      print('Starting SMS listening...');
      await SmsService.startListening();
      _smsSubscription = SmsService.transactionStream.listen(_onNewTransaction);
      print('SMS listening started successfully');
    } catch (e) {
      print('SMS listening failed: $e');
      _setError('SMS listening failed: $e');
    }
  }

  void _startNotificationListening() {
    _notificationSubscription = NotificationService.notificationActionStream
        .listen(_onNotificationAction);
  }

  void _onNewTransaction(Transaction transaction) async {
    print('New transaction detected: ${transaction.description} - ₹${transaction.amount}');
    
    // Add transaction to storage
    await StorageService.addTransaction(transaction);
    
    // Add to current list
    _transactions.add(transaction);
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    
    // Update budget if it's a debit transaction
    if (transaction.type == TransactionType.debit && _currentBudget != null) {
      _currentBudget!.spent += transaction.amount;
      await StorageService.updateBudget(_currentBudget!);
    }
    
    // Show notification
    try {
      await NotificationService.showTransactionNotification(transaction);
      print('Notification sent for transaction');
    } catch (e) {
      print('Failed to show notification: $e');
    }
    
    notifyListeners();
  }

  // Method to manually request SMS permissions
  Future<bool> requestSmsPermissions() async {
    try {
      print('Requesting SMS permissions...');
      bool granted = await SmsService.requestPermissions();
      if (granted) {
        print('SMS permissions granted, starting listening...');
        await _startSmsListening();
        _setError('');
      } else {
        _setError('SMS permissions not granted');
      }
      return granted;
    } catch (e) {
      print('Error requesting SMS permissions: $e');
      _setError('Failed to request SMS permissions: $e');
      return false;
    }
  }

  // Method to check current permission status
  Future<Map<String, bool>> checkPermissionStatus() async {
    try {
      PermissionStatus smsStatus = await Permission.sms.status;
      PermissionStatus phoneStatus = await Permission.phone.status;
      
      return {
        'sms': smsStatus == PermissionStatus.granted,
        'phone': phoneStatus == PermissionStatus.granted,
      };
    } catch (e) {
      print('Error checking permission status: $e');
      return {'sms': false, 'phone': false};
    }
  }

  // Transaction methods

  Future<void> updateTransaction(Transaction transaction) async {
    await StorageService.updateTransaction(transaction);
    
    int index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _transactions[index] = transaction;
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(String id) async {
    Transaction? transaction = StorageService.getTransactionById(id);
    if (transaction != null && transaction.type == TransactionType.debit && _currentBudget != null) {
      _currentBudget!.spent -= transaction.amount;
      await StorageService.updateBudget(_currentBudget!);
    }
    
    await StorageService.deleteTransaction(id);
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future<void> categorizeTransaction(String transactionId, String categoryId) async {
    final transaction = _transactions.firstWhere((t) => t.id == transactionId);
    final updatedTransaction = transaction.copyWith(
      category: categoryId,
      isCategorized: true,
    );
    await updateTransaction(updatedTransaction);
  }

  void _onNotificationAction(Map<String, dynamic> action) async {
    print('Notification action received: $action');
    String transactionId = action['transactionId'];
    String actionType = action['action'] ?? '';
    
    if (actionType == 'categorize' && action.containsKey('categoryId')) {
      String categoryId = action['categoryId'];
      print('Categorizing transaction $transactionId with category $categoryId');
      
      // Update transaction category
      Transaction? transaction = StorageService.getTransactionById(transactionId);
      if (transaction != null) {
        transaction.category = categoryId;
        transaction.isCategorized = true;
        await StorageService.updateTransaction(transaction);
        
        // Update in current list
        int index = _transactions.indexWhere((t) => t.id == transactionId);
        if (index != -1) {
          _transactions[index] = transaction;
          notifyListeners();
        }
        
        print('Transaction categorized successfully');
      } else {
        print('Transaction not found: $transactionId');
      }
    } else if (actionType == 'view') {
      print('View transaction requested: $transactionId');
      // Handle view transaction action (could navigate to transaction details)
      // This will be handled by the UI when we implement it
    }
  }



  List<Transaction> getTransactionsByMonth(int year, int month) {
    return _transactions.where((t) => 
        t.date.year == year && t.date.month == month).toList();
  }

  // Budget methods
  Future<void> addBudget(Budget budget) async {
    await StorageService.addBudget(budget);
    _budgets.add(budget);
    
    if (budget.year == _selectedDate.year && budget.month == _selectedDate.month) {
      _currentBudget = budget;
    }
    
    notifyListeners();
  }

  Future<void> updateBudget(Budget budget) async {
    await StorageService.updateBudget(budget);
    
    int index = _budgets.indexWhere((b) => b.id == budget.id);
    if (index != -1) {
      _budgets[index] = budget;
    }
    
    if (budget.year == _selectedDate.year && budget.month == _selectedDate.month) {
      _currentBudget = budget;
    }
    
    notifyListeners();
  }

  Future<void> deleteBudget(String id) async {
    await StorageService.deleteBudget(id);
    _budgets.removeWhere((b) => b.id == id);
    
    if (_currentBudget?.id == id) {
      _currentBudget = null;
    }
    
    notifyListeners();
  }

  // Category methods
  Future<void> addCategory(Category category) async {
    await StorageService.addCategory(category);
    _categories.add(category);
    notifyListeners();
  }

  Future<void> updateCategory(Category category) async {
    await StorageService.updateCategory(category);
    
    int index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String id) async {
    await StorageService.deleteCategory(id);
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  Category? getCategoryById(String id) {
    return _categories.firstWhere((c) => c.id == id);
  }

  // Date selection
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    _currentBudget = StorageService.getBudgetByMonth(date.year, date.month);
    notifyListeners();
  }

  // Analytics methods
  Map<String, double> getCategorySpending(int year, int month) {
    return StorageService.getCategorySpending(year, month);
  }

  Map<String, double> getMonthlySpending(int year) {
    return StorageService.getMonthlySpending(year);
  }

  double getTotalIncome(int year, int month) {
    return StorageService.getTotalIncome(year, month);
  }

  double getTotalExpenses(int year, int month) {
    return StorageService.getTotalExpenses(year, month);
  }

  double getCurrentBalance() {
    return StorageService.getCurrentBalance();
  }

  // Search methods
  List<Transaction> searchTransactions(String query) {
    return StorageService.searchTransactions(query);
  }

  // Utility methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  void clearAllData() async {
    await StorageService.clearAllData();
    _transactions.clear();
    _budgets.clear();
    _categories.clear();
    _currentBudget = null;
    notifyListeners();
  }

  // Cleanup
  @override
  void dispose() {
    _smsSubscription?.cancel();
    _notificationSubscription?.cancel();
    SmsService.dispose();
    NotificationService.dispose();
    StorageService.close();
    super.dispose();
  }
}
