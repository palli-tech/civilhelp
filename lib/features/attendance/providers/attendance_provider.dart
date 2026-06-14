import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/core/providers/company_provider.dart';
import 'package:civilhelp/core/providers/user_role_provider.dart';
import 'package:civilhelp/core/enums/user_role.dart';
import 'package:civilhelp/features/auth/providers/auth_provider.dart';
import '../models/attendance_model.dart';
import '../repositories/attendance_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});

final attendanceStreamProvider = StreamProvider<List<AttendanceModel>>((ref) {
  final repository = ref.watch(attendanceRepositoryProvider);
  final companyId = ref.watch(userCompanyIdProvider);

  return companyId.when(
    data: (id) => repository.getAttendanceByCompanyStream(id),
    loading: () => Stream.value([]),
    error: (error, _) => Stream.error(error),
  );
});

final attendanceBySiteStreamProvider =
    StreamProvider.family<List<AttendanceModel>, String>((ref, siteId) {
      final repository = ref.watch(attendanceRepositoryProvider);
      final companyId = ref.watch(userCompanyIdProvider);

      return companyId.when(
        data: (id) => repository.getAttendanceBySiteStream(id, siteId),
        loading: () => Stream.value([]),
        error: (error, _) => Stream.error(error),
      );
    });

final attendanceByLabourStreamProvider =
    StreamProvider.family<List<AttendanceModel>, String>((ref, labourId) {
      final repository = ref.watch(attendanceRepositoryProvider);
      final companyId = ref.watch(userCompanyIdProvider);

      return companyId.when(
        data: (id) => repository.getAttendanceByLabourStream(id, labourId),
        loading: () => Stream.value([]),
        error: (error, _) => Stream.error(error),
      );
    });

final attendanceTodayStreamProvider = StreamProvider<List<AttendanceModel>>((
  ref,
) {
  final repository = ref.watch(attendanceRepositoryProvider);
  final companyId = ref.watch(userCompanyIdProvider);

  return companyId.when(
    data: (id) => repository.getAttendanceForTodayStream(id),
    loading: () => Stream.value([]),
    error: (error, _) => Stream.error(error),
  );
});
final updateAttendanceProvider = FutureProvider.family<void, AttendanceModel>((
  ref,
  attendance,
) async {
  final repository = ref.read(attendanceRepositoryProvider);
  final companyId = await ref.watch(userCompanyIdProvider.future);
  final currentUser = ref.watch(currentUserProvider);

  // Prevent date collisions: if another attendance exists for same labour+date, block update
  final existing = await repository.getAttendanceForLabourOnDate(
    companyId: companyId,
    labourId: attendance.labourId,
    date: attendance.date,
  );

  if (existing != null && existing.id != attendance.id) {
    throw Exception(
      'Attendance already exists for this labour on the selected date',
    );
  }

  await repository.updateAttendance(
    attendance: attendance,
    updatedBy: currentUser?.uid ?? 'unknown',
  );

  // Invalidate affected streams
  ref.invalidate(attendanceStreamProvider);
  ref.invalidate(attendanceBySiteStreamProvider(attendance.siteId));
  ref.invalidate(attendanceByLabourStreamProvider(attendance.labourId));
  ref.invalidate(attendanceTodayStreamProvider);
});

final deleteAttendanceProvider =
    FutureProvider.family<void, ({String attendanceId, String deleteReason})>((
  ref,
  params,
) async {
  final companyId = await ref.watch(userCompanyIdProvider.future);
  final currentUser = ref.watch(currentUserProvider);

  await ref
      .read(attendanceRepositoryProvider)
      .deleteAttendance(
        attendanceId: params.attendanceId,
        companyId: companyId,
        deletedBy: currentUser?.uid ?? 'unknown',
        deleteReason: params.deleteReason,
      );

  // Invalidate all attendance streams after delete
  ref.invalidate(attendanceStreamProvider);
  ref.invalidate(attendanceBySiteStreamProvider);
  ref.invalidate(attendanceByLabourStreamProvider);
  ref.invalidate(attendanceTodayStreamProvider);
});

