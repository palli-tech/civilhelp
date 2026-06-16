//import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:civilhelp/core/providers/company_provider.dart';
import 'package:civilhelp/core/providers/user_role_provider.dart';
import 'package:civilhelp/core/enums/user_role.dart';
//import 'package:civilhelp/core/enums/labour_status.dart';
import 'package:civilhelp/features/auth/providers/auth_provider.dart';
import '../../labour/data/models/labour_model.dart';
import '../../labour/presentation/providers/labour_provider.dart';
import '../../sites/providers/site_provider.dart';
import '../models/attendance_model.dart';
//import '../repositories/attendance_repository.dart';
import 'attendance_provider.dart';

enum RegisterViewMode { daily, weekly, monthly }

class AttendanceRegisterState {
  final String? selectedSiteId;
  final DateTime selectedDate;
  final RegisterViewMode viewMode;
  final String searchKeyword;
  final bool isLoading;
  final String? errorMessage;

  AttendanceRegisterState({
    this.selectedSiteId,
    required this.selectedDate,
    this.viewMode = RegisterViewMode.daily,
    this.searchKeyword = '',
    this.isLoading = false,
    this.errorMessage,
  });

  AttendanceRegisterState copyWith({
    String? selectedSiteId,
    DateTime? selectedDate,
    RegisterViewMode? viewMode,
    String? searchKeyword,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AttendanceRegisterState(
      selectedSiteId: selectedSiteId ?? this.selectedSiteId,
      selectedDate: selectedDate ?? this.selectedDate,
      viewMode: viewMode ?? this.viewMode,
      searchKeyword: searchKeyword ?? this.searchKeyword,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AttendanceRegisterNotifier extends StateNotifier<AttendanceRegisterState> {
  final Ref ref;

  AttendanceRegisterNotifier(this.ref)
      : super(AttendanceRegisterState(selectedDate: DateTime.now())) {
    // Attempt to set a default site if sites are loaded
    ref.listen(sitesStreamProvider, (prev, next) {
      next.whenData((sites) {
        if (state.selectedSiteId == null && sites.isNotEmpty) {
          final role = ref.read(userRoleProvider);
          if (role == UserRole.supervisor) {
            final assignedSiteIds = ref.read(assignedSiteIdsProvider);
            final firstAssigned = sites.firstWhere(
              (s) => assignedSiteIds.contains(s.id),
              orElse: () => sites.first,
            );
            selectSite(firstAssigned.id);
          } else {
            selectSite(sites.first.id);
          }
        }
      });
    });
  }

  void selectSite(String? siteId) {
    state = state.copyWith(selectedSiteId: siteId, errorMessage: null);
  }

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date, errorMessage: null);
  }

  void setViewMode(RegisterViewMode mode) {
    state = state.copyWith(viewMode: mode, errorMessage: null);
  }

  void setSearchKeyword(String keyword) {
    state = state.copyWith(searchKeyword: keyword, errorMessage: null);
  }

  /// Mark all active workers on date as present
  Future<void> markAllPresentForDate(DateTime date) async {
    final siteId = state.selectedSiteId;
    if (siteId == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repository = ref.read(attendanceRepositoryProvider);
      final companyId = await ref.read(userCompanyIdProvider.future);
      final currentUser = ref.read(currentUserProvider);
      final role = ref.read(userRoleProvider);

      // Fetch workers active on this date
      final labourAsync = ref.read(labourStreamProvider);
      final allLabour = labourAsync.value ?? [];

      final activeWorkers = allLabour.where((l) {
        if (l.assignedSiteId != siteId) return false;
        return isWorkerActiveOnDate(l, date);
      }).toList();

      if (activeWorkers.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }

      // Fetch site details
      final sitesAsync = ref.read(sitesStreamProvider);
      final sites = sitesAsync.value ?? [];
      final site = sites.firstWhere((s) => s.id == siteId);

      final records = activeWorkers.map((l) {
        return (
          labourId: l.id,
          labourName: l.fullName,
          status: 'Present',
          hoursWorked: 8.0,
          musterQuantity: 1.0,
        );
      }).toList();

      final result = await repository.createBulkAttendance(
        siteId: siteId,
        siteName: site.name,
        date: date,
        companyId: companyId,
        createdBy: currentUser?.uid ?? 'unknown',
        labourRecords: records,
        userRole: role.name,
      );

      // Invalidate providers to force refresh
      ref.invalidate(attendanceBySiteStreamProvider(siteId));
      ref.invalidate(attendanceTodayStreamProvider);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Update single cell details (creates, updates, or soft-deletes)
  Future<void> updateAttendanceCell({
    required LabourModel labour,
    required DateTime date,
    required String status,
    required double hoursWorked,
    required double musterQuantity,
    AttendanceModel? existingRecord,
  }) async {
    final siteId = state.selectedSiteId;
    if (siteId == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repository = ref.read(attendanceRepositoryProvider);
      final companyId = await ref.read(userCompanyIdProvider.future);
      final currentUser = ref.read(currentUserProvider);
      final role = ref.read(userRoleProvider);

      if (status.toLowerCase() == 'deleted') {
        if (existingRecord != null) {
          await repository.deleteAttendance(
            attendanceId: existingRecord.id,
            companyId: companyId,
            deletedBy: currentUser?.uid ?? 'unknown',
            deleteReason: 'Supervisor removed cell',
            userRole: role.name,
          );
        }
      } else {
        if (existingRecord != null) {
          final updated = existingRecord.copyWith(
            status: status,
            hoursWorked: hoursWorked,
            musterQuantity: musterQuantity,
          );
          await repository.updateAttendance(
            attendance: updated,
            updatedBy: currentUser?.uid ?? 'unknown',
            userRole: role.name,
          );
        } else {
          final sitesAsync = ref.read(sitesStreamProvider);
          final sites = sitesAsync.value ?? [];
          final siteName = sites.firstWhere((s) => s.id == siteId).name;

          await repository.createAttendance(
            labourId: labour.id,
            labourName: labour.fullName,
            siteId: siteId,
            siteName: siteName,
            date: date,
            status: status,
            hoursWorked: hoursWorked,
            musterQuantity: musterQuantity,
            companyId: companyId,
            createdBy: currentUser?.uid ?? 'unknown',
            userRole: role.name,
          );
        }
      }

      ref.invalidate(attendanceBySiteStreamProvider(siteId));
      ref.invalidate(attendanceTodayStreamProvider);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Lock/Mark site attendance as completed
  Future<void> completeSiteAttendance(DateTime date) async {
    final siteId = state.selectedSiteId;
    if (siteId == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repository = ref.read(attendanceRepositoryProvider);
      final companyId = await ref.read(userCompanyIdProvider.future);
      final currentUser = ref.read(currentUserProvider);

      await repository.markSiteAttendanceComplete(
        companyId: companyId,
        siteId: siteId,
        date: date,
        completedBy: currentUser?.uid ?? 'unknown',
      );

      // Force recalculation
      ref.invalidate(attendanceCompletionsStreamProvider((companyId: companyId, siteId: siteId)));
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Reopen site attendance (Owner/Admin only)
  Future<void> reopenSiteAttendance(DateTime date) async {
    final siteId = state.selectedSiteId;
    if (siteId == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repository = ref.read(attendanceRepositoryProvider);
      final companyId = await ref.read(userCompanyIdProvider.future);
      final currentUser = ref.read(currentUserProvider);

      await repository.reopenSiteAttendance(
        companyId: companyId,
        siteId: siteId,
        date: date,
        verifiedBy: currentUser?.uid ?? 'unknown',
      );

      // Force recalculation
      ref.invalidate(attendanceCompletionsStreamProvider((companyId: companyId, siteId: siteId)));
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Manually unlock a frozen log and write an audit trace
  Future<void> unlockFrozenCell({
    required LabourModel labour,
    required DateTime date,
    required String reason,
  }) async {
    final siteId = state.selectedSiteId;
    if (siteId == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repository = ref.read(attendanceRepositoryProvider);
      final companyId = await ref.read(userCompanyIdProvider.future);
      final currentUser = ref.read(currentUserProvider);

      final attendanceId = repository.generateAttendanceDocId(
        labourId: labour.id,
        siteId: siteId,
        date: date,
      );

      await repository.logUnlockAudit(
        companyId: companyId,
        attendanceId: attendanceId,
        unlockedBy: currentUser?.uid ?? 'unknown',
        unlockReason: reason,
        siteId: siteId,
        labourId: labour.id,
        date: date,
      );

      // Invalidate stream of unlock audits
      ref.invalidate(unlockAuditsStreamProvider);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }
}

final attendanceRegisterStateProvider =
    StateNotifierProvider<AttendanceRegisterNotifier, AttendanceRegisterState>((ref) {
  return AttendanceRegisterNotifier(ref);
});

/// Helper to verify if worker was active on a given date
bool isWorkerActiveOnDate(LabourModel labour, DateTime date) {
  final target = DateTime(date.year, date.month, date.day);
  final joined = DateTime(labour.joinedDate.year, labour.joinedDate.month, labour.joinedDate.day);
  if (target.isBefore(joined)) return false;
  if (labour.deactivatedAt != null) {
    final deactivated = DateTime(
      labour.deactivatedAt!.year,
      labour.deactivatedAt!.month,
      labour.deactivatedAt!.day,
    );
    if (target.isAfter(deactivated)) return false;
  }
  return true;
}

/// Helper to format date consistently
String formatDateKey(DateTime date) {
  return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
}

List<DateTime> getDaysInWeek(DateTime date) {
  final monday = date.subtract(Duration(days: date.weekday - 1));
  return List.generate(7, (index) => monday.add(Duration(days: index)));
}

List<DateTime> getDaysInMonth(DateTime date) {
  final firstDay = DateTime(date.year, date.month, 1);
  final lastDay = DateTime(date.year, date.month + 1, 0);
  return List.generate(lastDay.day, (index) => firstDay.add(Duration(days: index)));
}

class WorkerTotals {
  final int presentCount;
  final int halfDayCount;
  final int absentCount;
  final double overtimeHours;
  final double totalEarned;

  WorkerTotals({
    required this.presentCount,
    required this.halfDayCount,
    required this.absentCount,
    required this.overtimeHours,
    required this.totalEarned,
  });
}

class RegisterMatrixData {
  final List<DateTime> dates;
  final List<LabourModel> workers;
  final Map<String, Map<String, AttendanceModel>> grid; // labourId -> DateStr -> Attendance
  final Map<String, Map<String, dynamic>> completions; // DateStr -> completion data
  final Map<String, bool> unlockedCells; // attendanceId -> isUnlocked
  
  // Daily Column Totals
  final Map<String, int> dailyPresentCount;
  final Map<String, int> dailyHalfDayCount;
  final Map<String, int> dailyAbsentCount;
  final Map<String, double> dailyOvertimeHours;

  // Worker Row Totals
  final Map<String, WorkerTotals> workerTotals;

  RegisterMatrixData({
    required this.dates,
    required this.workers,
    required this.grid,
    required this.completions,
    required this.unlockedCells,
    required this.dailyPresentCount,
    required this.dailyHalfDayCount,
    required this.dailyAbsentCount,
    required this.dailyOvertimeHours,
    required this.workerTotals,
  });

  factory RegisterMatrixData.empty() {
    return RegisterMatrixData(
      dates: [],
      workers: [],
      grid: {},
      completions: {},
      unlockedCells: {},
      dailyPresentCount: {},
      dailyHalfDayCount: {},
      dailyAbsentCount: {},
      dailyOvertimeHours: {},
      workerTotals: {},
    );
  }
}

final attendanceCompletionsStreamProvider = StreamProvider.family<
    Map<String, Map<String, dynamic>>,
    ({String companyId, String siteId})>((ref, arg) {
  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection('companies/${arg.companyId}/sites/${arg.siteId}/attendanceCompletions')
      .snapshots()
      .map((snap) {
    return {for (var doc in snap.docs) doc.id: doc.data()};
  });
});

final unlockAuditsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final companyId = ref.watch(userCompanyIdProvider).value ?? '';
  if (companyId.isEmpty) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('companies/$companyId/attendanceUnlockAudits')
      .snapshots()
      .map((snap) => snap.docs.map((doc) => doc.data()).toList());
});

final attendanceRegisterMatrixProvider = Provider<RegisterMatrixData>((ref) {
  final state = ref.watch(attendanceRegisterStateProvider);
  final companyId = ref.watch(userCompanyIdProvider).value ?? '';
  final siteId = state.selectedSiteId;

  if (companyId.isEmpty || siteId == null) {
    return RegisterMatrixData.empty();
  }

  // 1. Get dates in range
  final List<DateTime> dates;
  if (state.viewMode == RegisterViewMode.daily) {
    dates = [state.selectedDate];
  } else if (state.viewMode == RegisterViewMode.weekly) {
    dates = getDaysInWeek(state.selectedDate);
  } else {
    dates = getDaysInMonth(state.selectedDate);
  }

  // 2. Fetch all labour
  final allLabour = ref.watch(labourStreamProvider).value ?? [];

  // 3. Fetch attendance for this site
  final allAttendance = ref.watch(attendanceBySiteStreamProvider(siteId)).value ?? [];

  // 4. Fetch completions & unlock audits
  final completions = ref.watch(attendanceCompletionsStreamProvider((
        companyId: companyId,
        siteId: siteId
      ))).value ?? {};
  
  final audits = ref.watch(unlockAuditsStreamProvider).value ?? [];
  final unlockedCells = {
    for (var audit in audits) audit['attendanceId'] as String: true
  };

  // Filter attendance records by dates in range
  final startRange = DateTime(dates.first.year, dates.first.month, dates.first.day);
  final endRange = DateTime(dates.last.year, dates.last.month, dates.last.day, 23, 59, 59, 999);

  final attendanceLogs = allAttendance.where((a) {
    return a.date.isAfter(startRange.subtract(const Duration(seconds: 1))) &&
        a.date.isBefore(endRange.add(const Duration(seconds: 1)));
  }).toList();

  // 5. Filter workers
  final search = state.searchKeyword.toLowerCase().trim();
  final workers = allLabour.where((l) {
    final isAssigned = l.assignedSiteId == siteId;
    final hasAttendance = attendanceLogs.any((a) => a.labourId == l.id);
    final isActiveInRange = dates.any((d) => isWorkerActiveOnDate(l, d));

    if ((isAssigned && isActiveInRange) || hasAttendance) {
      if (search.isNotEmpty && !l.fullName.toLowerCase().contains(search)) return false;
      return true;
    }
    return false;
  }).toList();

  // 6. Build index map: labourId -> dateStr -> Attendance
  final Map<String, Map<String, AttendanceModel>> grid = {};
  for (final worker in workers) {
    grid[worker.id] = {};
  }

  for (final log in attendanceLogs) {
    if (grid.containsKey(log.labourId)) {
      final dateKey = formatDateKey(log.date);
      grid[log.labourId]![dateKey] = log;
    }
  }

  // 7. Calculate daily column totals & worker totals
  final Map<String, int> dailyPresentCount = {};
  final Map<String, int> dailyHalfDayCount = {};
  final Map<String, int> dailyAbsentCount = {};
  final Map<String, double> dailyOvertimeHours = {};

  final Map<String, WorkerTotals> workerTotals = {};

  for (final d in dates) {
    final dateKey = formatDateKey(d);
    dailyPresentCount[dateKey] = 0;
    dailyHalfDayCount[dateKey] = 0;
    dailyAbsentCount[dateKey] = 0;
    dailyOvertimeHours[dateKey] = 0.0;
  }

  for (final worker in workers) {
    int present = 0;
    int halfDay = 0;
    int absent = 0;
    double ot = 0.0;
    double earned = 0.0;

    for (final d in dates) {
      final dateKey = formatDateKey(d);
      final log = grid[worker.id]?[dateKey];

      if (log != null) {
        final statusLower = log.status.toLowerCase();
        final hours = log.hoursWorked;
        double normalHours = 0.0;

        if (statusLower == 'present') {
          present++;
          dailyPresentCount[dateKey] = (dailyPresentCount[dateKey] ?? 0) + 1;
          normalHours = 8.0;
        } else if (statusLower == 'half day' || statusLower == 'half-day') {
          halfDay++;
          dailyHalfDayCount[dateKey] = (dailyHalfDayCount[dateKey] ?? 0) + 1;
          normalHours = 4.0;
        } else if (statusLower == 'absent') {
          absent++;
          dailyAbsentCount[dateKey] = (dailyAbsentCount[dateKey] ?? 0) + 1;
          normalHours = 0.0;
        }

        final cellOt = (hours > normalHours) ? (hours - normalHours) : 0.0;
        ot += cellOt;
        dailyOvertimeHours[dateKey] = (dailyOvertimeHours[dateKey] ?? 0.0) + cellOt;
        earned += log.earningsSnapshot;
      }
    }

    workerTotals[worker.id] = WorkerTotals(
      presentCount: present,
      halfDayCount: halfDay,
      absentCount: absent,
      overtimeHours: ot,
      totalEarned: earned,
    );
  }

  return RegisterMatrixData(
    dates: dates,
    workers: workers,
    grid: grid,
    completions: completions,
    unlockedCells: unlockedCells,
    dailyPresentCount: dailyPresentCount,
    dailyHalfDayCount: dailyHalfDayCount,
    dailyAbsentCount: dailyAbsentCount,
    dailyOvertimeHours: dailyOvertimeHours,
    workerTotals: workerTotals,
  );
});

final companySettingsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final companyId = ref.watch(companyIdProvider);
  if (companyId.isEmpty) return Stream.value({});
  return FirebaseFirestore.instance
      .collection('companies')
      .doc(companyId)
      .snapshots()
      .map((doc) => doc.data() ?? {});
});
