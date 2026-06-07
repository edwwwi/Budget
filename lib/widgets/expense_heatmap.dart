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
    final customDate = ref.watch(customDateProvider);
    final filter = ref.watch(timeFilterProvider);
    final targetDate = (filter == TimeFilter.customDate && customDate != null) 
        ? customDate 
        : DateTime.now();
        
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
          GestureDetector(
            onTap: () async {
              final DateTime? picked = await showModalBottomSheet<DateTime>(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (BuildContext context) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Select Month (${targetDate.year})',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: 12,
                            itemBuilder: (context, index) {
                              final month = index + 1;
                              final date = DateTime(targetDate.year, month, 1);
                              final isSelected = month == targetDate.month;
                              return ListTile(
                                title: Text(
                                  DateFormat('MMMM').format(date),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppColors.primary : null,
                                  ),
                                ),
                                onTap: () => Navigator.pop(context, date),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
              if (picked != null) {
                ref.read(customDateProvider.notifier).state = picked;
                ref.read(timeFilterProvider.notifier).state = TimeFilter.customDate;
              }
            },
            child: Row(
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(targetDate),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textDark),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
              final color = _getColorForAmount(context, amount);

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
                                : (amount < 400 ? Colors.black87 : Colors.white),
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
                                  color: amount < 400 ? Colors.black87 : Colors.white,
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

  Color _getColorForAmount(BuildContext context, double amount) {
    if (amount == 0) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return isDark ? Colors.grey.shade800 : Colors.grey.shade100;
    }
    if (amount < 200) return Colors.red.shade200; // Very Light Red
    if (amount < 400) return Colors.red.shade400; // Light Red
    if (amount < 600) return Colors.red.shade600; // Medium Red
    if (amount < 800) return Colors.red.shade800; // Dark Red
    return Colors.red.shade900; // Very Dark Red
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