final createAttendanceProvider =
    FutureProvider.family<
      AttendanceModel,
      (
        String labourId,
        String labourName,
        String siteId,
        String siteName,
        DateTime date,
        String status,
        double hoursWorked,
        double musterQuantity,
      )
    >((ref, params) async {
      final repository = ref.watch(attendanceRepositoryProvider);
      final companyId = await ref.watch(userCompanyIdProvider.future);
      final currentUser = ref.watch(currentUserProvider);

      // Duplicate prevention: check existing attendance for same labour+date
      final existing = await repository.getAttendanceForLabourOnDate(
        companyId: companyId,
        labourId: params.$1,
        date: params.$5,
      );
      debugPrint('EXISTING ATTENDANCE -> ${existing?.id}');
      if (existing != null) {
        throw Exception(
          'Attendance already exists for the selected labour and date',
        );
      }

      final attendance = await repository.createAttendance(
        labourId: params.$1,
        labourName: params.$2,
        siteId: params.$3,
        siteName: params.$4,
        date: params.$5,
        status: params.$6,
        hoursWorked: params.$7,
        musterQuantity: params.$8,
        companyId: companyId,
        createdBy: currentUser?.uid ?? 'unknown',
      );

      ref.invalidate(attendanceStreamProvider);
      ref.invalidate(attendanceBySiteStreamProvider(params.$3));
      ref.invalidate(attendanceByLabourStreamProvider(params.$1));
      ref.invalidate(attendanceTodayStreamProvider);

      return attendance;
    });

typedef BulkAttendanceParams = ({
  String siteId,
  String siteName,
  DateTime date,
  List<
    ({String labourId, String labourName, String status, double hoursWorked, double musterQuantity})
  >
  labourRecords,
});

final createBulkAttendanceProvider =
    FutureProvider.family<(int created, int skipped), BulkAttendanceParams>((
      ref,
      params,
    ) async {
      final repository = ref.watch(attendanceRepositoryProvider);
      final companyId = await ref.watch(userCompanyIdProvider.future);
      final currentUser = ref.watch(currentUserProvider);

      final result = await repository.createBulkAttendance(
        siteId: params.siteId,
        siteName: params.siteName,
        date: params.date,
        companyId: companyId,
        createdBy: currentUser?.uid ?? 'unknown',
        labourRecords: params.labourRecords,
      );

      // Invalidate streams to refresh UI
      ref.invalidate(attendanceStreamProvider);
      ref.invalidate(attendanceBySiteStreamProvider(params.siteId));
      ref.invalidate(attendanceTodayStreamProvider);

      // Also invalidate for each individual labour involved
      for (final record in params.labourRecords) {
        ref.invalidate(attendanceByLabourStreamProvider(record.labourId));
      }

      return result;
    });

/// Supervisor-filtered attendance: only attendance at assigned sites.
final supervisorAttendanceStreamProvider = StreamProvider<List<AttendanceModel>>((ref) {
  final repository = ref.watch(attendanceRepositoryProvider);
  final companyId = ref.watch(userCompanyIdProvider).value ?? '';
  final assignedSiteIds = ref.watch(assignedSiteIdsProvider);

  if (companyId.isEmpty) {
    return Stream.value([]);
  }

  return repository.getAttendanceByCompanyStream(companyId).map((attendance) {
    return attendance.where((a) => assignedSiteIds.contains(a.siteId)).toList();
  });
});

/// Role-aware attendance provider.
///
/// Automatically returns the correct stream based on the user's role:
/// - Owner: company-wide attendance
/// - Supervisor: filtered to assigned sites only
final roleAwareAttendanceStreamProvider = StreamProvider<List<AttendanceModel>>((ref) {
  final role = ref.watch(userRoleProvider);
  final repository = ref.watch(attendanceRepositoryProvider);
  final companyId = ref.watch(userCompanyIdProvider).value ?? '';

  if (companyId.isEmpty) {
    return Stream.value([]);
  }

  if (role == UserRole.supervisor) {
    final assignedSiteIds = ref.watch(assignedSiteIdsProvider);
    return repository.getAttendanceByCompanyStream(companyId).map((attendance) {
      return attendance.where((a) => assignedSiteIds.contains(a.siteId)).toList();
    });
  }

  // Owner and other roles: full company-wide stream
  return repository.getAttendanceByCompanyStream(companyId);
});
