import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'budgify.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sms_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sender TEXT,
        timestamp TEXT,
        body TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL,
        category TEXT,
        merchant TEXT,
        type TEXT,
        sms_id INTEGER,
        timestamp TEXT,
        FOREIGN KEY (sms_id) REFERENCES sms_logs (id)
      )
    ''');
  }

  // Transaction CRUD operations
  Future<int> insertTransaction(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('transactions', row);
  }

  Future<List<Map<String, dynamic>>> queryAllTransactions() async {
    final db = await database;
    return await db.query('transactions', orderBy: 'timestamp DESC');
  }

  // SMS log CRUD operations
  Future<int> insertSmsLog(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('sms_logs', row);
  }
}
