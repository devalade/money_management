import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../database/database_helper.dart';

class ExpenseProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String _error = '';

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> fetchExpenses() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final expenseMaps = await _dbHelper.getExpensesWithCategory();
      _expenses = expenseMaps.map((map) => Expense.fromMap(map)).toList();
    } catch (e) {
      _error = 'Failed to load expenses: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchExpensesByWeek() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Get current week's start and end date
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      
      final startDate = DateFormat('yyyy-MM-dd').format(startOfWeek);
      final endDate = DateFormat('yyyy-MM-dd').format(endOfWeek);
      
      final expenseMaps = await _dbHelper.getExpensesWithCategoryByDateRange(startDate, endDate);
      _expenses = expenseMaps.map((map) => Expense.fromMap(map)).toList();
    } catch (e) {
      _error = 'Failed to load expenses: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchExpensesByDateRange(DateTime start, DateTime end) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final startDate = DateFormat('yyyy-MM-dd').format(start);
      final endDate = DateFormat('yyyy-MM-dd').format(end);
      
      final expenseMaps = await _dbHelper.getExpensesWithCategoryByDateRange(startDate, endDate);
      _expenses = expenseMaps.map((map) => Expense.fromMap(map)).toList();
    } catch (e) {
      _error = 'Failed to load expenses: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addExpense(Expense expense) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final id = await _dbHelper.insertExpense(expense.toMap());
      if (id > 0) {
        await fetchExpensesByWeek(); // Refresh with default view
        return true;
      } else {
        _error = 'Failed to add expense';
        return false;
      }
    } catch (e) {
      _error = 'Error adding expense: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateExpense(Expense expense) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final rowsAffected = await _dbHelper.updateExpense(expense.toMap());
      if (rowsAffected > 0) {
        await fetchExpensesByWeek(); // Refresh with default view
        return true;
      } else {
        _error = 'Failed to update expense';
        return false;
      }
    } catch (e) {
      _error = 'Error updating expense: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteExpense(int id) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final rowsAffected = await _dbHelper.deleteExpense(id);
      if (rowsAffected > 0) {
        await fetchExpensesByWeek(); // Refresh with default view
        return true;
      } else {
        _error = 'Failed to delete expense';
        return false;
      }
    } catch (e) {
      _error = 'Error deleting expense: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, double>> getExpensesByCategory(String periodicity) async {
    try {
      DateTime start;
      DateTime end = DateTime.now();
      
      switch (periodicity) {
        case 'weekly':
          final now = DateTime.now();
          start = now.subtract(Duration(days: now.weekday - 1));
          end = start.add(const Duration(days: 6));
          break;
        case 'monthly':
          final now = DateTime.now();
          start = DateTime(now.year, now.month, 1);
          end = DateTime(now.year, now.month + 1, 0);
          break;
        case 'quarterly':
          final now = DateTime.now();
          final quarter = (now.month - 1) ~/ 3;
          start = DateTime(now.year, quarter * 3 + 1, 1);
          end = DateTime(now.year, (quarter + 1) * 3 + 1, 0);
          break;
        case 'yearly':
          final now = DateTime.now();
          start = DateTime(now.year, 1, 1);
          end = DateTime(now.year, 12, 31);
          break;
        default:
          final now = DateTime.now();
          start = DateTime(now.year, now.month, 1);
          end = DateTime(now.year, now.month + 1, 0);
      }
      
      final startDate = DateFormat('yyyy-MM-dd').format(start);
      final endDate = DateFormat('yyyy-MM-dd').format(end);
      
      final expenseData = await _dbHelper.getExpensesByCategory(startDate, endDate);
      
      Map<String, double> result = {};
      for (var item in expenseData) {
        result[item['name']] = item['total'];
      }
      
      return result;
    } catch (e) {
      _error = 'Error getting expense data: $e';
      return {};
    }
  }
}
