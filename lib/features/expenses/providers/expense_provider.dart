import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/core/providers/company_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/expense_category.dart';
import '../models/expense_model.dart';
import '../repositories/expense_repository.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository();
});

/// Stream of all active (non-deleted) expenses for the company
final expensesStreamProvider = StreamProvider<List<ExpenseModel>>((ref) {
  final repository = ref.watch(expenseRepositoryProvider);
  final userCompanyId = ref.watch(userCompanyIdProvider);

  return userCompanyId.when(
    data: (companyId) => repository.getExpensesStream(companyId),
    loading: () => Stream.value([]),
    error: (error, _) => Stream.error(error),
  );
});

/// Fetch a single expense by ID
final expenseByIdProvider = FutureProvider.family<ExpenseModel?, String>((ref, expenseId) async {
  final repository = ref.watch(expenseRepositoryProvider);
  final companyId = await ref.watch(userCompanyIdProvider.future);
  return repository.getExpenseById(companyId: companyId, expenseId: expenseId);
});

/// Create a new expense
final createExpenseProvider = FutureProvider.family<ExpenseModel, (
  double amount,
  ExpenseCategory category,
  DateTime date,
  String description,
  String? siteId,
  String? receiptUrl,
)>((ref, params) async {
  final repository = ref.watch(expenseRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);
  final companyId = ref.watch(userCompanyIdProvider).value ?? 'default-company';

  final expense = await repository.createExpense(
    companyId: companyId,
    amount: params.$1,
    category: params.$2,
    date: params.$3,
    description: params.$4,
    siteId: params.$5,
    receiptUrl: params.$6,
    createdBy: currentUser?.uid ?? 'unknown',
  );

  ref.invalidate(expensesStreamProvider);
  ref.invalidate(currentMonthExpensesTotalProvider);

  return expense;
});

/// Update an existing expense
final updateExpenseProvider = FutureProvider.family<void, ExpenseModel>((ref, expense) async {
  final repository = ref.watch(expenseRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);

  final updatedExpense = expense.copyWith(
    updatedBy: currentUser?.uid ?? 'unknown',
    updatedAt: DateTime.now(),
  );

  await repository.updateExpense(updatedExpense);

  ref.invalidate(expensesStreamProvider);
  ref.invalidate(currentMonthExpensesTotalProvider);
  ref.invalidate(expenseByIdProvider(expense.id));
});

/// Soft delete an expense
final deleteExpenseProvider = FutureProvider.family<void, String>((ref, expenseId) async {
  final repository = ref.watch(expenseRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);
  final companyId = await ref.watch(userCompanyIdProvider.future);

  await repository.softDeleteExpense(
    companyId: companyId,
    expenseId: expenseId,
    deletedBy: currentUser?.uid ?? 'unknown',
  );

  ref.invalidate(expensesStreamProvider);
  ref.invalidate(currentMonthExpensesTotalProvider);
  ref.invalidate(expenseByIdProvider(expenseId));
});

/// Stream of total expenses in the current calendar month
final currentMonthExpensesTotalProvider = StreamProvider<double>((ref) {
  final repository = ref.watch(expenseRepositoryProvider);
  final companyId = ref.watch(userCompanyIdProvider);

  return companyId.when(
    data: (id) {
      if (id.isEmpty) return Stream.value(0.0);
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 1);

      return repository
          .getExpensesByDateRangeStream(
            companyId: id,
            start: startOfMonth,
            end: endOfMonth,
          )
          .map((expenses) => expenses.fold<double>(
                0.0,
                (total, item) => total + item.amount,
              ));
    },
    loading: () => Stream.value(0.0),
    error: (error, _) => Stream.error(error),
  );
});
