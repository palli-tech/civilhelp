import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:civilhelp/core/providers/company_provider.dart';
import 'package:civilhelp/core/services/firestore_path_service.dart';
import 'package:civilhelp/core/enums/labour_status.dart';
import 'package:civilhelp/core/enums/site_status.dart';
import 'package:civilhelp/features/attendance/models/attendance_model.dart';
import 'package:civilhelp/features/labour/data/models/labour_model.dart';
import 'package:civilhelp/core/providers/user_role_provider.dart';

import 'package:civilhelp/features/advances/providers/advance_provider.dart' as advance_providers;
import 'package:civilhelp/features/labour/presentation/providers/labour_provider.dart' as labour_providers;
import 'package:civilhelp/features/payments/providers/payment_provider.dart' as payment_providers;
import 'package:civilhelp/features/sites/providers/site_provider.dart' as site_providers;

// 1. Total Sites
final totalSitesCountProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(site_providers.siteRepositoryProvider);
  final companyId = ref.watch(userCompanyIdProvider);

  return companyId.when(
    data: (id) => repository.getSitesByCompanyStream(id).map((sites) => sites.length),
    loading: () => Stream.value(0),
    error: (error, _) => Stream.error(error),
  );
});

// 2. Active Sites
final activeSitesCountProvider = StreamProvider<int>((ref) {
  final companyId = ref.watch(userCompanyIdProvider).value ?? '';
  if (companyId.isEmpty) return Stream.value(0);

  return FirebaseFirestore.instance
      .collection(FirestorePathService.sites(companyId))
      .where('status', isEqualTo: 'active')
      .snapshots()
      .map((snap) => snap.docs.length);
});

// 3. Active Labour
final activeLabourCountProvider = StreamProvider<int>((ref) {
  final companyId = ref.watch(userCompanyIdProvider).value ?? '';
  if (companyId.isEmpty) return Stream.value(0);

  return FirebaseFirestore.instance
      .collection(FirestorePathService.labour(companyId))
      .where('status', isEqualTo: 'active')
      .snapshots()
      .map((snap) => snap.docs.length);
});

// 4. Today's Attendance count
final todayAttendanceCountProvider = StreamProvider<int>((ref) {
  final companyId = ref.watch(userCompanyIdProvider).value ?? '';
  if (companyId.isEmpty) return Stream.value(0);

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  return FirebaseFirestore.instance
      .collection(FirestorePathService.attendance(companyId))
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
      .where('date', isLessThan: Timestamp.fromDate(endOfDay))
      .snapshots()
      .map((snap) => snap.docs.length);
});

// Today's Attendance List (helper for supervisor filtering)
final todayAttendanceListProvider = StreamProvider<List<AttendanceModel>>((ref) {
  final companyId = ref.watch(userCompanyIdProvider).value ?? '';
  if (companyId.isEmpty) return Stream.value([]);

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  return FirebaseFirestore.instance
      .collection(FirestorePathService.attendance(companyId))
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
      .where('date', isLessThan: Timestamp.fromDate(endOfDay))
      .snapshots()
      .map((snap) => snap.docs.map((doc) => AttendanceModel.fromFirestore(doc)).toList());
});

// 5. Outstanding Advances (sum outstanding balance for active/unpaid advances)
final outstandingAdvanceTotalProvider = StreamProvider<double>((ref) {
  final repository = ref.watch(advance_providers.advanceRepositoryProvider);
  final companyId = ref.watch(userCompanyIdProvider);

  return companyId.when(
    data: (id) => repository
        .getOutstandingAdvancesByCompanyStream(id)
        .map((advances) => advances.fold<double>(0.0, (total, item) => total + (item.amount - item.recoveredAmount))),
    loading: () => Stream.value(0.0),
    error: (error, _) => Stream.error(error),
  );
});

// 6. Pending Payments Count
final pendingPaymentsCountProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(payment_providers.paymentRepositoryProvider);
  final companyId = ref.watch(userCompanyIdProvider);

  return companyId.when(
    data: (id) => repository
        .getPaymentsByStatusStream(id, 'pending')
        .map((payments) => payments.length),
    loading: () => Stream.value(0),
    error: (error, _) => Stream.error(error),
  );
});

// Current Month Attendance List (helper for payroll)
final currentMonthAttendanceProvider = StreamProvider<List<AttendanceModel>>((ref) {
  final companyId = ref.watch(userCompanyIdProvider).value ?? '';
  if (companyId.isEmpty) return Stream.value([]);

  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 1);

  return FirebaseFirestore.instance
      .collection(FirestorePathService.attendance(companyId))
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
      .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
      .snapshots()
      .map((snap) => snap.docs.map((doc) => AttendanceModel.fromFirestore(doc)).toList());
});

