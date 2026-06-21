import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civilhelp/features/payroll/repositories/payroll_repository.dart';
import 'package:civilhelp/features/attendance/repositories/attendance_repository.dart';
import 'package:civilhelp/features/advances/repositories/advance_repository.dart';
import 'package:civilhelp/features/payroll/models/payroll_period_model.dart';
import 'package:civilhelp/features/payroll/models/payroll_register_model.dart';
import 'package:civilhelp/features/payroll/models/payroll_summary_model.dart';
import 'package:civilhelp/features/advances/models/advance_model.dart';
import 'package:civilhelp/features/advances/models/advance_recovery_model.dart';
import 'package:civilhelp/features/payments/models/payment_model.dart';
import 'package:civilhelp/features/attendance/models/attendance_model.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late PayrollRepository payrollRepo;
  late AttendanceRepository attendanceRepo;
  late AdvanceRepository advanceRepo;

  const String companyId = 'comp_abc';
  const String createdBy = 'user_owner';

  // Use a dynamic past date to bypass backdate limits and future date blocks
  final DateTime testDate = DateTime.now().subtract(const Duration(days: 20));
  // Period that covers testDate: 5 days back to 5 days forward relative to testDate
  final DateTime periodStart = testDate.subtract(const Duration(days: 5));
  final DateTime periodEnd = testDate.add(const Duration(days: 5));

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    payrollRepo = PayrollRepository(firestore: firestore);
    attendanceRepo = AttendanceRepository(firestore: firestore);
    advanceRepo = AdvanceRepository(firestore: firestore);
    await firestore.collection('companies').doc(companyId).set({
      'attendanceBackdateLimitDays': 90,
    });
  });

  Future<void> seedUnpaidAttendance(DateTime date, {double wage = 500.0, String labourId = 'labour_1'}) async {
    await firestore.collection('companies').doc(companyId).collection('labour').doc(labourId).set({
      'fullName': 'Worker 1',
      'status': 'active',
      'dailyWage': wage,
    });
    await firestore.collection('companies').doc(companyId).collection('sites').doc('site_1').set({
      'name': 'Site 1',
    });
    await attendanceRepo.createAttendance(
      labourId: labourId,
      labourName: 'Worker 1',
      siteId: 'site_1',
      siteName: 'Site 1',
      date: date,
      status: 'Present',
      hoursWorked: 8.0,
      musterQuantity: 1.0,
      companyId: companyId,
      createdBy: createdBy,
    );
  }

  group('Phase 20: Payroll, Advances & Settlement Engine Tests', () {
    test('1. Payroll period lifecycle and transition constraints', () async {
      // Seed attendance first to pass zero gross validation
      await seedUnpaidAttendance(testDate);

      final period = await payrollRepo.createPayrollPeriod(
        companyId: companyId,
        name: 'Test Period 1',
        startDate: periodStart,
        endDate: periodEnd,
        createdBy: createdBy,
      );

      expect(period.status, 'open');

      // open -> frozen
      await payrollRepo.freezePayrollPeriod(companyId: companyId, periodId: period.id, frozenBy: createdBy);
      var updated = await firestore
          .collection('companies')
          .doc(companyId)
          .collection('payrollPeriods')
          .doc(period.id)
          .get()
          .then((d) => PayrollPeriodModel.fromFirestore(d));
      expect(updated.status, 'frozen');

      // frozen -> open
      await payrollRepo.reopenPayrollPeriod(companyId: companyId, periodId: period.id, reopenedBy: createdBy);
      updated = await firestore
          .collection('companies')
          .doc(companyId)
          .collection('payrollPeriods')
          .doc(period.id)
          .get()
          .then((d) => PayrollPeriodModel.fromFirestore(d));
      expect(updated.status, 'open');

      // open -> frozen -> paid (via finalizePayroll)
      await payrollRepo.freezePayrollPeriod(companyId: companyId, periodId: period.id, frozenBy: createdBy);
      
      // Calculate payroll for period to pass to finalize
      final calcs = await payrollRepo.calculatePayroll(companyId: companyId, periodId: period.id);

      // Finalize payroll
      await payrollRepo.finalizePayroll(
        companyId: companyId,
        periodId: period.id,
        finalizedBy: createdBy,
        results: calcs,
        paymentMode: 'cash',
      );

      updated = await firestore
          .collection('companies')
          .doc(companyId)
          .collection('payrollPeriods')
          .doc(period.id)
          .get()
          .then((d) => PayrollPeriodModel.fromFirestore(d));
      expect(updated.status, 'paid');

      // paid -> open (should fail)
      expect(
        () => payrollRepo.reopenPayrollPeriod(companyId: companyId, periodId: period.id, reopenedBy: createdBy),
        throwsA(isA<InvalidPayrollPeriodStatusException>()),
      );

      // paid -> frozen (should fail)
      expect(
        () => payrollRepo.freezePayrollPeriod(companyId: companyId, periodId: period.id, frozenBy: createdBy),
        throwsA(isA<InvalidPayrollPeriodStatusException>()),
      );
    });

    test('2. Attendance locking logic based on resolved period status', () async {
      await firestore.collection('companies').doc(companyId).collection('labour').doc('labour_1').set({
        'fullName': 'Worker 1',
        'status': 'active',
        'dailyWage': 500.0,
      });
      await firestore.collection('companies').doc(companyId).collection('sites').doc('site_1').set({
        'name': 'Site 1',
      });

      // Scenario A: Period does not exist -> allowed
      final att = await attendanceRepo.createAttendance(
        labourId: 'labour_1',
        labourName: 'Worker 1',
        siteId: 'site_1',
        siteName: 'Site 1',
        date: testDate,
        status: 'Present',
        hoursWorked: 8.0,
        musterQuantity: 1.0,
        companyId: companyId,
        createdBy: createdBy,
      );
      expect(att.id, isNotEmpty);

      // Create and freeze the period (it has gross > 0 because of att created above)
      final period = await payrollRepo.createPayrollPeriod(
        companyId: companyId,
        name: 'Test Period',
        startDate: periodStart,
        endDate: periodEnd,
        createdBy: createdBy,
      );
      await payrollRepo.freezePayrollPeriod(companyId: companyId, periodId: period.id, frozenBy: createdBy);

      // Scenario B: Period exists and is frozen -> reject create
      expect(
        () => attendanceRepo.createAttendance(
          labourId: 'labour_1',
          labourName: 'Worker 1',
          siteId: 'site_1',
          siteName: 'Site 1',
          date: testDate,
          status: 'Present',
          hoursWorked: 8.0,
          musterQuantity: 1.0,
          companyId: companyId,
          createdBy: createdBy,
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('is frozen'))),
      );

      // Scenario C: Period exists and is frozen -> reject update/delete
      expect(
        () => attendanceRepo.updateAttendance(
          attendance: att.copyWith(hoursWorked: 4.0),
          updatedBy: createdBy,
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('is frozen'))),
      );

      expect(
        () => attendanceRepo.deleteAttendance(
          attendanceId: att.id,
          companyId: companyId,
          deletedBy: createdBy,
          deleteReason: 'Cancel log',
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('is frozen'))),
      );
    });

    test('3. Payroll Calculation & Wage Snapshot Immutability', () async {
      await firestore.collection('companies').doc(companyId).collection('labour').doc('labour_1').set({
        'fullName': 'Worker 1',
        'status': 'active',
        'dailyWage': 400.0,
      });
      await firestore.collection('companies').doc(companyId).collection('sites').doc('site_1').set({
        'name': 'Site 1',
      });

      // Log attendance
      final att = await attendanceRepo.createAttendance(
        labourId: 'labour_1',
        labourName: 'Worker 1',
        siteId: 'site_1',
        siteName: 'Site 1',
        date: testDate,
        status: 'Present',
        hoursWorked: 8.0,
        musterQuantity: 1.5, // 1.5 muster value
        companyId: companyId,
        createdBy: createdBy,
      );

      expect(att.dailyWageSnapshot, 400.0);
      expect(att.earningsSnapshot, 600.0);

      // Change worker wage rate in profile
      await firestore.collection('companies').doc(companyId).collection('labour').doc('labour_1').update({
        'dailyWage': 800.0,
      });

      // Calculate payroll for a period that covers testDate.
      // Attendance floated (no period existed at write time), so payrollPeriodId is null.
      // Create an open period; this must trigger the backfill process and stamp the ID.
      final testPeriod = await payrollRepo.createPayrollPeriod(
        companyId: companyId,
        name: 'Calc Test Period',
        startDate: periodStart,
        endDate: periodEnd,
        createdBy: createdBy,
      );
      final periodId = testPeriod.id;

      // Verify that the floating attendance is now backfilled and stamped.
      final updatedAtt = await firestore
          .collection('companies')
          .doc(companyId)
          .collection('attendance')
          .doc(att.id)
          .get()
          .then((d) => AttendanceModel.fromFirestore(d));
      expect(updatedAtt.payrollPeriodId, periodId);

      // Verify wage snapshot immutability directly on the attendance record is preserved.
      expect(updatedAtt.earningsSnapshot, 600.0); // unchanged even though profile wage changed to 800
      expect(updatedAtt.dailyWageSnapshot, 400.0); // snapshot was taken at write time

      // Verify calculatePayroll successfully includes the backfilled attendance
      final calcs = await payrollRepo.calculatePayroll(companyId: companyId, periodId: periodId);
      expect(calcs.length, 1);
      expect(calcs.first.grossEarnings, 600.0);
    });

    test('4. Advance Recovery logic & Settlement Engine correctness', () async {
      await firestore.collection('companies').doc(companyId).collection('labour').doc('labour_1').set({
        'fullName': 'Worker 1',
        'status': 'active',
        'dailyWage': 600.0,
      });
      await firestore.collection('companies').doc(companyId).collection('sites').doc('site_1').set({
        'name': 'Site 1',
      });

      // Issue outstanding advance
      final adv = await advanceRepo.createAdvance(
        labourId: 'labour_1',
        labourName: 'Worker 1',
        amount: 1000.0,
        description: 'Festival Advance',
        date: testDate,
        companyId: companyId,
        createdBy: createdBy,
      );

      expect(adv.remainingAmount, 1000.0);
      expect(adv.status, 'pending');

      // Log attendance giving Gross = 600.0 BEFORE creating the period
      // to avoid ZeroGrossPayrollException
      await attendanceRepo.createAttendance(
        labourId: 'labour_1',
        labourName: 'Worker 1',
        siteId: 'site_1',
        siteName: 'Site 1',
        date: testDate,
        status: 'Present',
        hoursWorked: 8.0,
        musterQuantity: 1.0,
        companyId: companyId,
        createdBy: createdBy,
      );

      // Create period
      final period = await payrollRepo.createPayrollPeriod(
        companyId: companyId,
        name: 'Settlement Test Period',
        startDate: periodStart,
        endDate: periodEnd,
        createdBy: createdBy,
      );

      await payrollRepo.freezePayrollPeriod(companyId: companyId, periodId: period.id, frozenBy: createdBy);

      final periodId = period.id;
      final calcs = await payrollRepo.calculatePayroll(companyId: companyId, periodId: periodId);

      expect(calcs.length, 1);
      final c = calcs.first;
      expect(c.grossEarnings, 600.0);
      expect(c.advanceDeductions, 600.0); // capped at Gross
      expect(c.netPayable, 0.0); // Deduction == Gross

      // Finalize Settlement
      await payrollRepo.finalizePayroll(
        companyId: companyId,
        periodId: periodId,
        finalizedBy: createdBy,
        results: calcs,
        paymentMode: 'upi',
      );

      // Verify advance recovered partially
      final updatedAdv = await firestore
          .collection('companies')
          .doc(companyId)
          .collection('advances')
          .doc(adv.id)
          .get()
          .then((d) => AdvanceModel.fromFirestore(d));
      
      expect(updatedAdv.recoveredAmount, 600.0);
      expect(updatedAdv.remainingAmount, 400.0);
      expect(updatedAdv.status, 'partial');

      // Verify Advance Recovery ledger entry created
      final recoveries = await firestore
          .collection('companies')
          .doc(companyId)
          .collection('advanceRecoveries')
          .get();
      expect(recoveries.docs.length, 1);
      final rec = AdvanceRecoveryModel.fromFirestore(recoveries.docs.first);
      expect(rec.advanceId, adv.id);
      expect(rec.recoveredAmount, 600.0);

      // Verify payment doc created
      final payments = await firestore
          .collection('companies')
          .doc(companyId)
          .collection('payments')
          .get();
      expect(payments.docs.length, 1);
      final pay = PaymentModel.fromFirestore(payments.docs.first);
      expect(pay.grossEarningsSnapshot, 600.0);
      expect(pay.deductionsSnapshot, 600.0);
      expect(pay.amount, 0.0);
      expect(pay.paymentMode, 'upi');

      // Verify register doc created
      final registers = await firestore
          .collection('companies')
          .doc(companyId)
          .collection('payrollRegisters')
          .get();
      expect(registers.docs.length, 1);
      final reg = PayrollRegisterModel.fromFirestore(registers.docs.first);
      expect(reg.grossEarnings, 600.0);
      expect(reg.advanceDeductions, 600.0);
      expect(reg.netPayable, 0.0);

      // Verify summary doc created
      final summaries = await firestore
          .collection('companies')
          .doc(companyId)
          .collection('payrollSummaries')
          .get();
      expect(summaries.docs.length, 1);
      final sum = PayrollSummaryModel.fromFirestore(summaries.docs.first);
      expect(sum.totalWorkers, 1);
      expect(sum.totalGross, 600.0);
      expect(sum.totalDeductions, 600.0);
      expect(sum.totalNetPaid, 0.0);

      // Verify attendance stamped as paid
      final atts = await firestore
          .collection('companies')
          .doc(companyId)
          .collection('attendance')
          .get();
      final stampedAtt = AttendanceModel.fromFirestore(atts.docs.first);
      expect(stampedAtt.paymentStatus, 'paid');
      expect(stampedAtt.paymentId, pay.id);
    });

    test('5. Existing Assignment Not Overwritten', () async {
      // Seed period_old document so it is recognized as a valid existing period
      await firestore
          .collection('companies')
          .doc(companyId)
          .collection('payrollPeriods')
          .doc('period_old')
          .set({
        'id': 'period_old',
        'companyId': companyId,
        'name': 'Old Period',
        'startDate': Timestamp.fromDate(testDate.subtract(const Duration(days: 15))),
        'endDate': Timestamp.fromDate(testDate.subtract(const Duration(days: 10))),
        'status': 'open',
        'createdAt': Timestamp.now(),
        'createdBy': createdBy,
        'settlementJobStatus': 'pending',
      });

      await firestore.collection('companies').doc(companyId).collection('labour').doc('labour_1').set({
        'fullName': 'Worker 1',
        'status': 'active',
        'dailyWage': 500.0,
      });
      await firestore.collection('companies').doc(companyId).collection('sites').doc('site_1').set({
        'name': 'Site 1',
      });

      // Attendance 1: already assigned to 'period_old'
      final att1 = await attendanceRepo.createAttendance(
        labourId: 'labour_1',
        labourName: 'Worker 1',
        siteId: 'site_1',
        siteName: 'Site 1',
        date: testDate,
        status: 'Present',
        hoursWorked: 8.0,
        musterQuantity: 1.0,
        companyId: companyId,
        createdBy: createdBy,
      );
      await firestore
          .collection('companies')
          .doc(companyId)
          .collection('attendance')
          .doc(att1.id)
          .update({'payrollPeriodId': 'period_old'});

      // Attendance 2: floating (payrollPeriodId = null)
      final att2 = await firestore
          .collection('companies')
          .doc(companyId)
          .collection('attendance')
          .add({
            'labourId': 'labour_1',
            'labourName': 'Worker 1',
            'siteId': 'site_1',
            'siteName': 'Site 1',
            'date': Timestamp.fromDate(testDate),
            'status': 'Present',
            'hoursWorked': 8.0,
            'musterQuantity': 1.0,
            'companyId': companyId,
            'createdAt': Timestamp.now(),
            'createdBy': createdBy,
            'payrollPeriodId': null,
            'paymentStatus': 'unpaid',
            'isDeleted': false,
            'dailyWageSnapshot': 500.0,
            'earningsSnapshot': 500.0,
          });

      // Create period
      final period = await payrollRepo.createPayrollPeriod(
        companyId: companyId,
        name: 'New Period',
        startDate: periodStart,
        endDate: periodEnd,
        createdBy: createdBy,
      );

      // Verify att1 still has 'period_old'
      final updatedAtt1 = await firestore
          .collection('companies')
          .doc(companyId)
          .collection('attendance')
          .doc(att1.id)
          .get()
          .then((d) => AttendanceModel.fromFirestore(d));
      expect(updatedAtt1.payrollPeriodId, 'period_old');

      // Verify att2 was backfilled
      final updatedAtt2 = await firestore
          .collection('companies')
          .doc(companyId)
          .collection('attendance')
          .doc(att2.id)
          .get()
          .then((d) => AttendanceModel.fromFirestore(d));
      expect(updatedAtt2.payrollPeriodId, period.id);
    });

    test('6. Soft Deleted Attendance Ignored', () async {
      await firestore.collection('companies').doc(companyId).collection('labour').doc('labour_1').set({
        'fullName': 'Worker 1',
        'status': 'active',
        'dailyWage': 500.0,
      });
      await firestore.collection('companies').doc(companyId).collection('sites').doc('site_1').set({
        'name': 'Site 1',
      });

      // Create a soft-deleted attendance record with payrollPeriodId = null
      final attDoc = await firestore
          .collection('companies')
          .doc(companyId)
          .collection('attendance')
          .add({
            'labourId': 'labour_1',
            'labourName': 'Worker 1',
            'siteId': 'site_1',
            'siteName': 'Site 1',
            'date': Timestamp.fromDate(testDate),
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

      // Seed another active unpaid attendance record so the period has > 0 gross and succeeds creation
      await seedUnpaidAttendance(testDate, labourId: 'labour_valid');

      // Create period
      await payrollRepo.createPayrollPeriod(
        companyId: companyId,
        name: 'Soft Delete Test Period',
        startDate: periodStart,
        endDate: periodEnd,
        createdBy: createdBy,
      );

      // Verify soft deleted document still has null payrollPeriodId
      final updatedAtt = await firestore
          .collection('companies')
          .doc(companyId)
          .collection('attendance')
          .doc(attDoc.id)
          .get();
      expect(updatedAtt.data()?['payrollPeriodId'], isNull);
    });

    test('7. Security Lifecycle of backfilled attendance', () async {
      await firestore.collection('companies').doc(companyId).collection('labour').doc('labour_1').set({
        'fullName': 'Worker 1',
        'status': 'active',
        'dailyWage': 500.0,
      });
      await firestore.collection('companies').doc(companyId).collection('sites').doc('site_1').set({
        'name': 'Site 1',
      });

      // Create a floating attendance record
      final att = await attendanceRepo.createAttendance(
        labourId: 'labour_1',
        labourName: 'Worker 1',
        siteId: 'site_1',
        siteName: 'Site 1',
        date: testDate,
        status: 'Present',
        hoursWorked: 8.0,
        musterQuantity: 1.0,
        companyId: companyId,
        createdBy: createdBy,
      );
      expect(att.payrollPeriodId, isNull);

      // Create the payroll period (stamping it)
      final period = await payrollRepo.createPayrollPeriod(
        companyId: companyId,
        name: 'Security Test Period',
        startDate: periodStart,
        endDate: periodEnd,
        createdBy: createdBy,
      );

      // Verify it was backfilled
      final backfilledAtt = await firestore
          .collection('companies')
          .doc(companyId)
          .collection('attendance')
          .doc(att.id)
          .get()
          .then((d) => AttendanceModel.fromFirestore(d));
      expect(backfilledAtt.payrollPeriodId, period.id);

      // Freeze the period
      await payrollRepo.freezePayrollPeriod(
        companyId: companyId,
        periodId: period.id,
        frozenBy: createdBy,
      );

      // Attempt update (should throw lock error)
      expect(
        () => attendanceRepo.updateAttendance(
          attendance: backfilledAtt.copyWith(hoursWorked: 4.0),
          updatedBy: createdBy,
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('is frozen'))),
      );

      // Attempt delete (should throw lock error)
      expect(
        () => attendanceRepo.deleteAttendance(
          attendanceId: att.id,
          companyId: companyId,
          deletedBy: createdBy,
          deleteReason: 'Cancelled',
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('is frozen'))),
      );
    });

    test('8. Overlapping and Zero-Gross validation checks', () async {
      // Setup attendance
      await seedUnpaidAttendance(testDate, labourId: 'labour_valid_1');

      // Create first period
      final period1 = await payrollRepo.createPayrollPeriod(
        companyId: companyId,
        name: 'Period 1',
        startDate: testDate.subtract(const Duration(days: 2)),
        endDate: testDate.add(const Duration(days: 2)),
        createdBy: createdBy,
      );
      expect(period1.id, isNotEmpty);

      // Attempt to create overlapping period (should fail with PayrollOverlapException)
      expect(
        () => payrollRepo.createPayrollPeriod(
          companyId: companyId,
          name: 'Period Overlap',
          startDate: testDate.subtract(const Duration(days: 1)),
          endDate: testDate.add(const Duration(days: 3)),
          createdBy: createdBy,
        ),
        throwsA(isA<PayrollOverlapException>()),
      );

      // Attempt to create a period with zero gross (no unpaid attendance exists in range)
      // Since testDate is already claimed by period1, the range testDate+5 to testDate+10 has zero gross
      try {
        await payrollRepo.createPayrollPeriod(
          companyId: companyId,
          name: 'Period Zero Gross',
          startDate: testDate.add(const Duration(days: 5)),
          endDate: testDate.add(const Duration(days: 10)),
          createdBy: createdBy,
        );
        fail('Should have thrown ZeroGrossPayrollException');
      } on ZeroGrossPayrollException {
        // Expected exception
      }
      
      // Multiple open periods are allowed if they do not overlap
      // Seed another attendance for a non-overlapping range
      final futureDate = testDate.add(const Duration(days: 10));
      await seedUnpaidAttendance(futureDate, labourId: 'labour_valid_2');

      final period2 = await payrollRepo.createPayrollPeriod(
        companyId: companyId,
        name: 'Period 2',
        startDate: testDate.add(const Duration(days: 8)),
        endDate: testDate.add(const Duration(days: 12)),
        createdBy: createdBy,
      );
      expect(period2.id, isNotEmpty);
    });
  });
}
