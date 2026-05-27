import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/core/providers/company_provider.dart';
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

final attendanceBySiteStreamProvider = StreamProvider.family<
    List<AttendanceModel>, String>((ref, siteId) {
  final repository = ref.watch(attendanceRepositoryProvider);
  final companyId = ref.watch(userCompanyIdProvider);

  return companyId.when(
    data: (id) => repository.getAttendanceBySiteStream(id, siteId),
    loading: () => Stream.value([]),
    error: (error, _) => Stream.error(error),
  );
});

final attendanceByLabourStreamProvider = StreamProvider.family<
    List<AttendanceModel>, String>((ref, labourId) {
  final repository = ref.watch(attendanceRepositoryProvider);
  final companyId = ref.watch(userCompanyIdProvider);

  return companyId.when(
    data: (id) => repository.getAttendanceByLabourStream(id, labourId),
    loading: () => Stream.value([]),
    error: (error, _) => Stream.error(error),
  );
});

final attendanceTodayStreamProvider = StreamProvider<List<AttendanceModel>>(
  (ref) {
    final repository = ref.watch(attendanceRepositoryProvider);
    final companyId = ref.watch(userCompanyIdProvider);

    return companyId.when(
      data: (id) => repository.getAttendanceForTodayStream(id),
      loading: () => Stream.value([]),
      error: (error, _) => Stream.error(error),
    );
  },
);

final createAttendanceProvider = FutureProvider.family<AttendanceModel, (
  String labourId,
  String labourName,
  String siteId,
  String siteName,
  DateTime date,
  String status,
  double hoursWorked,
)>((ref, params) async {
  final repository = ref.watch(attendanceRepositoryProvider);
  final companyId = await ref.watch(userCompanyIdProvider.future);
  final currentUser = ref.watch(currentUserProvider);

  final attendance = await repository.createAttendance(
    labourId: params.$1,
    labourName: params.$2,
    siteId: params.$3,
    siteName: params.$4,
    date: params.$5,
    status: params.$6,
    hoursWorked: params.$7,
    companyId: companyId,
    createdBy: currentUser?.uid ?? 'unknown',
  );

  ref.invalidate(attendanceStreamProvider);
  ref.invalidate(attendanceBySiteStreamProvider(params.$3));
  ref.invalidate(attendanceByLabourStreamProvider(params.$1));
  ref.invalidate(attendanceTodayStreamProvider);

  return attendance;
});
