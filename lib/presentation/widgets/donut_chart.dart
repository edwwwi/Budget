import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/transaction_category.dart';

class BudifyDonutChart extends StatelessWidget {
  final Map<TransactionCategory, double> data;

  const BudifyDonutChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 0,
          centerSpaceRadius: 60,
          sections: _getSections(),
        ),
      ),
    );
  }

  List<PieChartSectionData> _getSections() {
    if (data.isEmpty) {
      return [
        PieChartSectionData(
          color: Colors.grey.withOpacity(0.2),
          value: 100,
          title: '',
          radius: 30,
        ),
      ];
    }

    return data.entries.map((entry) {
      final color = _getCategoryColor(entry.key);
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '',
        radius: 30,
        badgeWidget: _getIcon(entry.key),
        badgePositionPercentageOffset: 0.98,
      );
    }).toList();
  }

  Color _getCategoryColor(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.food:
        return Colors.orange;
      case TransactionCategory.petrol:
        return Colors.blue;
      case TransactionCategory.entertainment:
        return Colors.purple;
      case TransactionCategory.other:
        return Colors.grey;
      case TransactionCategory.income:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _getIcon(TransactionCategory category) {
    IconData icon;
    switch (category) {
      case TransactionCategory.food:
        icon = Icons.restaurant;
        break;
      case TransactionCategory.petrol:
        icon = Icons.local_gas_station;
        break;
      case TransactionCategory.entertainment:
        icon = Icons.movie;
        break;
      case TransactionCategory.other:
        icon = Icons.more_horiz;
        break;
      case TransactionCategory.income:
        icon = Icons.attach_money;
        break;
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      padding: EdgeInsets(2),
      child: Icon(icon, size: 16, color: _getCategoryColor(category)),
    );
  }
}
