import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';

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
    String path = join(await getDatabasesPath(), 'budgify.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color TEXT NOT NULL,
        is_default INTEGER DEFAULT 0,
        is_favorite INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await _insertDefaultCategories(db);

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        merchant TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        type TEXT NOT NULL,
        category_id INTEGER NOT NULL DEFAULT 6,
        is_categorized INTEGER DEFAULT 0,
        sms_body TEXT,
        account_number TEXT,
        balance REAL,
        reference_id TEXT,
        source TEXT,
        sms_hash TEXT,
        note TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_timestamp ON transactions (timestamp)');
    await db.execute('CREATE INDEX idx_category_id ON transactions (category_id)');
    await db.execute('CREATE INDEX idx_type ON transactions (type)');
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final now = DateTime.now().toIso8601String();
    final categories = [
      {'name': 'Food', 'icon': '🍔', 'color': '0xFFFF9800', 'is_default': 1, 'is_favorite': 1},
      {'name': 'Petrol', 'icon': '⛽', 'color': '0xFF2196F3', 'is_default': 1, 'is_favorite': 1},
      {'name': 'Travel', 'icon': '✈️', 'color': '0xFF009688', 'is_default': 1, 'is_favorite': 1},
      {'name': 'Entertainment', 'icon': '🎬', 'color': '0xFF9C27B0', 'is_default': 1, 'is_favorite': 0},
      {'name': 'Maintenance', 'icon': '🏠', 'color': '0xFF4CAF50', 'is_default': 1, 'is_favorite': 0},
      {'name': 'Other', 'icon': '📦', 'color': '0xFF9E9E9E', 'is_default': 1, 'is_favorite': 0},
    ];

    for (var cat in categories) {
      await db.insert('categories', {
        'name': cat['name'],
        'icon': cat['icon'],
        'color': cat['color'],
        'is_default': cat['is_default'],
        'is_favorite': cat['is_favorite'],
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE transactions ADD COLUMN note TEXT');
    }
    if (oldVersion < 3) {
      // 1. Create categories table
      await db.execute('''
        CREATE TABLE categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          icon TEXT NOT NULL,
          color TEXT NOT NULL,
          is_default INTEGER DEFAULT 0,
          is_favorite INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      await _insertDefaultCategories(db);

      // 2. Rename old transactions to transactions_old
      await db.execute('ALTER TABLE transactions RENAME TO transactions_old');

      // 3. Create new transactions table with category_id
      await db.execute('''
        CREATE TABLE transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          amount REAL NOT NULL,
          merchant TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          type TEXT NOT NULL,
          category_id INTEGER NOT NULL DEFAULT 6,
          is_categorized INTEGER DEFAULT 0,
          sms_body TEXT,
          account_number TEXT,
          balance REAL,
          reference_id TEXT,
          source TEXT,
          sms_hash TEXT,
          note TEXT,
          created_at TEXT,
          updated_at TEXT,
          FOREIGN KEY (category_id) REFERENCES categories (id)
        )
      ''');

      // 4. Copy data over, mapping old string category to category_id
      // We will do a generic map for default categories. Any custom category text will default to 6 ('Other').
      // Alternatively, we could dynamically insert them but keeping it simple as per prompt constraints.
      final List<Map<String, dynamic>> oldTx = await db.query('transactions_old');
      for (var tx in oldTx) {
        String catName = tx['category']?.toString() ?? 'Other';
        int catId = 6; // Default to Other
        
        switch (catName.toLowerCase()) {
          case 'food': catId = 1; break;
          case 'petrol': catId = 2; break;
          case 'travel': catId = 3; break;
          case 'entertainment': catId = 4; break;
          case 'maintenance': catId = 5; break;
          default: catId = 6; break;
        }

        await db.insert('transactions', {
          'id': tx['id'],
          'amount': tx['amount'],
          'merchant': tx['merchant'],
          'timestamp': tx['timestamp'],
          'type': tx['type'],
          'category_id': catId,
          'is_categorized': tx['is_categorized'],
          'sms_body': tx['sms_body'],
          'account_number': tx['account_number'],
          'balance': tx['balance'],
          'reference_id': tx['reference_id'],
          'source': tx['source'],
          'sms_hash': tx['sms_hash'],
          'note': tx['note'],
          'created_at': tx['created_at'] ?? DateTime.now().toIso8601String(),
          'updated_at': tx['updated_at'] ?? DateTime.now().toIso8601String(),
        });
      }

      // 5. Drop old table
      await db.execute('DROP TABLE transactions_old');
      
      // Re-create indexes
      await db.execute('CREATE INDEX idx_timestamp ON transactions (timestamp)');
      await db.execute('CREATE INDEX idx_category_id ON transactions (category_id)');
      await db.execute('CREATE INDEX idx_type ON transactions (type)');
    }
  }

  // --- Category Methods ---
  
  Future<int> insertCategory(CategoryModel category) async {
    Database db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<CategoryModel>> getCategories() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) => CategoryModel.fromMap(maps[i]));
  }

  Future<int> updateCategory(CategoryModel category) async {
    Database db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    Database db = await database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Transaction Methods ---

  Future<int> insertTransaction(TransactionModel transaction) async {
    Database db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<TransactionModel>> getTransactions({DateTime? startDate, DateTime? endDate}) async {
    Database db = await database;
    
    String? whereStr;
    List<dynamic>? whereArgs;

    if (startDate != null && endDate != null) {
      whereStr = 'timestamp >= ? AND timestamp <= ?';
      whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: whereStr,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC'
    );
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  Future<List<TransactionModel>> getUncategorizedTransactions() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'is_categorized = ?',
      whereArgs: [0],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    Database db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    Database db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<TransactionModel?> getInstanceBySmsHash(String smsHash) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'sms_hash = ?',
      whereArgs: [smsHash],
    );
    if (maps.isNotEmpty) {
      return TransactionModel.fromMap(maps.first);
    }
    return null;
  }
}
