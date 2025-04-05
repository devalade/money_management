import 'package:flutter/foundation.dart';
import '../models/category.dart' as app_models;
import '../database/database_helper.dart';

class CategoryProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<app_models.Category> _categories = [];
  bool _isLoading = false;
  String _error = '';

  List<app_models.Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final categoryMaps = await _dbHelper.getCategories();
      _categories = categoryMaps.map((map) => app_models.Category.fromMap(map)).toList();
    } catch (e) {
      _error = 'Failed to load categories: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCategory(app_models.Category category) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final id = await _dbHelper.insertCategory(category.toMap());
      if (id > 0) {
        await fetchCategories();
        return true;
      } else {
        _error = 'Failed to add category';
        return false;
      }
    } catch (e) {
      _error = 'Error adding category: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateCategory(app_models.Category category) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final rowsAffected = await _dbHelper.updateCategory(category.toMap());
      if (rowsAffected > 0) {
        await fetchCategories();
        return true;
      } else {
        _error = 'Failed to update category';
        return false;
      }
    } catch (e) {
      _error = 'Error updating category: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCategory(int id) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final rowsAffected = await _dbHelper.deleteCategory(id);
      if (rowsAffected > 0) {
        await fetchCategories();
        return true;
      } else {
        _error = 'Cannot delete category. It may be used in expenses.';
        return false;
      }
    } catch (e) {
      _error = 'Error deleting category: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