// 7. Current Month Payroll (computed from actual month attendances and daily wages)
final currentMonthPayrollProvider = Provider<AsyncValue<double>>((ref) {
  final attendanceAsync = ref.watch(currentMonthAttendanceProvider);
  final labourListAsync = ref.watch(labour_providers.labourStreamProvider);

  return attendanceAsync.when(
    data: (attendances) {
      return labourListAsync.when(
        data: (labourList) {
          final wageMap = {for (final l in labourList) l.id: l.dailyWage};
          double totalPayroll = 0.0;
          for (final att in attendances) {
            final wage = wageMap[att.labourId] ?? 0.0;
            totalPayroll += att.calculateEarnings(wage);
          }
          return AsyncValue.data(totalPayroll);
        },
        loading: () => const AsyncValue.loading(),
        error: (err, stack) => AsyncValue.error(err, stack),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

// --- Supervisor-specific assigned metrics ---

// Supervisor assigned site IDs from user document (watches centralized provider)
final supervisorAssignedSiteIdsProvider = Provider<List<String>>((ref) {
  return ref.watch(assignedSiteIdsProvider);
});

// 8. Supervisor Assigned active sites count
final supervisorAssignedSitesCountProvider = Provider<AsyncValue<int>>((ref) {
  final assignedIds = ref.watch(supervisorAssignedSiteIdsProvider);
  final sitesAsync = ref.watch(site_providers.sitesStreamProvider);

  return sitesAsync.when(
    data: (sites) => AsyncValue.data(
      sites.where((s) => assignedIds.contains(s.id) && s.status == SiteStatus.active).length,
    ),
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

// 9. Today's Attendance count at supervisor's assigned sites
final supervisorTodayAttendanceCountProvider = Provider<AsyncValue<int>>((ref) {
  final assignedIds = ref.watch(supervisorAssignedSiteIdsProvider);
  final todayAttendanceAsync = ref.watch(todayAttendanceListProvider);

  return todayAttendanceAsync.when(
    data: (attendance) => AsyncValue.data(
      attendance.where((entry) => assignedIds.contains(entry.siteId)).length,
    ),
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

// 10. Present/Half-day Workers count today at supervisor's assigned sites
final supervisorPresentWorkersCountProvider = Provider<AsyncValue<int>>((ref) {
  final assignedIds = ref.watch(supervisorAssignedSiteIdsProvider);
  final todayAttendanceAsync = ref.watch(todayAttendanceListProvider);

  return todayAttendanceAsync.when(
    data: (attendance) => AsyncValue.data(
      attendance.where((entry) =>
          assignedIds.contains(entry.siteId) &&
          (entry.status.toLowerCase() == 'present' || entry.status.toLowerCase() == 'half day')
      ).length,
    ),
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

// 11. Absent Workers count today at supervisor's assigned sites
final supervisorAbsentWorkersCountProvider = Provider<AsyncValue<int>>((ref) {
  final assignedIds = ref.watch(supervisorAssignedSiteIdsProvider);
  final todayAttendanceAsync = ref.watch(todayAttendanceListProvider);

  return todayAttendanceAsync.when(
    data: (attendance) => AsyncValue.data(
      attendance.where((entry) =>
          assignedIds.contains(entry.siteId) &&
          entry.status.toLowerCase() == 'absent'
      ).length,
    ),
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

// 12. Supervisor's assigned active labour list
final supervisorAssignedLabourProvider = Provider<AsyncValue<List<LabourModel>>>((ref) {
  final assignedIds = ref.watch(supervisorAssignedSiteIdsProvider);
  final labourListAsync = ref.watch(labour_providers.labourStreamProvider);

  return labourListAsync.when(
    data: (labour) => AsyncValue.data(
      labour.where((l) => assignedIds.contains(l.assignedSiteId) && l.status == LabourStatus.active).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

// 13. Pending Attendance count (assigned active labour who do not have attendance marked today)
final supervisorPendingAttendanceCountProvider = Provider<AsyncValue<int>>((ref) {
  final assignedLabourAsync = ref.watch(supervisorAssignedLabourProvider);
  final todayAttendanceAsync = ref.watch(todayAttendanceListProvider);

  return assignedLabourAsync.when(
    data: (assignedLabour) {
      return todayAttendanceAsync.when(
        data: (todayAttendance) {
          final markedLabourIds = todayAttendance.map((e) => e.labourId).toSet();
          final pendingCount = assignedLabour.where((l) => !markedLabourIds.contains(l.id)).length;
          return AsyncValue.data(pendingCount);
        },
        loading: () => const AsyncValue.loading(),
        error: (err, stack) => AsyncValue.error(err, stack),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});
