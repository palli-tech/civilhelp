import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civilhelp/features/attendance/repositories/attendance_repository.dart';
import 'package:civilhelp/features/payroll/repositories/payroll_repository.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late AttendanceRepository attendanceRepo;
  const String companyId = 'test_company';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    attendanceRepo = AttendanceRepository(firestore: fakeFirestore);
  });

  group('Legacy Attendance Validation Scan Tests', () {
    test('Detects valid/clean attendance documents correctly', () async {
      // Seed a fully valid attendance document
      await fakeFirestore
          .collection('companies')
          .doc(companyId)
          .collection('attendance')
          .doc('valid_1')
          .set({
        'labourId': 'L1',
        'labourName': 'Worker 1',
        'siteId': 'S1',
        'siteName': 'Site 1',
        'date': Timestamp.fromDate(DateTime(2026, 6, 13)),
        'status': 'Present',
        'hoursWorked': 8.0,
        'musterQuantity': 1.0,
        'companyId': companyId,
        'createdAt': Timestamp.now(),
        'createdBy': 'owner',
        'dailyWageSnapshot': 500.0,
        'earningsSnapshot': 500.0,
        'labourNameSnapshot': 'Worker 1',
        'siteNameSnapshot': 'Site 1',
        'payrollPeriodId': null,
        'paymentStatus': 'unpaid',
        'paymentId': null,
        'isDeleted': false,
      });

      final report = await attendanceRepo.scanLegacyAttendance(companyId: companyId);

      expect(report['totalRecords'], 1);
      expect(report['legacyStatusCount'], 0);
      expect(report['missingPaymentStatus'], 0);
      expect(report['missingPayrollPeriodId'], 0);
      expect(report['missingPaymentId'], 0);
      expect(report['missingIsDeleted'], 0);
      expect(report['recordsMissingRequiredFields'], 0);
      expect(report['corruptDocIds'], isEmpty);
    });

    test('Detects documents with legacy paymentStatus = "open"', () async {
      // Seed a document with paymentStatus = 'open'
      await fakeFirestore
          .collection('companies')
          .doc(companyId)
          .collection('attendance')
          .doc('legacy_status_1')
          .set({
        'labourId': 'L1',
        'labourName': 'Worker 1',
        'siteId': 'S1',
        'siteName': 'Site 1',
        'date': Timestamp.fromDate(DateTime(2026, 6, 13)),
        'status': 'Present',
        'hoursWorked': 8.0,
        'musterQuantity': 1.0,
        'companyId': companyId,
        'createdAt': Timestamp.now(),
        'createdBy': 'owner',
        'dailyWageSnapshot': 500.0,
        'earningsSnapshot': 500.0,
        'labourNameSnapshot': 'Worker 1',
        'siteNameSnapshot': 'Site 1',
        'payrollPeriodId': null,
        'paymentStatus': 'open', // legacy
        'paymentId': null,
        'isDeleted': false,
      });

      final report = await attendanceRepo.scanLegacyAttendance(companyId: companyId);

      expect(report['totalRecords'], 1);
      expect(report['legacyStatusCount'], 1);
      expect(report['recordsMissingRequiredFields'], 1);
      expect(report['corruptDocIds'], contains('legacy_status_1'));
    });

    test('Detects documents missing required fields (payrollPeriodId, paymentId, isDeleted, paymentStatus)', () async {
      // Seed a document missing payrollPeriodId, paymentId, isDeleted, and paymentStatus
      await fakeFirestore
          .collection('companies')
          .doc(companyId)
          .collection('attendance')
          .doc('corrupt_1')
          .set({
        'labourId': 'L1',
        'labourName': 'Worker 1',
        'siteId': 'S1',
        'siteName': 'Site 1',
        'date': Timestamp.fromDate(DateTime(2026, 6, 13)),
        'status': 'Present',
        'hoursWorked': 8.0,
        'musterQuantity': 1.0,
        'companyId': companyId,
        'createdAt': Timestamp.now(),
        'createdBy': 'owner',
        'dailyWageSnapshot': 500.0,
        'earningsSnapshot': 500.0,
        'labourNameSnapshot': 'Worker 1',
        'siteNameSnapshot': 'Site 1',
        // missing fields: payrollPeriodId, paymentStatus, paymentId, isDeleted
      });

      final report = await attendanceRepo.scanLegacyAttendance(companyId: companyId);

      expect(report['totalRecords'], 1);
      expect(report['legacyStatusCount'], 0); // Not 'open', it's missing entirely
      expect(report['missingPaymentStatus'], 1);
      expect(report['missingPayrollPeriodId'], 1);
      expect(report['missingPaymentId'], 1);
      expect(report['missingIsDeleted'], 1);
      expect(report['recordsMissingRequiredFields'], 1);
      expect(report['corruptDocIds'], contains('corrupt_1'));
    });
  });

  group('Orphaned Legacy Payroll Assignment Repair Tests', () {
    late PayrollRepository payrollRepo;

    setUp(() {
      payrollRepo = PayrollRepository(firestore: fakeFirestore);
    });

    test('Test A – Orphaned Assignment Detection', () async {
      // Seed an orphaned attendance
      await fakeFirestore
          .collection('companies')
          .doc(companyId)
          .collection('attendance')
          .doc('orphan_1')
          .set({
        'labourId': 'L1',
        'payrollPeriodId': 'legacy_123', // points to non-existent period
        'paymentStatus': 'unpaid',
        'isDeleted': false,
        'date': Timestamp.fromDate(DateTime(2026, 6, 13)),
      });

      final report = await payrollRepo.scanOrphanedPayrollAssignments(companyId: companyId);

      expect(report.totalAttendance, 1);
      expect(report.orphanedAssignments, 1);
      expect(report.validAssignments, 0);
      expect(report.floatingAssignments, 0);
      expect(report.orphanedDocIds, contains('orphan_1'));
    });

    test('Test B – Repair Utility', () async {
      // Seed orphaned attendance
      final docRef = fakeFirestore
          .collection('companies')
          .doc(companyId)
          .collection('attendance')
          .doc('orphan_1');

      await docRef.set({
        'labourId': 'L1',
        'payrollPeriodId': 'legacy_123',
        'paymentStatus': 'unpaid',
        'isDeleted': false,
        'date': Timestamp.fromDate(DateTime(2026, 6, 13)),
      });

      await payrollRepo.repairOrphanedPayrollAssignments(companyId: companyId);

      final docSnap = await docRef.get();
      expect(docSnap.data()?['payrollPeriodId'], isNull);
    });

    test('Test C – Payroll Creation Recovery', () async {
      // Seed worker and site
      await fakeFirestore.collection('companies').doc(companyId).collection('labour').doc('L1').set({
        'fullName': 'Worker 1',
        'dailyWage': 600.0,
        'status': 'active',
      });
      await fakeFirestore.collection('companies').doc(companyId).collection('sites').doc('S1').set({
        'name': 'Site 1',
      });

      // Seed orphaned attendance covering test date
      final testDate = DateTime(2026, 6, 13);
      final docRef = fakeFirestore
          .collection('companies')
          .doc(companyId)
          .collection('attendance')
          .doc('L1_S1_2026-06-13');

      await docRef.set({
        'labourId': 'L1',
        'labourName': 'Worker 1',
        'siteId': 'S1',
        'siteName': 'Site 1',
        'dailyWageSnapshot': 600.0,
        'earningsSnapshot': 600.0,
        'labourNameSnapshot': 'Worker 1',
        'siteNameSnapshot': 'Site 1',
        'payrollPeriodId': 'legacy_123',
        'paymentStatus': 'unpaid',
        'isDeleted': false,
        'date': Timestamp.fromDate(testDate),
        'musterQuantity': 1.0,
        'hoursWorked': 8.0,
        'companyId': companyId,
        'createdAt': Timestamp.now(),
        'createdBy': 'owner_1',
      });

      // Create period
      final period = await payrollRepo.createPayrollPeriod(
        companyId: companyId,
        name: 'New Period',
        startDate: testDate.subtract(const Duration(days: 1)),
        endDate: testDate.add(const Duration(days: 1)),
        createdBy: 'owner_1',
      );

      expect(period.id, isNotEmpty);

      // Verify attendance reassigned and payroll succeeds
      final docSnap = await docRef.get();
      expect(docSnap.data()?['payrollPeriodId'], period.id);

      final calcs = await payrollRepo.calculatePayroll(companyId: companyId, periodId: period.id);
      expect(calcs.length, 1);
      expect(calcs.first.grossEarnings, 600.0);
    });

    test('Test D – Existing Assignment Protection', () async {
      // Seed a matching valid payroll period document in firestore
      final validPeriodId = 'valid_period';
      await fakeFirestore
          .collection('companies')
          .doc(companyId)
          .collection('payrollPeriods')
          .doc(validPeriodId)
          .set({
        'companyId': companyId,
        'name': 'Valid Period',
        'startDate': Timestamp.fromDate(DateTime(2026, 6, 10)),
        'endDate': Timestamp.fromDate(DateTime(2026, 6, 20)),
        'status': 'open',
        'createdAt': Timestamp.now(),
        'createdBy': 'owner_1',
      });

      // Seed attendance pointing to valid period
      final testDate = DateTime(2026, 6, 13);
      final docRef = fakeFirestore
          .collection('companies')
          .doc(companyId)
          .collection('attendance')
          .doc('assigned_1');

      await docRef.set({
        'labourId': 'L1',
        'payrollPeriodId': validPeriodId,
        'paymentStatus': 'unpaid',
        'isDeleted': false,
        'date': Timestamp.fromDate(testDate),
      });

      // Seed another unpaid attendance record in the second period's range so creation succeeds
      await fakeFirestore
          .collection('companies')
          .doc(companyId)
          .collection('attendance')
          .doc('assigned_2')
          .set({
        'labourId': 'L1',
        'labourName': 'Worker 1',
        'siteId': 'S1',
        'siteName': 'Site 1',
        'dailyWageSnapshot': 600.0,
        'earningsSnapshot': 600.0,
        'payrollPeriodId': null,
        'paymentStatus': 'unpaid',
        'isDeleted': false,
        'date': Timestamp.fromDate(testDate.add(const Duration(days: 12))), // 25 Jun
        'musterQuantity': 1.0,
        'hoursWorked': 8.0,
        'companyId': companyId,
        'createdAt': Timestamp.now(),
        'createdBy': 'owner_1',
      });

      // Create another payroll period
      await payrollRepo.createPayrollPeriod(
        companyId: companyId,
        name: 'Second Period',
        startDate: testDate.add(const Duration(days: 10)),
        endDate: testDate.add(const Duration(days: 20)),
        createdBy: 'owner_1',
      );

      // Verify attendance remains assigned to valid_period
      final docSnap = await docRef.get();
      expect(docSnap.data()?['payrollPeriodId'], validPeriodId);
    });

    test('Test E – Mixed Dataset', () async {
      // Seed a valid period that does not overlap with the new period (01 Jun to 05 Jun)
      final validPeriodId = 'valid_period';
      await fakeFirestore
          .collection('companies')
          .doc(companyId)
          .collection('payrollPeriods')
          .doc(validPeriodId)
          .set({
        'companyId': companyId,
        'name': 'Valid Period',
        'startDate': Timestamp.fromDate(DateTime(2026, 6, 1)),
        'endDate': Timestamp.fromDate(DateTime(2026, 6, 5)),
        'status': 'open',
        'createdAt': Timestamp.now(),
        'createdBy': 'owner_1',
      });

      // Seed worker and site details
      await fakeFirestore.collection('companies').doc(companyId).collection('labour').doc('L1').set({
        'fullName': 'Worker 1',
        'dailyWage': 600.0,
        'status': 'active',
      });
      await fakeFirestore.collection('companies').doc(companyId).collection('sites').doc('S1').set({
        'name': 'Site 1',
      });

      final testDate = DateTime(2026, 6, 13);

      // Attendance A: orphaned
      final docARef = fakeFirestore
          .collection('companies')
          .doc(companyId)
          .collection('attendance')
          .doc('A');
      await docARef.set({
        'labourId': 'L1',
        'labourName': 'Worker 1',
        'siteId': 'S1',
        'siteName': 'Site 1',
        'dailyWageSnapshot': 600.0,
        'earningsSnapshot': 600.0,
        'payrollPeriodId': 'orphaned_period',
        'paymentStatus': 'unpaid',
        'isDeleted': false,
        'date': Timestamp.fromDate(testDate),
        'musterQuantity': 1.0,
        'hoursWorked': 8.0,
        'companyId': companyId,
        'createdAt': Timestamp.now(),
        'createdBy': 'owner_1',
      });

      // Attendance B: valid period
      final docBRef = fakeFirestore
          .collection('companies')
          .doc(companyId)
          .collection('attendance')
          .doc('B');
      await docBRef.set({
        'labourId': 'L1',
        'payrollPeriodId': validPeriodId,
        'paymentStatus': 'unpaid',
        'isDeleted': false,
        'date': Timestamp.fromDate(testDate),
      });

      // Attendance C: null
      final docCRef = fakeFirestore
          .collection('companies')
          .doc(companyId)
          .collection('attendance')
          .doc('C');
      await docCRef.set({
        'labourId': 'L1',
        'labourName': 'Worker 1',
        'siteId': 'S1',
        'siteName': 'Site 1',
        'dailyWageSnapshot': 600.0,
        'earningsSnapshot': 600.0,
        'payrollPeriodId': null,
        'paymentStatus': 'unpaid',
        'isDeleted': false,
        'date': Timestamp.fromDate(testDate),
        'musterQuantity': 1.0,
        'hoursWorked': 8.0,
        'companyId': companyId,
        'createdAt': Timestamp.now(),
        'createdBy': 'owner_1',
      });

      // Create new payroll period (12 Jun to 14 Jun)
      final newPeriod = await payrollRepo.createPayrollPeriod(
        companyId: companyId,
        name: 'New Period',
        startDate: testDate.subtract(const Duration(days: 1)),
        endDate: testDate.add(const Duration(days: 1)),
        createdBy: 'owner_1',
      );

      // Assert: A and C reassigned, B untouched
      final snapA = await docARef.get();
      final snapB = await docBRef.get();
      final snapC = await docCRef.get();

      expect(snapA.data()?['payrollPeriodId'], newPeriod.id);
      expect(snapC.data()?['payrollPeriodId'], newPeriod.id);
      expect(snapB.data()?['payrollPeriodId'], validPeriodId);
    });
  });
}
