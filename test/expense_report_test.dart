import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:civilhelp/features/expenses/models/expense_category.dart';
import 'package:civilhelp/features/reports/models/report_filter.dart';
import 'package:civilhelp/features/reports/repositories/report_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ReportRepository reportRepo;

  const String companyId = 'comp_xyz';
  final DateTime now = DateTime.now();

  setUp(() {
    firestore = FakeFirebaseFirestore();
    reportRepo = ReportRepository(firestore: firestore);
  });

  Future<void> seedExpense({
    required String id,
    required double amount,
    required ExpenseCategory category,
    required DateTime date,
    String? siteId,
    bool isDeleted = false,
  }) async {
    await firestore
        .collection('companies')
        .doc(companyId)
        .collection('expenses')
        .doc(id)
        .set({
      'companyId': companyId,
      'siteId': siteId,
      'amount': amount,
      'category': category.name,
      'date': Timestamp.fromDate(date),
      'description': 'Description $id',
      'receiptUrl': null,
      'isDeleted': isDeleted,
      'createdAt': Timestamp.fromDate(date),
      'createdBy': 'owner_1',
      'updatedAt': Timestamp.fromDate(date),
      'updatedBy': 'owner_1',
      'deletedAt': isDeleted ? Timestamp.fromDate(date) : null,
      'deletedBy': isDeleted ? 'owner_1' : null,
    });
  }

  group('Expense Summary Report Repository Unit Tests', () {
    test('Correctly aggregates expenses in date range and excludes soft deleted records', () async {
      final start = now.subtract(const Duration(days: 5));
      final end = now.add(const Duration(days: 5));

      // Active expenses in range
      await seedExpense(id: 'exp1', amount: 1000.0, category: ExpenseCategory.materials, date: now, siteId: 'site1');
      await seedExpense(id: 'exp2', amount: 1500.0, category: ExpenseCategory.fuel, date: now, siteId: 'site2');

      // Soft deleted expense in range (should be ignored)
      await seedExpense(id: 'exp3', amount: 2000.0, category: ExpenseCategory.rent, date: now, siteId: 'site1', isDeleted: true);

      // Expense outside range (before)
      await seedExpense(id: 'exp4', amount: 3000.0, category: ExpenseCategory.materials, date: now.subtract(const Duration(days: 10)), siteId: 'site1');

      // Expense outside range (after)
      await seedExpense(id: 'exp5', amount: 4000.0, category: ExpenseCategory.other, date: now.add(const Duration(days: 10)), siteId: 'site2');

      final filter = ReportFilter(
        companyId: companyId,
        startDate: start,
        endDate: end,
      );

      final report = await reportRepo.getExpenseReport(filter);

      // Should only contain active exp1 and exp2
      expect(report.totalExpenses, 2500.0);
      expect(report.expenseCount, 2);
      expect(report.categoryEntries.length, 2);

      final materialsEntry = report.categoryEntries.firstWhere((c) => c.categoryName == 'Materials');
      expect(materialsEntry.totalAmount, 1000.0);
      expect(materialsEntry.percentage, 40.0);

      final fuelEntry = report.categoryEntries.firstWhere((c) => c.categoryName == 'Fuel');
      expect(fuelEntry.totalAmount, 1500.0);
      expect(fuelEntry.percentage, 60.0);
    });

    test('Correctly filters by siteId and aggregates metrics', () async {
      final start = now.subtract(const Duration(days: 5));
      final end = now.add(const Duration(days: 5));

      await seedExpense(id: 'exp1', amount: 1000.0, category: ExpenseCategory.materials, date: now, siteId: 'site1');
      await seedExpense(id: 'exp2', amount: 2000.0, category: ExpenseCategory.fuel, date: now, siteId: 'site2');

      // Filter specifically for site1
      final filter = ReportFilter(
        companyId: companyId,
        startDate: start,
        endDate: end,
        siteId: 'site1',
      );

      final report = await reportRepo.getExpenseReport(filter);

      expect(report.totalExpenses, 1000.0);
      expect(report.expenseCount, 1);
      expect(report.categoryEntries.length, 1);
      expect(report.categoryEntries.first.categoryName, 'Materials');
      expect(report.categoryEntries.first.percentage, 100.0);
    });
  });
}
