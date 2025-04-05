import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

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
    String path = join(await getDatabasesPath(), 'mon_budget.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    // Create category table
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    // Create budget table
    await db.execute('''
      CREATE TABLE budgets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        periodicity TEXT NOT NULL,
        amount REAL NOT NULL
      )
    ''');

    // Create expense table
    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        title TEXT NOT NULL,
        observation TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // Create income table
    await db.execute('''
      CREATE TABLE incomes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        amount REAL NOT NULL,
        title TEXT NOT NULL,
        observation TEXT
      )
    ''');
  }

  // Category CRUD operations
  Future<int> insertCategory(Map<String, dynamic> category) async {
    Database db = await database;
    return await db.insert('categories', category);
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    Database db = await database;
    return await db.query('categories');
  }

  Future<int> updateCategory(Map<String, dynamic> category) async {
    Database db = await database;
    return await db.update(
      'categories',
      category,
      where: 'id = ?',
      whereArgs: [category['id']],
    );
  }

  Future<int> deleteCategory(int id) async {
    Database db = await database;
    
    // Check if category is used in any expense
    List<Map<String, dynamic>> expenses = await db.query(
      'expenses',
      where: 'category_id = ?',
      whereArgs: [id],
    );
    
    if (expenses.isNotEmpty) {
      // Category is in use, cannot delete
      return 0;
    }
    
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Budget CRUD operations
  Future<int> insertBudget(Map<String, dynamic> budget) async {
    Database db = await database;
    
    // Check if budget with same periodicity already exists
    List<Map<String, dynamic>> existingBudgets = await db.query(
      'budgets',
      where: 'periodicity = ?',
      whereArgs: [budget['periodicity']],
    );
    
    if (existingBudgets.isNotEmpty) {
      // Budget with same periodicity exists, cannot insert
      return 0;
    }
    
    return await db.insert('budgets', budget);
  }

  Future<List<Map<String, dynamic>>> getBudgets() async {
    Database db = await database;
    return await db.query('budgets');
  }

  Future<int> updateBudget(Map<String, dynamic> budget) async {
    Database db = await database;
    return await db.update(
      'budgets',
      budget,
      where: 'id = ?',
      whereArgs: [budget['id']],
    );
  }

  Future<int> deleteBudget(int id) async {
    Database db = await database;
    return await db.delete(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Expense CRUD operations
  Future<int> insertExpense(Map<String, dynamic> expense) async {
    Database db = await database;
    return await db.insert('expenses', expense);
  }

  Future<List<Map<String, dynamic>>> getExpenses() async {
    Database db = await database;
    return await db.query('expenses');
  }

  Future<List<Map<String, dynamic>>> getExpensesByDateRange(String startDate, String endDate) async {
    Database db = await database;
    return await db.query(
      'expenses',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
    );
  }

  Future<List<Map<String, dynamic>>> getExpensesWithCategory() async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT e.*, c.name as category_name
      FROM expenses e
      JOIN categories c ON e.category_id = c.id
    ''');
  }

  Future<List<Map<String, dynamic>>> getExpensesWithCategoryByDateRange(String startDate, String endDate) async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT e.*, c.name as category_name
      FROM expenses e
      JOIN categories c ON e.category_id = c.id
      WHERE e.date BETWEEN ? AND ?
    ''', [startDate, endDate]);
  }

  Future<int> updateExpense(Map<String, dynamic> expense) async {
    Database db = await database;
    return await db.update(
      'expenses',
      expense,
      where: 'id = ?',
      whereArgs: [expense['id']],
    );
  }

  Future<int> deleteExpense(int id) async {
    Database db = await database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Income CRUD operations
  Future<int> insertIncome(Map<String, dynamic> income) async {
    Database db = await database;
    return await db.insert('incomes', income);
  }

  Future<List<Map<String, dynamic>>> getIncomes() async {
    Database db = await database;
    return await db.query('incomes');
  }

  Future<List<Map<String, dynamic>>> getIncomesByDateRange(String startDate, String endDate) async {
    Database db = await database;
    return await db.query(
      'incomes',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
    );
  }

  Future<int> updateIncome(Map<String, dynamic> income) async {
    Database db = await database;
    return await db.update(
      'incomes',
      income,
      where: 'id = ?',
      whereArgs: [income['id']],
    );
  }

  Future<int> deleteIncome(int id) async {
    Database db = await database;
    return await db.delete(
      'incomes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Dashboard queries
  Future<List<Map<String, dynamic>>> getExpensesByCategory(String startDate, String endDate) async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT c.name, SUM(e.amount) as total
      FROM expenses e
      JOIN categories c ON e.category_id = c.id
      WHERE e.date BETWEEN ? AND ?
      GROUP BY c.id
    ''', [startDate, endDate]);
  }

  Future<List<Map<String, dynamic>>> getExpensesVsBudget() async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT c.name, SUM(e.amount) as expense_total, b.amount as budget_amount
      FROM expenses e
      JOIN categories c ON e.category_id = c.id
      LEFT JOIN budgets b ON 1=1
      GROUP BY c.id
    ''');
  }
}
