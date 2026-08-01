import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../providers/categories_provider.dart';
import '../../data/models/category_model.dart';

class EditCategoryScreen extends ConsumerStatefulWidget {
  final CategoryModel? category;

  const EditCategoryScreen({super.key, this.category});

  @override
  ConsumerState<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends ConsumerState<EditCategoryScreen> {
  late TextEditingController _nameController;
  late TextEditingController _iconController;
  late String _selectedColor;

  final List<String> _colors = [
    '0xFFFF9800', // Orange
    '0xFF2196F3', // Blue
    '0xFF009688', // Teal
    '0xFF9C27B0', // Purple
    '0xFF4CAF50', // Green
    '0xFFF44336', // Red
    '0xFFE91E63', // Pink
    '0xFF795548', // Brown
    '0xFF607D8B', // Blue Grey
    '0xFF9E9E9E', // Grey
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _iconController = TextEditingController(text: widget.category?.icon ?? '⭐');
    _selectedColor = widget.category?.color ?? _colors[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  void _saveCategory() {
    final name = _nameController.text.trim();
    final icon = _iconController.text.trim();

    if (name.isEmpty || icon.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name and an emoji icon.')),
      );
      return;
    }

    final newCategory = CategoryModel(
      id: widget.category?.id,
      name: name,
      icon: icon,
      color: _selectedColor,
      isDefault: widget.category?.isDefault ?? false,
      isFavorite: widget.category?.isFavorite ?? false,
      createdAt: widget.category?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (widget.category == null) {
      ref.read(categoriesProvider.notifier).addCategory(newCategory);
    } else {
      ref.read(categoriesProvider.notifier).updateCategory(newCategory);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.category == null ? 'Add Category' : 'Edit Category',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.primary),
            onPressed: _saveCategory,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Category Name', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: 'e.g., Medical',
              ),
            ),
            const SizedBox(height: 24),
            const Text('Category Icon (Emoji)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _iconController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: 'e.g., 💊',
              ),
              maxLength: 2,
            ),
            const SizedBox(height: 24),
            const Text('Category Color', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colors.map((colorHex) {
                final isSelected = _selectedColor == colorHex;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = colorHex;
                    });
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(int.parse(colorHex.replaceAll('0x', ''), radix: 16)),
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
