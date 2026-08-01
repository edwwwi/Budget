import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/category_model.dart';
import '../data/database/database_helper.dart';

final categoriesProvider = StateNotifierProvider<CategoriesNotifier, List<CategoryModel>>((ref) {
  return CategoriesNotifier();
});

class CategoriesNotifier extends StateNotifier<List<CategoryModel>> {
  CategoriesNotifier() : super([]) {
    _loadCategories();
  }

  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> _loadCategories() async {
    final categories = await _dbHelper.getCategories();
    state = categories;
  }

  Future<void> addCategory(CategoryModel category) async {
    final id = await _dbHelper.insertCategory(category);
    final newCategory = category.copyWith(id: id);
    state = [...state, newCategory];
  }

  Future<void> updateCategory(CategoryModel category) async {
    await _dbHelper.updateCategory(category);
    state = [
      for (final cat in state)
        if (cat.id == category.id) category else cat,
    ];
  }

  Future<void> deleteCategory(int id) async {
    await _dbHelper.deleteCategory(id);
    state = state.where((cat) => cat.id != id).toList();
  }

  Future<void> toggleFavorite(CategoryModel category) async {
    final updatedCategory = category.copyWith(isFavorite: !category.isFavorite);
    await updateCategory(updatedCategory);
  }

  CategoryModel getCategoryById(int id) {
    return state.firstWhere((cat) => cat.id == id,
        orElse: () => CategoryModel(
            id: 6,
            name: 'Other',
            icon: '📦',
            color: '0xFF9E9E9E',
            isDefault: true));
  }
}
