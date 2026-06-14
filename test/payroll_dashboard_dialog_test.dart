import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:civilhelp/features/payroll/screens/payroll_dashboard_screen.dart';
import 'package:civilhelp/features/payroll/providers/payroll_providers.dart';
import 'package:civilhelp/features/payroll/repositories/payroll_repository.dart';
import 'package:civilhelp/features/payroll/models/payroll_period_model.dart';
import 'package:civilhelp/core/providers/company_provider.dart';
import 'package:civilhelp/features/auth/providers/auth_provider.dart';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

class FakePayrollRepository extends PayrollRepository {
  FakePayrollRepository({required super.firestore});

  bool failOnCreate = false;
  String failMessage = 'Error creating period';
  final List<PayrollPeriodModel> periods = [];

  @override
  Stream<List<PayrollPeriodModel>> getPayrollPeriodsStream(String companyId) {
    return Stream.value(periods);
  }

  @override
  Future<PayrollPeriodModel> createPayrollPeriod({
    required String companyId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required String createdBy,
  }) async {
    if (failOnCreate) {
      throw ZeroGrossPayrollException(failMessage);
    }
    final model = PayrollPeriodModel(
      id: 'new_period_id',
      companyId: companyId,
      name: name,
      startDate: startDate,
      endDate: endDate,
      status: 'open',
      createdAt: DateTime.now(),
      createdBy: createdBy,
    );
    periods.add(model);
    return model;
  }
}

void main() {
  late FakePayrollRepository fakeRepo;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    fakeRepo = FakePayrollRepository(firestore: fakeFirestore);
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        userCompanyIdProvider.overrideWith((ref) => 'comp_abc'),
        currentUserProvider.overrideWith((ref) => null),
        payrollRepositoryProvider.overrideWith((ref) => fakeRepo),
        firestoreProvider.overrideWith((ref) => fakeFirestore),
      ],
      child: const MaterialApp(
        home: PayrollDashboardScreen(),
      ),
    );
  }

  testWidgets('Test user-facing dialog behavior - Success path', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // 1. Verify screen renders the empty state or period list
    expect(find.text('Payroll Dashboard'), findsOneWidget);

    // 2. Tap FAB to open the New Period dialog
    final fabFinder = find.byType(FloatingActionButton);
    expect(fabFinder, findsOneWidget);
    await tester.tap(fabFinder);
    await tester.pumpAndSettle();

    // 3. Verify dialog is open
    expect(find.text('New Payroll Period'), findsOneWidget);

    // 4. Fill in the Period Name field
    final nameFieldFinder = find.byType(TextFormField);
    expect(nameFieldFinder, findsOneWidget);
    await tester.enterText(nameFieldFinder, 'Test New Period');
    await tester.pumpAndSettle();

    // 5. Tap the Create button (success path)
    fakeRepo.failOnCreate = false;
    final createButtonFinder = find.text('Create');
    expect(createButtonFinder, findsOneWidget);
    await tester.tap(createButtonFinder);
    await tester.pumpAndSettle();

    // 6. Verify dialog closes (Navigator.pop called on success)
    expect(find.text('New Payroll Period'), findsNothing);

    // 7. Verify SnackBar success message
    expect(find.text('Payroll period created successfully.'), findsOneWidget);
  });

  testWidgets('Test user-facing dialog behavior - Failure path (keeps dialog open)', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // 1. Tap FAB to open the New Period dialog
    final fabFinder = find.byType(FloatingActionButton);
    await tester.tap(fabFinder);
    await tester.pumpAndSettle();

    // 2. Verify dialog is open
    expect(find.text('New Payroll Period'), findsOneWidget);

    // 3. Set failure state on fake repo
    fakeRepo.failOnCreate = true;
    fakeRepo.failMessage = 'Zero gross earnings found.';

    // 4. Tap the Create button
    final createButtonFinder = find.text('Create');
    await tester.tap(createButtonFinder);
    await tester.pumpAndSettle();

    // 5. Verify dialog remains open (Navigator.pop is NOT called on failure)
    expect(find.text('New Payroll Period'), findsOneWidget);

    // 6. Verify error text is displayed inside the dialog
    expect(find.byKey(const Key('dialog_error_text')), findsOneWidget);
    expect(find.text('Zero gross earnings found.'), findsOneWidget);

    // 7. Tap Cancel button to close dialog manually
    final cancelButtonFinder = find.text('Cancel');
    await tester.tap(cancelButtonFinder);
    await tester.pumpAndSettle();

    // 8. Verify dialog is now closed
    expect(find.text('New Payroll Period'), findsNothing);
  });
}
