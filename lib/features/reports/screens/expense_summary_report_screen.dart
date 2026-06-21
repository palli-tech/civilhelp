import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:civilhelp/app/theme.dart';
import 'package:civilhelp/core/providers/company_provider.dart';
import 'package:civilhelp/features/sites/providers/site_provider.dart';
import 'package:civilhelp/features/expenses/models/expense_category.dart';
import 'package:civilhelp/features/expenses/models/expense_model.dart';
import 'package:civilhelp/shared/layouts/app_scaffold.dart';
import 'package:civilhelp/shared/widgets/module_header.dart';
import 'package:civilhelp/shared/widgets/premium_module_card.dart';
import '../models/report_filter.dart';
import '../models/report_dtos.dart';
import '../providers/report_provider.dart';
import '../widgets/report_filter_bar.dart';

class ExpenseSummaryReportScreen extends ConsumerStatefulWidget {
  const ExpenseSummaryReportScreen({super.key});

  @override
  ConsumerState<ExpenseSummaryReportScreen> createState() => _ExpenseSummaryReportScreenState();
}

class _ExpenseSummaryReportScreenState extends ConsumerState<ExpenseSummaryReportScreen> {
  String? _selectedSiteId;
  ExpenseCategory? _selectedCategory;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  Color _getCategoryColor(String categoryName, BuildContext context) {
    switch (categoryName.toLowerCase()) {
      case 'materials':
        return context.customColors.site;
      case 'fuel':
        return context.customColors.worker;
      case 'food':
        return context.customColors.success;
      case 'rent':
        return context.customColors.info;
      case 'tools':
        return context.customColors.advance;
      case 'transport':
        return context.customColors.payroll;
      default:
        return context.colors.outline;
    }
  }

