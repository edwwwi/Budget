import '../database/database_helper.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<int> addTransaction(TransactionModel transaction) async {
    // Check for duplicates via has if derived from SMS
    if (transaction.source == 'SMS' && transaction.smsHash != null) {
      final existing =
          await _databaseHelper.getInstanceBySmsHash(transaction.smsHash!);
      if (existing != null) {
        return existing.id!; // Return existing ID if duplicate
      }
    }
    return await _databaseHelper.insertTransaction(transaction);
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    return await _databaseHelper.getTransactions();
  }

  Future<List<TransactionModel>> getUncategorized() async {
    return await _databaseHelper.getUncategorizedTransactions();
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _databaseHelper.updateTransaction(transaction);
  }

  Future<void> deleteTransaction(int id) async {
    await _databaseHelper.deleteTransaction(id);
  }
}
