import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civilhelp/features/payroll/repositories/payroll_repository.dart';
import 'package:civilhelp/features/attendance/repositories/attendance_repository.dart';
import 'package:civilhelp/features/advances/repositories/advance_repository.dart';
import 'package:civilhelp/features/reports/repositories/report_repository.dart';
import 'package:civilhelp/features/reports/models/report_filter.dart';
import 'package:civilhelp/features/reports/models/worker_ledger_entry.dart';
import 'package:civilhelp/features/payroll/models/payroll_register_model.dart';
import 'package:civilhelp/features/payments/models/payment_model.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late PayrollRepository payrollRepo;
  late AttendanceRepository attendanceRepo;
  late AdvanceRepository advanceRepo;
  late ReportRepository reportRepo;

  const String companyId = 'reconcile_company';
  const String createdBy = 'admin_user';

  final DateTime dateDay1 = DateTime.now().subtract(const Duration(days: 3));
  final DateTime dateDay2 = DateTime.now().subtract(const Duration(days: 2));
  final DateTime periodStart = DateTime.now().subtract(const Duration(days: 5));
  final DateTime periodEnd = DateTime.now().add(const Duration(days: 2));

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    payrollRepo = PayrollRepository(firestore: firestore);
    attendanceRepo = AttendanceRepository(firestore: firestore);
    advanceRepo = AdvanceRepository(firestore: firestore);
    reportRepo = ReportRepository(firestore: firestore);

    await firestore.collection('companies').doc(companyId).set({
      'attendanceBackdateLimitDays': 90,
    });

    // Seed worker profiles
    await firestore.collection('companies').doc(companyId).collection('labour').doc('worker_a').set({
      'fullName': 'Worker A',
      'status': 'active',
      'dailyWage': 500.0,
      'assignedSiteId': 'site_a',
      'assignedSiteName': 'Site A',
    });

    await firestore.collection('companies').doc(companyId).collection('labour').doc('worker_b').set({
      'fullName': 'Worker B',
      'status': 'active',
      'dailyWage': 600.0,
      'assignedSiteId': 'site_b',
      'assignedSiteName': 'Site B',
    });

    // Seed sites with required fields (startDate, createdAt, etc) to prevent cast errors
    await firestore.collection('companies').doc(companyId).collection('sites').doc('site_a').set({
      'name': 'Site A',
      'location': 'Location A',
      'client': 'Client A',
      'startDate': Timestamp.fromDate(periodStart),
      'status': 'active',
      'companyId': companyId,
      'createdAt': Timestamp.now(),
      'createdBy': createdBy,
    });
    await firestore.collection('companies').doc(companyId).collection('sites').doc('site_b').set({
      'name': 'Site B',
      'location': 'Location B',
      'client': 'Client B',
      'startDate': Timestamp.fromDate(periodStart),
      'status': 'active',
      'companyId': companyId,
      'createdAt': Timestamp.now(),
      'createdBy': createdBy,
    });
  });

  Future<void> setupReconciliationData() async {
    // 1. Attendance records (worker_a works at site_a, worker_b works at site_b)
    await attendanceRepo.createAttendance(
      labourId: 'worker_a',
      labourName: 'Worker A',
      siteId: 'site_a',
      siteName: 'Site A',
      date: dateDay1,
      status: 'Present',
      hoursWorked: 8.0,
      musterQuantity: 1.0, // Earned 500
      companyId: companyId,
      createdBy: createdBy,
    );

    await attendanceRepo.createAttendance(
      labourId: 'worker_a',
      labourName: 'Worker A',
      siteId: 'site_a',
      siteName: 'Site A',
      date: dateDay2,
      status: 'Present',
      hoursWorked: 8.0,
      musterQuantity: 1.0, // Earned 500
      companyId: companyId,
      createdBy: createdBy,
    );

    await attendanceRepo.createAttendance(
      labourId: 'worker_b',
      labourName: 'Worker B',
      siteId: 'site_b',
      siteName: 'Site B',
      date: dateDay1,
      status: 'Present',
      hoursWorked: 8.0,
      musterQuantity: 1.0, // Earned 600
      companyId: companyId,
      createdBy: createdBy,
    );

    await attendanceRepo.createAttendance(
      labourId: 'worker_b',
      labourName: 'Worker B',
      siteId: 'site_b',
      siteName: 'Site B',
      date: dateDay2,
      status: 'Half-day',
      hoursWorked: 4.0,
      musterQuantity: 0.5, // Earned 300
      companyId: companyId,
      createdBy: createdBy,
    );

    // 2. Advances
    await advanceRepo.createAdvance(
      labourId: 'worker_a',
      labourName: 'Worker A',
      amount: 400.0,
      description: 'Advance Worker A',
      date: dateDay1,
      companyId: companyId,
      createdBy: createdBy,
    );

    await advanceRepo.createAdvance(
      labourId: 'worker_b',
      labourName: 'Worker B',
      amount: 1000.0,
      description: 'Advance Worker B',
      date: dateDay1,
      companyId: companyId,
      createdBy: createdBy,
    );

    // 3. Create payroll period & freeze & settle
    final period = await payrollRepo.createPayrollPeriod(
      companyId: companyId,
      name: 'Period Jun 1',
      startDate: periodStart,
      endDate: periodEnd,
      createdBy: createdBy,
    );

    await payrollRepo.freezePayrollPeriod(
      companyId: companyId,
      periodId: period.id,
      frozenBy: createdBy,
    );

    final calcs = await payrollRepo.calculatePayroll(
      companyId: companyId,
      periodId: period.id,
    );

    await payrollRepo.finalizePayroll(
      companyId: companyId,
      periodId: period.id,
      finalizedBy: createdBy,
      results: calcs,
      paymentMode: 'cash',
    );
  }

  group('Phase 21: Payroll Reconciliation & Report Modernization Tests', () {
    test('1. Worker Ledger matches payroll records', () async {
      await setupReconciliationData();

      final filter = ReportFilter(
        companyId: companyId,
        startDate: periodStart,
        endDate: periodEnd,
        labourId: 'worker_a',
      );

      final ledger = await reportRepo.getWorkerLedgerReport(filter);

      // Worker A has:
      // Earnings: 500 (Day 1) + 500 (Day 2) = 1000.0
      // Advances: 400.0
      // Payments: 600.0
      // Net Outstanding Balance: 0.0
      expect(ledger.totalEarned, 1000.0);
      expect(ledger.totalAdvances, 400.0);
      expect(ledger.totalPayments, 600.0);
      expect(ledger.outstandingBalance, 0.0);

      // Verify the entries list size
      expect(ledger.entries.length, 4); // 2 attendances, 1 advance, 1 payment
      
      // Verify payment entry values
      final payEntry = ledger.entries.firstWhere((e) => e.type == LedgerEntryType.payment);
      expect(payEntry.debit, 600.0);
      expect(payEntry.credit, 0.0);
    });

    test('2. Advance Report matches advances and recoveries', () async {
      await setupReconciliationData();

      final filter = ReportFilter(
        companyId: companyId,
        startDate: periodStart,
        endDate: periodEnd,
      );

      final advanceReport = await reportRepo.getAdvanceReport(filter);

      // Worker A advance: 400 (recovered 400, remaining 0)
      // Worker B advance: 1000 (recovered 900, remaining 100)
      // Total advances issued: 1400.0
      // Remaining unapplied: 100.0
      expect(advanceReport.advanceCount, 2);
      expect(advanceReport.totalAdvances, 1400.0);
      expect(advanceReport.remainingUnapplied, 100.0);
    });

    test('3. Payment Report matches settled payments', () async {
      await setupReconciliationData();

      final filter = ReportFilter(
        companyId: companyId,
        startDate: periodStart,
        endDate: periodEnd,
      );

      final paymentReport = await reportRepo.getPaymentReport(filter);

      // Payments:
      // Worker A net payable: 600.0
      // Worker B net payable: 0.0
      // Total Net settled: 600.0
      expect(paymentReport.paymentCount, 2); // payment docs generated for both workers (one has 0.0 amount)
      expect(paymentReport.totalPayments, 600.0);
    });

    test('4. Monthly Payroll Summary matches payroll summaries', () async {
      await setupReconciliationData();

      final filter = ReportFilter(
        companyId: companyId,
        startDate: periodStart,
        endDate: periodEnd,
      );

      final monthlyReport = await reportRepo.getMonthlyPayrollReport(filter);

      expect(monthlyReport.entries.length, 1);
      final entry = monthlyReport.entries.first;
      expect(entry.totalEarned, 1900.0); // 1000 (Worker A) + 900 (Worker B)
      expect(entry.totalAdvances, 1300.0); // Recoveries: 400 (Worker A) + 900 (Worker B)
      expect(entry.totalPayments, 600.0); // Net paid: 600 (Worker A) + 0 (Worker B)
      expect(entry.closingBalance, 0.0); // 1900 - 1300 - 600 = 0.0
    });

    test('5. Site Performance totals reconcile with payroll registers', () async {
      await setupReconciliationData();

      final filter = ReportFilter(
        companyId: companyId,
        startDate: periodStart,
        endDate: periodEnd,
      );

      final siteReport = await reportRepo.getSitePerformanceReport(filter);

      // Site A has:
      // Worker A: gross 1000, advance 400, payment 600.
      final siteA = siteReport.entries.firstWhere((e) => e.siteId == 'site_a');
      expect(siteA.totalEarned, 1000.0);
      expect(siteA.totalAdvances, 400.0);
      expect(siteA.totalPayments, 600.0);
      expect(siteA.outstandingBalance, 0.0);

      // Site B has:
      // Worker B: gross 900, advance 1000, payment 0.
      final siteB = siteReport.entries.firstWhere((e) => e.siteId == 'site_b');
      expect(siteB.totalEarned, 900.0);
      expect(siteB.totalAdvances, 1000.0);
      expect(siteB.totalPayments, 0.0);
      expect(siteB.outstandingBalance, -100.0); // 900 - 1000 - 0 = -100 (worker B owes 100 remaining advance)
    });

    test('6. Outstanding Balance matches advance remaining balances', () async {
      await setupReconciliationData();

      final filter = ReportFilter(
        companyId: companyId,
        startDate: periodStart,
        endDate: periodEnd,
      );

      final outstandingReport = await reportRepo.getOutstandingBalanceReport(filter);

      // All attendances in period are paid, so pending attendance earnings = 0.0.
      // Worker A remaining advance = 0.0.
      // Worker B remaining advance = 100.0.
      // Total outstanding balance (pending earned - outstanding advances) = 0 - 100 = -100.0.
      expect(outstandingReport.totalOutstandingBalance, -100.0);
      
      final entryB = outstandingReport.workerEntries.firstWhere((e) => e.labourId == 'worker_b');
      expect(entryB.totalEarned, 0.0);
      expect(entryB.totalAdvances, 100.0); // remaining advance balance
      expect(entryB.outstandingBalance, -100.0);
    });

    test('7. Cross-report reconciliation', () async {
      await setupReconciliationData();

      // Retrieve period ID
      final periods = await firestore.collection('companies/$companyId/payrollPeriods').get();
      final periodId = periods.docs.first.id;

      // 1. Worker Ledger
      final ledgerFilter = ReportFilter(
        companyId: companyId,
        startDate: periodStart,
        endDate: periodEnd,
        labourId: 'worker_a',
      );
      final ledger = await reportRepo.getWorkerLedgerReport(ledgerFilter);
      final ledgerTotalPayment = ledger.totalPayments; // 600.0

      // 2. Payroll Register
      final regDoc = await firestore
          .collection('companies/$companyId/payrollRegisters')
          .doc('${periodId}_worker_a')
          .get();
      final register = PayrollRegisterModel.fromFirestore(regDoc);
      final registerNetPayable = register.netPayable; // 600.0

      // 3. Payment Report
      final paymentFilter = ReportFilter(
        companyId: companyId,
        startDate: periodStart,
        endDate: periodEnd,
        labourId: 'worker_a',
      );
      final paymentReport = await reportRepo.getPaymentReport(paymentFilter);
      final paymentReportTotal = paymentReport.totalPayments; // 600.0

      expect(ledgerTotalPayment, registerNetPayable);
      expect(registerNetPayable, paymentReportTotal);
      expect(ledgerTotalPayment, 600.0);
    });

    test('8. Payroll Register -> Payment Integrity', () async {
      await setupReconciliationData();

      final registersSnap = await firestore.collection('companies/$companyId/payrollRegisters').get();
      for (final doc in registersSnap.docs) {
        final reg = PayrollRegisterModel.fromFirestore(doc);
        
        // Assert register arithmetic integrity: grossEarnings - deductions == netPayable
        expect(reg.grossEarnings - reg.advanceDeductions, reg.netPayable);

        // Assert payment settlement equivalence
        final payDoc = await firestore
            .collection('companies/$companyId/payments')
            .doc(reg.paymentId)
            .get();
        expect(payDoc.exists, isTrue);
        final payment = PaymentModel.fromFirestore(payDoc);
        expect(payment.amount, reg.netPayable);
      }
    });

    test('9. Soft Delete Exclusion Reconciliation', () async {
      // 1. Seed valid active attendance (earned = 500)
      await attendanceRepo.createAttendance(
        labourId: 'worker_a',
        labourName: 'Worker A',
        siteId: 'site_a',
        siteName: 'Site A',
        date: dateDay1,
        status: 'Present',
        hoursWorked: 8.0,
        musterQuantity: 1.0,
        companyId: companyId,
        createdBy: createdBy,
      );

      // 2. Seed soft-deleted attendance (should be ignored, contributes 0)
      await firestore
          .collection('companies')
          .doc(companyId)
          .collection('attendance')
          .add({
            'labourId': 'worker_a',
            'labourName': 'Worker A',
            'siteId': 'site_a',
            'siteName': 'Site A',
            'date': Timestamp.fromDate(dateDay2),
            'status': 'Present',
            'hoursWorked': 8.0,
            'musterQuantity': 1.0,
            'companyId': companyId,
            'createdAt': Timestamp.now(),
            'createdBy': createdBy,
            'payrollPeriodId': null,
            'paymentStatus': 'unpaid',
            'isDeleted': true, // soft deleted
            'dailyWageSnapshot': 500.0,
            'earningsSnapshot': 500.0,
          });

      // Verify reports only see 500.0 from valid attendance and 0.0 from deleted
      final filter = ReportFilter(
        companyId: companyId,
        startDate: periodStart,
        endDate: periodEnd,
      );

      // A. Attendance Summary
      final attSummary = await reportRepo.getAttendanceSummaryReport(filter);
      expect(attSummary.totalEarned, 500.0);
      expect(attSummary.totalAttendanceDays, 1); // Only 1 day

      // B. Worker Ledger (unpaid state)
      final ledgerFilter = ReportFilter(
        companyId: companyId,
        startDate: periodStart,
        endDate: periodEnd,
        labourId: 'worker_a',
      );
      final ledger = await reportRepo.getWorkerLedgerReport(ledgerFilter);
      expect(ledger.totalEarned, 500.0);

      // C. Outstanding Balance
      final outstanding = await reportRepo.getOutstandingBalanceReport(filter);
      expect(outstanding.totalOutstandingBalance, 500.0);
      expect(outstanding.workerEntries.first.totalEarned, 500.0);

      // D. Site Performance
      final sitePerf = await reportRepo.getSitePerformanceReport(filter);
      expect(sitePerf.totalEarned, 500.0);

      // Create period & settle to verify Monthly Payroll Summary exclusion
      final period = await payrollRepo.createPayrollPeriod(
        companyId: companyId,
        name: 'Soft Delete Period',
        startDate: periodStart,
        endDate: periodEnd,
        createdBy: createdBy,
      );
      await payrollRepo.freezePayrollPeriod(companyId: companyId, periodId: period.id, frozenBy: createdBy);
      final calcs = await payrollRepo.calculatePayroll(companyId: companyId, periodId: period.id);
      await payrollRepo.finalizePayroll(
        companyId: companyId,
        periodId: period.id,
        finalizedBy: createdBy,
        results: calcs,
        paymentMode: 'cash',
      );

      // E. Monthly Payroll Summary
      final monthly = await reportRepo.getMonthlyPayrollReport(filter);
      expect(monthly.entries.first.totalEarned, 500.0);
    });
  });
}