  String _getCategoryEmoji(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.materials:
        return '🧱';
      case ExpenseCategory.fuel:
        return '⛽';
      case ExpenseCategory.food:
        return '🍲';
      case ExpenseCategory.rent:
        return '🏠';
      case ExpenseCategory.tools:
        return '🛠️';
      case ExpenseCategory.transport:
        return '🚚';
      case ExpenseCategory.other:
        return '🪙';
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyIdAsync = ref.watch(userCompanyIdProvider);

    return AppScaffold(
      child: Column(
        children: [
          const ModuleHeader(
            title: 'Expense Summary',
            subtitle: 'Analyze company overheads and expenses',
            showBackButton: true,
          ),
          Expanded(
            child: companyIdAsync.when(
              data: (companyId) {
                if (companyId.isEmpty) {
                  return const Center(child: Text('Company not associated with user.'));
                }

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Site and Date Filters
                      ReportFilterBar(
                        selectedSiteId: _selectedSiteId,
                        selectedWorkerId: null,
                        startDate: _startDate,
                        endDate: _endDate,
                        showWorkerFilter: false,
                        showSiteFilter: true,
                        onSiteChanged: (val) => setState(() => _selectedSiteId = val),
                        onWorkerChanged: (_) {},
                        onDateRangeChanged: (start, end) => setState(() {
                          _startDate = start;
                          _endDate = end;
                        }),
                      ),

                      // Category Filter Dropdown
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                        child: DropdownButtonFormField<ExpenseCategory>(
                          initialValue: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Expense Category Filter',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<ExpenseCategory>(
                              value: null,
                              child: Text('All Categories'),
                            ),
                            ...ExpenseCategory.values.map((cat) => DropdownMenuItem<ExpenseCategory>(
                              value: cat,
                              child: Text('${_getCategoryEmoji(cat)} ${cat.displayName}'),
                            )),
                          ],
                          onChanged: (val) => setState(() => _selectedCategory = val),
                        ),
                      ),

                      const Divider(height: 1),

                      // Main report content
                      _buildReportContent(companyId),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(),
              )),
              error: (err, stack) => Center(child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Text('Error: $err'),
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent(String companyId) {
    final filter = ReportFilter(
      companyId: companyId,
      startDate: _startDate,
      endDate: DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59),
      siteId: _selectedSiteId,
    );

    final reportAsync = ref.watch(expenseReportProvider(filter));
    final sitesAsync = ref.watch(sitesStreamProvider);
    final sites = sitesAsync.value ?? [];

    return reportAsync.when(
      data: (report) {
        // Filter values locally by Category if specified
        final List<ExpenseModel> displayExpenses;
        final double displayTotal;
        final int displayCount;
        final List<ExpenseCategorySummaryEntry> displayCategoryBreakdown;

        if (_selectedCategory != null) {
          displayExpenses = report.rawExpenses
              .where((e) => e.category == _selectedCategory)
              .toList();
          displayTotal = displayExpenses.fold(0.0, (sum, item) => sum + item.amount);
          displayCount = displayExpenses.length;
          displayCategoryBreakdown = report.categoryEntries
              .where((e) => e.categoryName.toLowerCase() == _selectedCategory!.displayName.toLowerCase())
              .toList();
        } else {
          displayExpenses = report.rawExpenses;
          displayTotal = report.totalExpenses;
          displayCount = report.expenseCount;
          displayCategoryBreakdown = report.categoryEntries;
        }

        final currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Overview Summary Cards
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: context.customColors.error.withValues(alpha: 0.15),
                              child: Icon(Icons.receipt_long, color: context.customColors.error, size: 26),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Expenses',
                                    style: context.text.bodyMedium?.copyWith(
                                      color: context.colors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currencyFmt.format(displayTotal),
                                    style: context.text.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: context.customColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              displayCount.toString(),
                              style: context.text.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.customColors.info,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Payments',
                              style: context.text.bodySmall?.copyWith(
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Category Breakdown Chart/Progress Indicators
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category Breakdown',
                        style: context.text.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (displayCategoryBreakdown.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Text('No breakdown details available.'),
                          ),
                        )
                      else
                        ...displayCategoryBreakdown.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        entry.categoryName,
                                        style: context.text.bodyMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '₹${entry.totalAmount.toStringAsFixed(0)}',
                                      style: context.text.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: entry.percentage / 100,
                                    minHeight: 6,
                                    backgroundColor: context.colors.outlineVariant.withValues(alpha: 0.2),
                                    color: _getCategoryColor(entry.categoryName, context),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '${entry.percentage.toStringAsFixed(1)}%',
                                    style: context.text.bodySmall?.copyWith(
                                      color: context.colors.onSurfaceVariant,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 3. Chronological Transactions List Header
              Padding(
                padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
                child: Text(
                  'Chronological Ledger',
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // 4. Individual Transactions List
              if (displayExpenses.isEmpty)
                const Card(
                  elevation: 1,
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text('No expenses match the selected filters.')),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayExpenses.length,
                  itemBuilder: (context, index) {
                    final expense = displayExpenses[index];
                    final dateStr = DateFormat('dd MMM yyyy').format(expense.date);
                    final emoji = _getCategoryEmoji(expense.category);

                    // Dynamically resolve site name
                    final site = sites.where((s) => s.id == expense.siteId).firstOrNull;
                    final siteName = site?.name ?? 'General / No Site';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: PremiumModuleCard(
                        padding: const EdgeInsets.all(16),
                        glowColor: _getCategoryColor(expense.category.displayName, context),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: _getCategoryColor(expense.category.displayName, context).withValues(alpha: 0.15),
                            child: Text(emoji, style: const TextStyle(fontSize: 16)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        expense.category.displayName,
                                        style: context.text.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '₹${expense.amount.toStringAsFixed(2)}',
                                      style: context.text.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: context.customColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        siteName,
                                        style: context.text.bodySmall?.copyWith(
                                          color: context.colors.onSurfaceVariant,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      dateStr,
                                      style: context.text.bodySmall?.copyWith(
                                        color: context.colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                if (expense.description.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    expense.description,
                                    style: context.text.bodyMedium?.copyWith(
                                      color: context.colors.onSurface,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48.0),
          child: Text('Error rendering report: $err'),
        ),
      ),
    );
  }
}
