import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6C63FF); // Soft Purple
  static const Color secondary = Color(0xFF2ecc71); // Soft Green
  static const Color background = Color(0xFFF5F7FA); // Soft White/Grey
  static const Color cardBackground = Colors.white;
  static const Color textDark = Color(0xFF2D3436);
  static const Color textLight = Color(0xFF636E72);
  static const Color error = Color(0xFFe74c3c);

  // Categories
  static const Color food = Color(0xFFFF7675);
  static const Color petrol = Color(0xFF74B9FF);
  static const Color entertainment = Color(0xFFA29BFE);
  static const Color other = Color(0xFFDFE6E9);
  static const Color income = Color(0xFF00b894);
  static const Color expense = Color(0xFFd63031);
}

class AppStrings {
  static const String appName = 'Budify';
  static const String currency =
      '₹'; // Assuming INR based on Federal Bank context
  static const String expenseDetected = 'Expense Detected';
  static const String uncategorized = 'Uncategorized';
}
