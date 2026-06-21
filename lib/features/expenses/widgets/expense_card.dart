import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:civilhelp/app/theme.dart';
import 'package:civilhelp/shared/widgets/premium_module_card.dart';
import '../models/expense_category.dart';
import '../models/expense_model.dart';

class ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final String siteName;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const ExpenseCard({
    super.key,
    required this.expense,
    required this.siteName,
    required this.onTap,
    this.onDelete,
  });

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
    final isDark = context.isDarkMode;
    final dateStr = DateFormat('dd MMM yyyy').format(expense.date);
    final categoryEmoji = _getCategoryEmoji(expense.category);

    return PremiumModuleCard(
      onTap: onTap,
      glowColor: context.customColors.site,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      '$categoryEmoji ',
                      style: const TextStyle(fontSize: 18),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.category.displayName,
                            style: context.text.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            siteName,
                            style: context.text.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (expense.receiptUrl != null && expense.receiptUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: Tooltip(
                        message: 'Receipt attached',
                        child: Icon(
                          Icons.receipt_outlined,
                          size: 18,
                          color: context.colors.primary,
                        ),
                      ),
                    ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (value) {
                      if (value == 'edit') {
                        onTap();
                      } else if (value == 'delete') {
                        onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      if (onDelete != null)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (expense.description.isNotEmpty) ...[
            Text(
              expense.description,
              style: context.text.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
          ],
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              Text(
                '₹${expense.amount.toStringAsFixed(2)}',
                style: context.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFF00D68F) : const Color(0xFF00A261),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
