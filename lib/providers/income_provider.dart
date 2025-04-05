import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/income.dart';
import '../database/database_helper.dart';

class IncomeProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Income> _incomes = [];
  bool _isLoading = false;
  String _error = '';

  List<Income> get incomes => _incomes;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> fetchIncomes() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final incomeMaps = await _dbHelper.getIncomes();
      _incomes = incomeMaps.map((map) => Income.fromMap(map)).toList();
    } catch (e) {
      _error = 'Failed to load incomes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchIncomesByMonth() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Get current month's start and end date
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);
      
      final startDate = DateFormat('yyyy-MM-dd').format(startOfMonth);
      final endDate = DateFormat('yyyy-MM-dd').format(endOfMonth);
      
      final incomeMaps = await _dbHelper.getIncomesByDateRange(startDate, endDate);
      _incomes = incomeMaps.map((map) => Income.fromMap(map)).toList();
    } catch (e) {
      _error = 'Failed to load incomes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchIncomesByDateRange(DateTime start, DateTime end) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final startDate = DateFormat('yyyy-MM-dd').format(start);
      final endDate = DateFormat('yyyy-MM-dd').format(end);
      
      final incomeMaps = await _dbHelper.getIncomesByDateRange(startDate, endDate);
      _incomes = incomeMaps.map((map) => Income.fromMap(map)).toList();
    } catch (e) {
      _error = 'Failed to load incomes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addIncome(Income income) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final id = await _dbHelper.insertIncome(income.toMap());
      if (id > 0) {
        await fetchIncomesByMonth(); // Refresh with default view
        return true;
      } else {
        _error = 'Failed to add income';
        return false;
      }
    } catch (e) {
      _error = 'Error adding income: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateIncome(Income income) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final rowsAffected = await _dbHelper.updateIncome(income.toMap());
      if (rowsAffected > 0) {
        await fetchIncomesByMonth(); // Refresh with default view
        return true;
      } else {
        _error = 'Failed to update income';
        return false;
      }
    } catch (e) {
      _error = 'Error updating income: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteIncome(int id) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final rowsAffected = await _dbHelper.deleteIncome(id);
      if (rowsAffected > 0) {
        await fetchIncomesByMonth(); // Refresh with default view
        return true;
      } else {
        _error = 'Failed to delete income';
        return false;
      }
    } catch (e) {
      _error = 'Error deleting income: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double getTotalIncome() {
    return _incomes.fold(0, (sum, income) => sum + income.amount);
  }
}
