import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../providers/categories_provider.dart';
import '../../data/models/category_model.dart';
import 'edit_category_screen.dart';

class ManageCategoriesScreen extends ConsumerWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final favoriteCount = categories.where((c) => c.isFavorite).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Categories',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Select up to 3 categories to appear in your quick access notification.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return _CategoryTile(
                  category: category,
                  favoriteCount: favoriteCount,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const EditCategoryScreen(category: null)),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  final CategoryModel category;
  final int favoriteCount;

  const _CategoryTile({required this.category, required this.favoriteCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color color = Color(int.parse(category.color));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(category.icon, style: const TextStyle(fontSize: 24)),
          ),
        ),
        title: Text(category.name,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.textDark)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                category.isFavorite ? Icons.star : Icons.star_border,
                color: category.isFavorite ? Colors.amber : Colors.grey,
              ),
              onPressed: () {
                if (!category.isFavorite && favoriteCount >= 3) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You can only select up to 3 favorites.')),
                  );
                  return;
                }
                ref.read(categoriesProvider.notifier).toggleFavorite(category);
              },
              tooltip: 'Quick Access',
            ),
            if (!category.isDefault)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            EditCategoryScreen(category: category)),
                  );
                },
              ),
            if (!category.isDefault)
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.error),
                onPressed: () {
                  _confirmDelete(context, ref);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category?'),
        content: const Text(
            'Are you sure you want to delete this category? Transactions using this category will be preserved but might show up as uncategorized if not handled.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              ref.read(categoriesProvider.notifier).deleteCategory(category.id!);
              Navigator.pop(context);
            },
            child: const Text('DELETE', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
