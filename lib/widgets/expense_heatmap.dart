import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import 'day_detail_modal.dart';

class ExpenseHeatmap extends ConsumerWidget {
  const ExpenseHeatmap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aggregatesAsync = ref.watch(monthlyDailyAggregatesProvider);

    return aggregatesAsync.when(
      data: (aggregates) {
        return _buildHeatmap(context, ref, aggregates);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading heatmap: $err')),
    );
  }

  Widget _buildHeatmap(BuildContext context, WidgetRef ref, Map<int, double> aggregates) {
    final dateRange = ref.watch(dateRangeProvider);
    final targetDate = dateRange.start; // using the start of range as reference for month display
    
    // Total spent in this month (or selected range)
    final double totalSpent = aggregates.values.fold(0.0, (a, b) => a + b);
        
    final firstDayOfMonth = DateTime(targetDate.year, targetDate.month, 1);
    final daysInMonth = DateTime(targetDate.year, targetDate.month + 1, 0).day;
    
    // weekday is 1-7 (Mon-Sun). We want 0-6 padding for our grid starting with Sunday (0)
    final paddingDays = firstDayOfMonth.weekday % 7; 

    final totalCells = paddingDays + daysInMonth;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Total Spent (Top Left) | Month Year (Top Right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Spent',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${AppStrings.currency}${totalSpent.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textDark,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () async {
                  final List<DateTime> months = [];
                  final now = DateTime.now();
                  for (int i = 0; i < 12; i++) {
                    months.add(DateTime(now.year, now.month - i, 1));
                  }
                  
                  final selected = await showDialog<DateTime>(
                    context: context,
                    builder: (context) {
                      return SimpleDialog(
                        title: const Text('Select Month'),
                        children: months.map((m) {
                          return SimpleDialogOption(
                            onPressed: () => Navigator.pop(context, m),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(DateFormat('MMMM yyyy').format(m), style: const TextStyle(fontSize: 16)),
                            ),
                          );
                        }).toList(),
                      );
                    }
                  );

                  if (selected != null) {
                    final range = DateTimeRange(
                      start: DateTime(selected.year, selected.month, 1),
                      end: DateTime(selected.year, selected.month + 1, 0, 23, 59, 59),
                    );
                    ref.read(customDateRangeProvider.notifier).state = range;
                    ref.read(timeFilterProvider.notifier).state = TimeFilter.custom;
                  }
                },
                child: Row(
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(targetDate),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textDark,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Day Headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _DayHeader('S'), _DayHeader('M'), _DayHeader('T'), _DayHeader('W'),
              _DayHeader('T'), _DayHeader('F'), _DayHeader('S'),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: totalCells,
            itemBuilder: (context, index) {
              if (index < paddingDays) {
                return const SizedBox.shrink(); // Empty space for days before the 1st
              }

              final day = index - paddingDays + 1;
              final amount = aggregates[day] ?? 0.0;
              final color = _getColorForAmount(context, amount, aggregates);

              return GestureDetector(
                onTap: () {
                  final date = DateTime(targetDate.year, targetDate.month, day);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => DayDetailModal(date: date, totalSpent: amount),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: amount == 0 ? Colors.grey.shade300 : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: amount == 0 
                                ? Colors.grey.shade600 
                                : (amount < 200 ? Colors.black87 : Colors.white),
                          ),
                        ),
                        if (amount > 0)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2.0),
                              child: Text(
                                '₹${amount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: amount < 200 ? Colors.black87 : Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getColorForAmount(BuildContext context, double amount, Map<int, double> aggregates) {
    if (amount == 0) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return isDark ? Colors.grey.shade800 : Colors.grey.shade200; // Grey
    }
    
    // Dynamic intensity based on highest expense
    double maxAmount = 1000.0; // fallback
    if (aggregates.isNotEmpty) {
      maxAmount = aggregates.values.reduce((a, b) => a > b ? a : b);
      if (maxAmount == 0) maxAmount = 1000.0;
    }

    final ratio = amount / maxAmount;

    if (ratio <= 0.25) return Colors.red.shade200; // Low Expense (Light Red)
    if (ratio <= 0.50) return Colors.red.shade400; // Medium Expense (Medium Red)
    if (ratio <= 0.75) return Colors.red.shade700; // High Expense (Dark Red)
    return Colors.red.shade900; // Highest Expense (Very Dark Red)
  }
}

class _DayHeader extends StatelessWidget {
  final String text;
  const _DayHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
