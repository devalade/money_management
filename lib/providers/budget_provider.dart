import 'package:flutter/foundation.dart';
import '../models/budget.dart';
import '../database/database_helper.dart';

class BudgetProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Budget> _budgets = [];
  bool _isLoading = false;
  String _error = '';

  List<Budget> get budgets => _budgets;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> fetchBudgets() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final budgetMaps = await _dbHelper.getBudgets();
      _budgets = budgetMaps.map((map) => Budget.fromMap(map)).toList();
    } catch (e) {
      _error = 'Failed to load budgets: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addBudget(Budget budget) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final id = await _dbHelper.insertBudget(budget.toMap());
      if (id > 0) {
        await fetchBudgets();
        return true;
      } else {
        _error = 'Failed to add budget. A budget with this periodicity already exists.';
        return false;
      }
    } catch (e) {
      _error = 'Error adding budget: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateBudget(Budget budget) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final rowsAffected = await _dbHelper.updateBudget(budget.toMap());
      if (rowsAffected > 0) {
        await fetchBudgets();
        return true;
      } else {
        _error = 'Failed to update budget';
        return false;
      }
    } catch (e) {
      _error = 'Error updating budget: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteBudget(int id) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final rowsAffected = await _dbHelper.deleteBudget(id);
      if (rowsAffected > 0) {
        await fetchBudgets();
        return true;
      } else {
        _error = 'Failed to delete budget';
        return false;
      }
    } catch (e) {
      _error = 'Error deleting budget: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
