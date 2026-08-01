import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/transaction_provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../history/history_page.dart';
import '../../widgets/expense_heatmap.dart';

class InsightsPage extends ConsumerWidget {
  const InsightsPage({super.key});
////Insights Page
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdownAsync = ref.watch(categoryBreakdownProvider);
    final totalExpenseAsync = ref.watch(totalExpenseProvider);
    final uncategorizedAsync = ref.watch(uncategorizedTransactionsProvider);
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    final textColor = isDarkMode ? Colors.white : AppColors.textDark;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : AppColors.cardBackground;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode, color: textColor),
            onPressed: () {
              ref.read(themeProvider.notifier).state =
                  isDarkMode ? ThemeMode.light : ThemeMode.dark;
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Uncategorized Banner
              uncategorizedAsync.when(
                data: (list) {
                  if (list.isEmpty) return const SizedBox.shrink();
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistoryPage(initialFilter: 'Uncategorized'),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '⚠ ${list.length} Expenses Need Categorization\nReview Now',
                              style: TextStyle(
                                color: Colors.amber.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right, color: Colors.amber.shade800),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              
              // Total Expense Card
              totalExpenseAsync.when(
                data: (amount) => _buildTotalExpenseCard(amount),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error: $e'),
              ),
              const SizedBox(height: 20),

              // Filter Chips
              _buildFilterChips(context, ref, cardColor, textColor),
              const SizedBox(height: 24),

              Text('Category Breakdown',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
              const SizedBox(height: 16),

              // Donut Chart & List
              breakdownAsync.when(
                data: (data) {
                  if (data.isEmpty) {
                    return _buildEmptyState(cardColor);
                  }
                  final totalExpense =
                      data.values.fold(0.0, (sum, item) => sum + item);

                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: SizedBox(
                          height: 198, // Reduced by 10% from 220
                          child: PieChart(
                            key: ValueKey(data.length),
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 45, // Reduced by 10% from 50
                              sections: _generateSections(data, totalExpense),
                            ),
                            swapAnimationDuration: Duration.zero,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Breakdown List
                      ...data.entries.map((entry) {
                        final percentage = (entry.value / totalExpense * 100);
                        final color = _getColorForCategory(entry.key);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: color.withOpacity(0.15),
                                radius: 24,
                                child: Icon(
                                  _getIconDataForCategory(entry.key),
                                  color: color,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(entry.key,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: textColor)),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: percentage / 100,
                                        backgroundColor: theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
                                        color: color,
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${AppStrings.currency}${entry.value.toStringAsFixed(0)}',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: textColor),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error: $err'),
              ),
              const SizedBox(height: 24),

              // Expense Heatmap
              Text('Monthly Expense Heatmap',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
              const SizedBox(height: 16),
              const ExpenseHeatmap(),
              
              const SizedBox(height: 24),
              
              // Analytics Summary Cards
              Text('Spending Insights',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
              const SizedBox(height: 16),
              _buildSummaryCards(ref, cardColor, textColor),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color cardColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('No expenses found',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Try changing the time filter or add a transaction.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTotalExpenseCard(double amount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.expense, Color(0xFFE84343)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.expense.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Expenses',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(
            '${AppStrings.currency}${amount.toStringAsFixed(2)}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: -1),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, WidgetRef ref, Color cardColor, Color textColor) {
    final currentFilter = ref.watch(timeFilterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: TimeFilter.values.map((filter) {
          final isSelected = currentFilter == filter;
          String label = '';
          switch (filter) {
            case TimeFilter.today:
              label = 'Today';
              break;
            case TimeFilter.thisWeek:
              label = 'This Week';
              break;
            case TimeFilter.thisMonth:
              label = 'This Month';
              break;
            case TimeFilter.customDate:
              label = 'Custom Date';
              break;
            case TimeFilter.allTime:
              label = 'All Time';
              break;
          }
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(label,
                  style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : textColor)),
              selected: isSelected,
              onSelected: (_) async {
                  if (filter == TimeFilter.customDate) {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: ref.read(customDateProvider) ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: AppColors.primary, // header background color
                              onPrimary: Colors.white, // header text color
                              onSurface: AppColors.textDark, // body text color
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      ref.read(customDateProvider.notifier).state = picked;
                      ref.read(timeFilterProvider.notifier).state = filter;
                    }
                  } else {
                    ref.read(timeFilterProvider.notifier).state = filter;
                  }
              },
              backgroundColor: cardColor,
              selectedColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Colors.transparent)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCards(WidgetRef ref, Color cardColor, Color textColor) {
    final biggestExpenseAsync = ref.watch(biggestExpenseProvider);
    final mostSpendingCatAsync = ref.watch(mostSpendingCategoryProvider);
    final avgDailyAsync = ref.watch(averageDailySpendingProvider);
    final txCountAsync = ref.watch(transactionsCountProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildSmallSummaryCard(
            'Biggest Expense',
            biggestExpenseAsync.when(
                data: (v) => '${AppStrings.currency}${v.toStringAsFixed(0)}',
                loading: () => '...',
                error: (_, __) => 'Err'),
            Icons.trending_up,
            AppColors.expense,
            cardColor,
            textColor,
          ),
          const SizedBox(width: 12),
          _buildSmallSummaryCard(
            'Top Category',
            mostSpendingCatAsync.when(
                data: (v) => v?.key ?? 'None',
                loading: () => '...',
                error: (_, __) => 'Err'),
            Icons.category,
            AppColors.primary,
            cardColor,
            textColor,
          ),
          const SizedBox(width: 12),
          _buildSmallSummaryCard(
            'Avg Daily',
            avgDailyAsync.when(
                data: (v) => '${AppStrings.currency}${v.toStringAsFixed(0)}',
                loading: () => '...',
                error: (_, __) => 'Err'),
            Icons.calendar_today,
            Colors.orange,
            cardColor,
            textColor,
          ),
          const SizedBox(width: 12),
          _buildSmallSummaryCard(
            'Transactions',
            txCountAsync.when(
                data: (v) => '$v',
                loading: () => '...',
                error: (_, __) => 'Err'),
            Icons.receipt_long,
            Colors.blue,
            cardColor,
            textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSmallSummaryCard(
      String title, String value, IconData icon, Color iconColor, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 12),
          Text(title,
              style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generateSections(
      Map<String, double> data, double total) {
    return data.entries.map((entry) {
      final color = _getColorForCategory(entry.key);

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '',
        radius: 36, // Reduced by 10% from 40
        badgeWidget: _Badge(
          _getIconDataForCategory(entry.key),
          size: 28, // Reduced slightly
          color: color,
        ),
        badgePositionPercentageOffset: 1.1,
      );
    }).toList();
  }

  Color _getColorForCategory(String category) {
    switch (category) {
      case 'Food':
        return AppColors.food;
      case 'Petrol':
        return AppColors.petrol;
      case 'Travel':
        return AppColors.travel;
      case 'Entertainment':
        return AppColors.entertainment;
      case 'Other':
        return AppColors.other;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconDataForCategory(String category) {
    switch (category) {
      case 'Food':
        return Icons.fastfood;
      case 'Petrol':
        return Icons.local_gas_station;
      case 'Travel':
        return Icons.flight_takeoff;
      case 'Entertainment':
        return Icons.movie;
      case 'Other':
        return Icons.category;
      default:
        return Icons.help_outline;
    }
  }

}

class _Badge extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;

  const _Badge(this.icon, {required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.6,
        ),
      ),
    );
  }
}
