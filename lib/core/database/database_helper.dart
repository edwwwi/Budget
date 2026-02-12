import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/transaction_model.dart';
import '../../models/sms_log_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'budify.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sms_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sender TEXT,
        body TEXT,
        timestamp TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL,
        category INTEGER,
        merchant TEXT,
        type INTEGER,
        timestamp TEXT
      )
    ''');
  }

  // SMS Logs Operations
  Future<int> insertSmsLog(SmsLogModel log) async {
    Database db = await database;
    return await db.insert('sms_logs', log.toMap());
  }

  Future<List<SmsLogModel>> getSmsLogs() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sms_logs',
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => SmsLogModel.fromMap(maps[i]));
  }

  // Transactions Operations
  Future<int> insertTransaction(TransactionModel transaction) async {
    Database db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<TransactionModel>> getTransactions() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  Future<int> deleteTransaction(int id) async {
    Database db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    Database db = await database;
    await db.delete('sms_logs');
    await db.delete('transactions');
  }
}
