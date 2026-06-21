import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:civilhelp/app/theme.dart';
import 'package:civilhelp/app/router.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../../shared/widgets/module_header.dart';
import '../../../shared/widgets/module_empty_state.dart';
import '../../../shared/widgets/operational_metrics_strip.dart';
import '../../sites/providers/site_provider.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../widgets/expense_card.dart';

enum DateRangeType {
  today('Today'),
  thisWeek('This Week'),
  thisMonth('This Month'),
  custom('Custom Range');

  final String label;
  const DateRangeType(this.label);
}

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  String _searchQuery = '';
  String? _selectedFilterSiteId;
  DateRangeType _selectedDateRangeType = DateRangeType.thisMonth;
  DateTimeRange? _customDateRange;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
      initialDateRange: _customDateRange,
    );
    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedDateRangeType = DateRangeType.custom;
      });
    }
  }

  void _navigateToAddEdit([ExpenseModel? expense]) {
    if (expense == null) {
      Navigator.of(context).pushNamed(AppRoutes.addExpense);
    } else {
      Navigator.of(context).pushNamed(AppRoutes.editExpense, arguments: expense);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesStreamProvider);
    final sitesAsync = ref.watch(sitesStreamProvider);
    final currentMonthExpensesAsync = ref.watch(currentMonthExpensesTotalProvider);

    return AppScaffold(
      fab: FloatingActionButton(
        onPressed: () => _navigateToAddEdit(),
        tooltip: 'Add Expense',
        backgroundColor: context.customColors.site,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ModuleHeader(
            title: 'Expenses',
            subtitle: 'Track overhead and project costs',
            showBackButton: false,
          ),
          Expanded(
            child: expensesAsync.when(
              data: (expenses) {
                final sites = sitesAsync.value ?? [];
                final siteMap = {for (final s in sites) s.id: s.name};

                // Apply filters
                final filteredExpenses = expenses.where((exp) {
                  // Search query
                  if (_searchQuery.isNotEmpty &&
                      !exp.description.toLowerCase().contains(_searchQuery.toLowerCase()) &&
                      !exp.category.displayName.toLowerCase().contains(_searchQuery.toLowerCase())) {
                    return false;
                  }

                  // Site filter
                  if (_selectedFilterSiteId != null && exp.siteId != _selectedFilterSiteId) {
                    return false;
                  }

                  // Date filter
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  switch (_selectedDateRangeType) {
                    case DateRangeType.today:
                      final start = today;
                      final end = today.add(const Duration(days: 1));
                      if (exp.date.isBefore(start) || exp.date.isAfter(end)) return false;
                      break;
                    case DateRangeType.thisWeek:
                      final weekday = now.weekday;
                      final start = today.subtract(Duration(days: weekday - 1));
                      final end = start.add(const Duration(days: 7));
                      if (exp.date.isBefore(start) || exp.date.isAfter(end)) return false;
                      break;
                    case DateRangeType.thisMonth:
                      final start = DateTime(now.year, now.month, 1);
                      final end = DateTime(now.year, now.month + 1, 1);
                      if (exp.date.isBefore(start) || exp.date.isAfter(end)) return false;
                      break;
                    case DateRangeType.custom:
                      if (_customDateRange != null) {
                        final start = _customDateRange!.start;
                        final end = _customDateRange!.end.add(const Duration(days: 1));
                        if (exp.date.isBefore(start) || exp.date.isAfter(end)) return false;
                      }
                      break;
                  }

                  return true;
                }).toList();

                // Compute summary metrics
                final totalFilteredExpenses = filteredExpenses.fold<double>(
                  0.0,
                  (sum, item) => sum + item.amount,
                );

                final monthlyGlobalExpenses = currentMonthExpensesAsync.value ?? 0.0;

                // Category or site breakdown logic
                final Map<String, double> siteBreakdown = {};
                for (final exp in filteredExpenses) {
                  final name = exp.siteId == null ? 'All Sites' : (siteMap[exp.siteId] ?? 'Unknown Site');
                  siteBreakdown[name] = (siteBreakdown[name] ?? 0.0) + exp.amount;
                }

                final mostExpensiveSite = siteBreakdown.isEmpty
                    ? 'None'
                    : siteBreakdown.entries.reduce((a, b) => a.value > b.value ? a : b).key;

                if (expenses.isEmpty) {
                  return ModuleEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No Expenses Yet',
                    description: 'Record project expenses to keep track of overheads.',
                    ctaLabel: 'Add Expense',
                    onCta: () => _navigateToAddEdit(),
                    iconColor: context.customColors.site,
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Metrics strip
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      child: OperationalMetricsStrip(
                        metrics: [
                          OperationalMetricData(
                            label: 'Filtered Total',
                            value: '₹${totalFilteredExpenses.toStringAsFixed(0)}',
                            icon: Icons.filter_alt_outlined,
                            color: context.customColors.site,
                          ),
                          OperationalMetricData(
                            label: 'This Month',
                            value: '₹${monthlyGlobalExpenses.toStringAsFixed(0)}',
                            icon: Icons.calendar_month_outlined,
                            color: context.customColors.success,
                          ),
                          OperationalMetricData(
                            label: 'Top Site Cost',
                            value: mostExpensiveSite,
                            icon: Icons.location_on_outlined,
                            color: context.customColors.advance,
                          ),
                        ],
                      ),
                    ),

                    // Filter controls
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search expenses...',
                                    prefixIcon: const Icon(Icons.search, size: 20),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      _searchQuery = val;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              DropdownButton<String?>(
                                value: _selectedFilterSiteId,
                                underline: const SizedBox(),
                                icon: const Icon(Icons.filter_list),
                                hint: const Text('Site'),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('All Sites'),
                                  ),
                                  ...sites.map((s) {
                                    return DropdownMenuItem<String?>(
                                      value: s.id,
                                      child: Text(s.name),
                                    );
                                  }),
                                ],
                                onChanged: (val) {
                                  setState(() {
                                    _selectedFilterSiteId = val;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ...DateRangeType.values.map((type) {
                                final isSelected = _selectedDateRangeType == type;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6.0),
                                  child: ChoiceChip(
                                    label: Text(type.label),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      if (selected) {
                                        if (type == DateRangeType.custom) {
                                          _selectCustomDateRange();
                                        } else {
                                          setState(() {
                                            _selectedDateRangeType = type;
                                          });
                                        }
                                      }
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Expenses List
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(expensesStreamProvider);
                          ref.invalidate(currentMonthExpensesTotalProvider);
                          ref.invalidate(sitesStreamProvider);
                        },
                        child: filteredExpenses.isEmpty
                            ? const Center(
                                child: Text('No expenses match the selected filters.'),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                                itemCount: filteredExpenses.length,
                                itemBuilder: (context, index) {
                                  final exp = filteredExpenses[index];
                                  final name = exp.siteId == null ? 'All Sites' : (siteMap[exp.siteId] ?? 'Unknown Site');
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: ExpenseCard(
                                      expense: exp,
                                      siteName: name,
                                      onTap: () => _navigateToAddEdit(exp),
                                      onDelete: () => _showDeleteDialog(context, ref, exp.id),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => ModuleEmptyState(
                icon: Icons.error_outline,
                title: 'Error Loading Expenses',
                description: err.toString(),
                iconColor: context.colors.error,
                ctaLabel: 'Retry',
                onCta: () {
                  ref.invalidate(expensesStreamProvider);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, String expenseId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense? This action can be undone by administrators.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(deleteExpenseProvider(expenseId).future);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Expense deleted successfully')),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: context.colors.error)),
          ),
        ],
      ),
    );
  }
}
