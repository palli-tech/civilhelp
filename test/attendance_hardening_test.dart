import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:civilhelp/features/attendance/repositories/attendance_repository.dart';
import 'package:civilhelp/features/attendance/models/attendance_model.dart';
import 'package:civilhelp/features/attendance/providers/attendance_provider.dart';
import 'package:civilhelp/features/labour/data/repositories/labour_repository_impl.dart';
import 'package:civilhelp/features/payroll/repositories/payroll_repository.dart';
import 'package:civilhelp/core/providers/company_provider.dart';
import 'package:civilhelp/core/providers/user_role_provider.dart';
import 'package:civilhelp/core/enums/user_role.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late AttendanceRepository attendanceRepo;
  late LabourRepository labourRepo;

  const String companyId = 'test_company';
  const String supervisorUid = 'supervisor_1';
  const String ownerUid = 'owner_1';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    attendanceRepo = AttendanceRepository(firestore: fakeFirestore);
    labourRepo = LabourRepository(firestore: fakeFirestore);
  });

  group('Phase 19: Workforce Operations Hardening Tests', () {
    
    test('1. Attendance ID Generation schema: labourId_siteId_dateString', () {
      final date = DateTime(2026, 6, 13);
      final generatedId = attendanceRepo.generateAttendanceDocId(
        labourId: 'L123',
        siteId: 'S456',
        date: date,
      );
      
      expect(generatedId, 'L123_S456_2026-06-13');
    });

    test('2. Wage snapshot correctness & immutability at creation', () async {
      // Setup company, site, and labour in firestore
      await fakeFirestore.collection('companies').doc(companyId).set({
        'name': 'Test Company',
        'attendanceBackdateLimitDays': 3,
      });

      await fakeFirestore.collection('companies').doc(companyId).collection('sites').doc('site_1').set({
        'name': 'Initial Site Name',
      });

      await fakeFirestore.collection('companies').doc(companyId).collection('labour').doc('labour_1').set({
        'fullName': 'Initial Worker Name',
        'dailyWage': 600.0,
      });

      // Log attendance
      final attendance = await attendanceRepo.createAttendance(
        labourId: 'labour_1',
        labourName: 'Initial Worker Name',
        siteId: 'site_1',
        siteName: 'Initial Site Name',
        date: DateTime.now(),
        status: 'Present',
        hoursWorked: 8.0,
        musterQuantity: 1.0,
        companyId: companyId,
        createdBy: supervisorUid,
      );

      // Verify snapshots captured correctly
      expect(attendance.dailyWageSnapshot, 600.0);
      expect(attendance.earningsSnapshot, 600.0);
      expect(attendance.labourNameSnapshot, 'Initial Worker Name');
      expect(attendance.siteNameSnapshot, 'Initial Site Name');

      // Update labour dailyWage and siteName in database
      await fakeFirestore.collection('companies').doc(companyId).collection('labour').doc('labour_1').update({
        'dailyWage': 800.0,
        'fullName': 'Updated Worker Name',
      });

      await fakeFirestore.collection('companies').doc(companyId).collection('sites').doc('site_1').update({
        'name': 'Updated Site Name',
      });

      // Retrieve attendance again to check snapshot immutability
      final fetchedDocs = await fakeFirestore
          .collection('companies')
          .doc(companyId)
          .collection('attendance')
          .get();
      
      final fetchedAttendance = AttendanceModel.fromFirestore(fetchedDocs.docs.first);

      // Snapshots must remain unchanged (immutable)
      expect(fetchedAttendance.dailyWageSnapshot, 600.0);
      expect(fetchedAttendance.earningsSnapshot, 600.0);
      expect(fetchedAttendance.labourNameSnapshot, 'Initial Worker Name');
      expect(fetchedAttendance.siteNameSnapshot, 'Initial Site Name');
    });

    test('3. Paid & Frozen record locking (cannot edit or delete)', () async {
      await fakeFirestore.collection('companies').doc(companyId).set({
        'attendanceBackdateLimitDays': 3,
      });

      await fakeFirestore.collection('companies').doc(companyId).collection('sites').doc('site_1').set({
        'name': 'Site 1',
      });

      await fakeFirestore.collection('companies').doc(companyId).collection('labour').doc('labour_1').set({
        'fullName': 'Worker 1',
        'dailyWage': 500.0,
      });

      // Create attendance
      final attendance = await attendanceRepo.createAttendance(
        labourId: 'labour_1',
        labourName: 'Worker 1',
        siteId: 'site_1',
        siteName: 'Site 1',
        date: DateTime.now(),
        status: 'Present',
        hoursWorked: 8.0,
        musterQuantity: 1.0,
        companyId: companyId,
        createdBy: supervisorUid,
      );

      // Lock it (set to frozen) in database
      final docRef = fakeFirestore
          .collection('companies')
          .doc(companyId)
          .collection('attendance')
          .doc(attendance.id);
          
      await docRef.update({'paymentStatus': 'frozen'});

      // Create a payroll period that covers today and freeze it
      // (using the new arbitrary date-range API)
      final payrollRepo = PayrollRepository(firestore: fakeFirestore);
      final today = DateTime.now();

      // Seed dummy unpaid attendance to satisfy zero gross check
      await fakeFirestore.collection('companies').doc(companyId).collection('labour').doc('labour_dummy').set({
        'fullName': 'Dummy Worker',
        'status': 'active',
        'dailyWage': 500.0,
      });
      await attendanceRepo.createAttendance(
        labourId: 'labour_dummy',
        labourName: 'Dummy Worker',
        siteId: 'site_1',
        siteName: 'Site 1',
        date: today,
        status: 'Present',
        hoursWorked: 8.0,
        musterQuantity: 1.0,
        companyId: companyId,
        createdBy: ownerUid,
      );

      final period = await payrollRepo.createPayrollPeriod(
        companyId: companyId,
        name: 'Test Period',
        startDate: today.subtract(const Duration(days: 7)),
        endDate: today.add(const Duration(days: 7)),
        createdBy: ownerUid,
      );
      await fakeFirestore
          .collection('companies')
          .doc(companyId)
          .collection('payrollPeriods')
          .doc(period.id)
          .update({'status': 'frozen'});

      final frozenAttendance = attendance.copyWith(paymentStatus: 'frozen');

      // Attempt edit (should throw)
      expect(
        () => attendanceRepo.updateAttendance(attendance: frozenAttendance.copyWith(hoursWorked: 6.0), updatedBy: ownerUid),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Cannot modify attendance'))),
      );

      // Attempt delete (should throw)
      expect(
        () => attendanceRepo.deleteAttendance(
          attendanceId: frozenAttendance.id,
          companyId: companyId,
          deletedBy: ownerUid,
          deleteReason: 'mistake',
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Cannot delete attendance'))),
      );

      // Now set to paid
      await docRef.update({'paymentStatus': 'paid'});
      await fakeFirestore
          .collection('companies')
          .doc(companyId)
          .collection('payrollPeriods')
          .doc(period.id)
          .update({'status': 'paid'});
      final paidAttendance = attendance.copyWith(paymentStatus: 'paid');

      // Attempt edit (should throw)
      expect(
        () => attendanceRepo.updateAttendance(attendance: paidAttendance.copyWith(hoursWorked: 4.0), updatedBy: ownerUid),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Cannot modify attendance'))),
      );

      // Attempt delete (should throw)
      expect(
        () => attendanceRepo.deleteAttendance(
          attendanceId: paidAttendance.id,
          companyId: companyId,
          deletedBy: ownerUid,
          deleteReason: 'already paid',
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Cannot delete attendance'))),
      );
    });

    test('4. Configurable Backdate Limits', () async {
      // Set limit to 5 days
      await fakeFirestore.collection('companies').doc(companyId).set({
        'attendanceBackdateLimitDays': 5,
      });

      await fakeFirestore.collection('companies').doc(companyId).collection('sites').doc('site_1').set({
        'name': 'Site 1',
      });

      await fakeFirestore.collection('companies').doc(companyId).collection('labour').doc('labour_1').set({
        'fullName': 'Worker 1',
        'dailyWage': 500.0,
      });

      final today = DateTime.now();

      // Within limit: 4 days back
      final validDate = today.subtract(const Duration(days: 4));
      final att1 = await attendanceRepo.createAttendance(
        labourId: 'labour_1',
        labourName: 'Worker 1',
        siteId: 'site_1',
        siteName: 'Site 1',
        date: validDate,
        status: 'Present',
        hoursWorked: 8.0,
        musterQuantity: 1.0,
        companyId: companyId,
        createdBy: ownerUid,
      );
      expect(att1.id, isNotEmpty);

      // Exceeds limit: 6 days back (should throw)
      final invalidDate = today.subtract(const Duration(days: 6));
      expect(
        () => attendanceRepo.createAttendance(
          labourId: 'labour_1',
          labourName: 'Worker 1',
          siteId: 'site_1',
          siteName: 'Site 1',
          date: invalidDate,
          status: 'Present',
          hoursWorked: 8.0,
          musterQuantity: 1.0,
          companyId: companyId,
          createdBy: ownerUid,
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('exceeds the company backdate limit'))),
      );
    });

    test('5. Soft delete behavior (isDeleted, deletedBy, deletedAt, deleteReason)', () async {
      await fakeFirestore.collection('companies').doc(companyId).set({
        'attendanceBackdateLimitDays': 3,
      });

      await fakeFirestore.collection('companies').doc(companyId).collection('sites').doc('site_1').set({
        'name': 'Site 1',
      });

      await fakeFirestore.collection('companies').doc(companyId).collection('labour').doc('labour_1').set({
        'fullName': 'Worker 1',
        'dailyWage': 500.0,
      });

      final attendance = await attendanceRepo.createAttendance(
        labourId: 'labour_1',
        labourName: 'Worker 1',
        siteId: 'site_1',
        siteName: 'Site 1',
        date: DateTime.now(),
        status: 'Present',
        hoursWorked: 8.0,
        musterQuantity: 1.0,
        companyId: companyId,
        createdBy: supervisorUid,
      );

      // Perform soft delete
      await attendanceRepo.deleteAttendance(
        attendanceId: attendance.id,
        companyId: companyId,
        deletedBy: ownerUid,
        deleteReason: 'Duplicate entry log',
      );

      // Verify fields in Firestore
      final snap = await fakeFirestore
          .collection('companies')
          .doc(companyId)
          .collection('attendance')
          .doc(attendance.id)
          .get();

      final data = snap.data()!;
      expect(data['isDeleted'], true);
      expect(data['deletedBy'], ownerUid);
      expect(data['deletedAt'], isNotNull);
      expect(data['deleteReason'], 'Duplicate entry log');

      // Verify that queries ignore soft deleted records
      final activeList = await attendanceRepo.getAttendanceByCompanyStream(companyId).first;
      expect(activeList.any((a) => a.id == attendance.id), isFalse);
    });

    test('6. Labour deactivation transaction limits (unpaid attendance/advances)', () async {
      await fakeFirestore.collection('companies').doc(companyId).set({
        'attendanceBackdateLimitDays': 3,
      });

      await fakeFirestore.collection('companies').doc(companyId).collection('sites').doc('site_1').set({
        'name': 'Site 1',
      });

      // Create labour worker
      final labour = await labourRepo.createLabour(
        fullName: 'Labour Worker',
        phoneNumber: '9876543210',
        aadhaarNumber: '123456789012',
        dailyWage: 500.0,
        assignedSiteId: 'site_1',
        assignedSiteName: 'Site 1',
        joinedDate: DateTime.now(),
        status: 'active',
        companyId: companyId,
        createdBy: ownerUid,
      );

      // 1. Unpaid attendance case: log attendance (paymentStatus is default 'open')
      await attendanceRepo.createAttendance(
        labourId: labour.id,
        labourName: labour.fullName,
        siteId: 'site_1',
        siteName: 'Site 1',
        date: DateTime.now(),
        status: 'Present',
        hoursWorked: 8.0,
        musterQuantity: 1.0,
        companyId: companyId,
        createdBy: supervisorUid,
      );

      // Try deactivating (should fail due to unpaid attendance)
      expect(
        () => labourRepo.updateLabourStatus(companyId: companyId, labourId: labour.id, status: 'inactive'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('unpaid attendance logs exist'))),
      );

      // Set attendance to paid
      final attendanceSnap = await fakeFirestore
          .collection('companies')
          .doc(companyId)
          .collection('attendance')
          .get();
      final attId = attendanceSnap.docs.first.id;
      await fakeFirestore
          .collection('companies')
          .doc(companyId)
          .collection('attendance')
          .doc(attId)
          .update({'paymentStatus': 'paid'});

      // Try deactivating again (should succeed since attendance is paid and no advances exist)
      await labourRepo.updateLabourStatus(companyId: companyId, labourId: labour.id, status: 'inactive');
      
      final updatedLabour = await labourRepo.getLabourById(companyId: companyId, labourId: labour.id);
      expect(updatedLabour!.status.name, 'inactive');

      // Reactivate labour for advances test
      await fakeFirestore.collection('companies').doc(companyId).collection('labour').doc(labour.id).update({
        'status': 'active',
      });

      // 2. Unpaid advances case: write advance
      await fakeFirestore.collection('companies').doc(companyId).collection('advances').add({
        'labourId': labour.id,
        'amount': 2000.0,
        'status': 'pending',
      });

      // Try deactivating (should fail due to unpaid advances)
      expect(
        () => labourRepo.updateLabourStatus(companyId: companyId, labourId: labour.id, status: 'inactive'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('unpaid/unrecovered advances exist'))),
      );
    });

    test('6b. Block attendance logging for inactive workers', () async {
      await fakeFirestore.collection('companies').doc(companyId).set({
        'attendanceBackdateLimitDays': 3,
      });

      await fakeFirestore.collection('companies').doc(companyId).collection('sites').doc('site_1').set({
        'name': 'Site 1',
      });

      // Create inactive labour worker
      final labour = await labourRepo.createLabour(
        fullName: 'Inactive Labour',
        phoneNumber: '9876543210',
        aadhaarNumber: '123456789012',
        dailyWage: 500.0,
        assignedSiteId: 'site_1',
        assignedSiteName: 'Site 1',
        joinedDate: DateTime.now(),
        status: 'inactive',
        companyId: companyId,
        createdBy: ownerUid,
      );

      // Attempt single attendance logging (should fail)
      expect(
        () => attendanceRepo.createAttendance(
          labourId: labour.id,
          labourName: labour.fullName,
          siteId: 'site_1',
          siteName: 'Site 1',
          date: DateTime.now(),
          status: 'Present',
          hoursWorked: 8.0,
          musterQuantity: 1.0,
          companyId: companyId,
          createdBy: supervisorUid,
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Cannot log attendance for inactive worker'))),
      );

      // Attempt bulk attendance logging (should skip the inactive worker)
      final bulkResult = await attendanceRepo.createBulkAttendance(
        siteId: 'site_1',
        siteName: 'Site 1',
        date: DateTime.now(),
        companyId: companyId,
        createdBy: supervisorUid,
        labourRecords: [
          (
            labourId: labour.id,
            labourName: labour.fullName,
            status: 'Present',
            hoursWorked: 8.0,
            musterQuantity: 1.0,
          )
        ],
      );

      expect(bulkResult.$1, 0);
      expect(bulkResult.$2, 1);
    });

    test('7. Supervisor site enforcement (filtering in providers)', () async {
      final container = ProviderContainer(
        overrides: [
          userCompanyIdProvider.overrideWith((ref) => companyId),
          assignedSiteIdsProvider.overrideWith((ref) => ['site_1']),
          userRoleProvider.overrideWith((ref) => UserRole.supervisor),
          attendanceRepositoryProvider.overrideWith((ref) => attendanceRepo),
        ],
      );

      // Create two records: one in supervisor's assigned site, and one in another site
      await fakeFirestore.collection('companies').doc(companyId).set({
        'attendanceBackdateLimitDays': 3,
      });

      await fakeFirestore.collection('companies').doc(companyId).collection('sites').doc('site_1').set({
        'name': 'Site 1',
      });
      await fakeFirestore.collection('companies').doc(companyId).collection('sites').doc('site_2').set({
        'name': 'Site 2',
      });

      await fakeFirestore.collection('companies').doc(companyId).collection('labour').doc('labour_1').set({
        'fullName': 'Worker 1',
        'dailyWage': 500.0,
      });
      await fakeFirestore.collection('companies').doc(companyId).collection('labour').doc('labour_2').set({
        'fullName': 'Worker 2',
        'dailyWage': 500.0,
      });

      // Log attendance on site_1 (assigned)
      await attendanceRepo.createAttendance(
        labourId: 'labour_1',
        labourName: 'Worker 1',
        siteId: 'site_1',
        siteName: 'Site 1',
        date: DateTime.now(),
        status: 'Present',
        hoursWorked: 8.0,
        musterQuantity: 1.0,
        companyId: companyId,
        createdBy: supervisorUid,
      );

      // Log attendance on site_2 (not assigned)
      await attendanceRepo.createAttendance(
        labourId: 'labour_2',
        labourName: 'Worker 2',
        siteId: 'site_2',
        siteName: 'Site 2',
        date: DateTime.now(),
        status: 'Present',
        hoursWorked: 8.0,
        musterQuantity: 1.0,
        companyId: companyId,
        createdBy: supervisorUid,
      );

      // Listen to role-aware attendance stream provider
      final list = await container.read(roleAwareAttendanceStreamProvider.future);

      // Must only contain site_1 record (supervisor site scope enforcement)
      expect(list.length, 1);
      expect(list.first.siteId, 'site_1');
    });

    test('8. Migration utility test', () async {
      // 1. Create a legacy attendance record with a non-deterministic random doc ID and missing snapshots
      final randomDocId = 'random_legacy_doc_id';
      final legacyDate = DateTime(2026, 5, 20);
      
      await fakeFirestore.collection('companies').doc(companyId).collection('labour').doc('labour_mig').set({
        'fullName': 'Migration Worker',
        'dailyWage': 450.0,
      });

      await fakeFirestore.collection('companies').doc(companyId).collection('sites').doc('site_mig').set({
        'name': 'Migration Site',
      });

      // Write direct legacy record to firestore
      await fakeFirestore
          .collection('companies')
          .doc(companyId)
          .collection('attendance')
          .doc(randomDocId)
          .set({
        'labourId': 'labour_mig',
        'labourName': 'Migration Worker',
        'siteId': 'site_mig',
        'siteName': 'Migration Site',
        'date': Timestamp.fromDate(legacyDate),
        'status': 'Present',
        'hoursWorked': 8.0,
        'musterQuantity': 1.0,
        'companyId': companyId,
        'createdAt': Timestamp.now(),
        'createdBy': 'legacy_system',
      });

      // Run migration
      await attendanceRepo.migrateLegacyRecords(companyId: companyId);

      // Verify the new deterministic record exists with snapshots
      final expectedDocId = attendanceRepo.generateAttendanceDocId(
        labourId: 'labour_mig',
        siteId: 'site_mig',
        date: legacyDate,
      );

      final newSnap = await fakeFirestore
          .collection('companies')
          .doc(companyId)
          .collection('attendance')
          .doc(expectedDocId)
          .get();

      expect(newSnap.exists, isTrue);
      
      final data = newSnap.data()!;
      expect(data['dailyWageSnapshot'], 450.0);
      expect(data['earningsSnapshot'], 450.0);
      expect(data['labourNameSnapshot'], 'Migration Worker');
      expect(data['siteNameSnapshot'], 'Migration Site');
      expect(data['paymentStatus'], 'open');

      // Verify old random ID doc was deleted
      final oldSnap = await fakeFirestore
          .collection('companies')
          .doc(companyId)
          .collection('attendance')
          .doc(randomDocId)
          .get();
      
      expect(oldSnap.exists, isFalse);
    });
  });
}
