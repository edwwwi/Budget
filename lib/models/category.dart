import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 3)
class Category extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String icon;

  @HiveField(3)
  int color;

  @HiveField(4)
  bool isDefault;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isDefault = false,
  });

  Color get colorValue => Color(color);

  IconData get iconData {
    switch (icon) {
      case 'food':
        return Icons.restaurant;
      case 'travel':
        return Icons.flight;
      case 'shopping':
        return Icons.shopping_cart;
      case 'bills':
        return Icons.receipt;
      case 'entertainment':
        return Icons.movie;
      case 'transport':
        return Icons.directions_car;
      case 'health':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      case 'salary':
        return Icons.work;
      case 'investment':
        return Icons.trending_up;
      case 'gift':
        return Icons.card_giftcard;
      case 'other':
        return Icons.more_horiz;
      default:
        return Icons.category;
    }
  }

  static List<Category> get defaultCategories => [
    Category(
      id: 'food',
      name: 'Food & Dining',
      icon: 'food',
      color: Colors.orange.value,
      isDefault: true,
    ),
    Category(
      id: 'travel',
      name: 'Travel',
      icon: 'travel',
      color: Colors.blue.value,
      isDefault: true,
    ),
    Category(
      id: 'shopping',
      name: 'Shopping',
      icon: 'shopping',
      color: Colors.pink.value,
      isDefault: true,
    ),
    Category(
      id: 'bills',
      name: 'Bills & Utilities',
      icon: 'bills',
      color: Colors.red.value,
      isDefault: true,
    ),
    Category(
      id: 'entertainment',
      name: 'Entertainment',
      icon: 'entertainment',
      color: Colors.purple.value,
      isDefault: true,
    ),
    Category(
      id: 'transport',
      name: 'Transport',
      icon: 'transport',
      color: Colors.green.value,
      isDefault: true,
    ),
    Category(
      id: 'health',
      name: 'Health',
      icon: 'health',
      color: Colors.teal.value,
      isDefault: true,
    ),
    Category(
      id: 'education',
      name: 'Education',
      icon: 'education',
      color: Colors.indigo.value,
      isDefault: true,
    ),
    Category(
      id: 'salary',
      name: 'Salary',
      icon: 'salary',
      color: Colors.green.value,
      isDefault: true,
    ),
    Category(
      id: 'investment',
      name: 'Investment',
      icon: 'investment',
      color: Colors.amber.value,
      isDefault: true,
    ),
    Category(
      id: 'gift',
      name: 'Gift',
      icon: 'gift',
      color: Colors.deepPurple.value,
      isDefault: true,
    ),
    Category(
      id: 'other',
      name: 'Other',
      icon: 'other',
      color: Colors.grey.value,
      isDefault: true,
    ),
  ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'isDefault': isDefault,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      color: json['color'],
      isDefault: json['isDefault'] ?? false,
    );
  }
}
