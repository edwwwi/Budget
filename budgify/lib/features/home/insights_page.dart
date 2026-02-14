import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/transaction_provider.dart';
import '../../core/constants.dart';

class InsightsPage extends ConsumerWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdownAsync = ref.watch(categoryBreakdownProvider);
    final incomeExpenseAsync = ref.watch(incomeExpenseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Budify Insights')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Summary Cards
              incomeExpenseAsync.when(
                data: (data) => Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Income',
                        amount: data['income'] ?? 0,
                        color: AppColors.income,
                        icon: Icons.arrow_downward,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Expense',
                        amount: data['expense'] ?? 0,
                        color: AppColors.expense,
                        icon: Icons.arrow_upward,
                      ),
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error: $err'),
              ),
              const SizedBox(height: 24),

              const Text('Expense Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Donut Chart
              breakdownAsync.when(
                data: (data) {
                  if (data.isEmpty) {
                    return const SizedBox(
                      height: 200,
                      child: Center(child: Text('No expense data yet')),
                    );
                  }
                  return SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: _generateSections(data),
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error: $err'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _generateSections(Map<String, double> data) {
    return data.entries.map((entry) {
      final color = _getColorForCategory(entry.key);
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '', // Hide title on chart to keep it clean, or show percentage
        radius: 50,
        badgeWidget: _Badge(
          entry.key,
          size: 40,
          borderColor: color,
        ),
        badgePositionPercentageOffset: .98,
      );
    }).toList();
  }

  Color _getColorForCategory(String category) {
    switch (category) {
      case 'Food':
        return AppColors.food;
      case 'Petrol':
        return AppColors.petrol;
      case 'Entertainment':
        return AppColors.entertainment;
      case 'Other':
        return AppColors.other;
      default:
        return Colors.grey;
    }
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final double size;
  final Color borderColor;

  const _Badge(this.text, {required this.size, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 3),
        ],
      ),
      child: Center(
        child: Text(
          text.substring(0, 1),
          style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
              color: Colors.black),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textLight)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${AppStrings.currency} ${amount.toStringAsFixed(2)}',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
