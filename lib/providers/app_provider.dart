import 'package:flutter/material.dart';
import '../core/database/database_helper.dart';
import '../models/transaction_model.dart';
import '../models/transaction_category.dart';
import '../models/transaction_type.dart';
import '../services/notification_service.dart';
import '../services/sms_background_service.dart';

class AppProvider with ChangeNotifier {
  final List<TransactionModel> _transactions = [];
  bool _isLoading = false;

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;

  double get totalIncome => _transactions
      .where((t) => t.type == TransactionType.credit)
      .fold(0, (sum, t) => sum + t.amount);

  double get totalOutcome => _transactions
      .where((t) => t.type == TransactionType.debit)
      .fold(0, (sum, t) => sum + t.amount);

  Map<TransactionCategory, double> get categorySpending {
    final Map<TransactionCategory, double> spending = {};
    for (var t in _transactions.where((t) => t.type == TransactionType.debit)) {
      spending[t.category] = (spending[t.category] ?? 0) + t.amount;
    }
    return spending;
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    // Initialize services
    await NotificationService.initialize();
    await SmsBackgroundService.initialize();

    // Load initial data
    await loadTransactions();

    // Listen for notification actions (categorization)
    NotificationService.notificationActionStream.listen((data) {
      if (data['action'] == 'transaction_added') {
        _transactions.insert(0, data['transaction']);
        notifyListeners();
      }
    });

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadTransactions() async {
    final dbTransactions = await DatabaseHelper().getTransactions();
    _transactions.clear();
    _transactions.addAll(dbTransactions);
    notifyListeners();
  }

  Future<void> addManualTransaction(TransactionModel transaction) async {
    await DatabaseHelper().insertTransaction(transaction);
    _transactions.insert(0, transaction);
    notifyListeners();
  }

  Future<void> deleteTransaction(int id) async {
    await DatabaseHelper().deleteTransaction(id);
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }
}
