import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';

class DashboardProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Map<String, double> _expensesByCategory = {};
  Map<String, Map<String, double>> _expensesVsBudget = {};
  bool _isLoading = false;
  String _error = '';
  String _currentPeriodicity = 'monthly'; // Default periodicity

  Map<String, double> get expensesByCategory => _expensesByCategory;
  Map<String, Map<String, double>> get expensesVsBudget => _expensesVsBudget;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get currentPeriodicity => _currentPeriodicity;

  void setPeriodicity(String periodicity) {
    _currentPeriodicity = periodicity;
    fetchExpensesByCategory();
    notifyListeners();
  }

  Future<void> fetchExpensesByCategory() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      DateTime start;
      DateTime end = DateTime.now();
      
      switch (_currentPeriodicity) {
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
      
      _expensesByCategory = {};
      for (var item in expenseData) {
        _expensesByCategory[item['name']] = item['total'];
      }
    } catch (e) {
      _error = 'Failed to load expense data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchExpensesVsBudget() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final data = await _dbHelper.getExpensesVsBudget();
      
      _expensesVsBudget = {};
      for (var item in data) {
        _expensesVsBudget[item['name']] = {
          'expense': item['expense_total'] ?? 0.0,
          'budget': item['budget_amount'] ?? 0.0,
        };
      }
    } catch (e) {
      _error = 'Failed to load budget comparison data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDashboard() async {
    await fetchExpensesByCategory();
    await fetchExpensesVsBudget();
  }
}
