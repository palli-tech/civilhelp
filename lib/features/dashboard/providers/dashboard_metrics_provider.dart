import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/core/providers/company_provider.dart';
import 'package:civilhelp/features/attendance/providers/attendance_provider.dart' as attendance_providers;
import 'package:civilhelp/features/advances/providers/advance_provider.dart' as advance_providers;
import 'package:civilhelp/features/labour/presentation/providers/labour_provider.dart' as labour_providers;
import 'package:civilhelp/features/payments/providers/payment_provider.dart' as payment_providers;
import 'package:civilhelp/features/sites/providers/site_provider.dart' as site_providers;

final activeSitesCountProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(site_providers.siteRepositoryProvider);
  final companyId = ref.watch(userCompanyIdProvider);

  return companyId.when(
    data: (id) => repository.getSitesByCompanyStream(id).map((sites) => sites.length),
    loading: () => Stream.value(0),
    error: (error, _) => Stream.error(error),
  );
});

final activeLabourCountProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(labour_providers.labourRepositoryProvider);
  final companyId = ref.watch(userCompanyIdProvider);

  return companyId.when(
    data: (id) => repository.getLabourByCompanyStream(id).map((labour) => labour.length),
    loading: () => Stream.value(0),
    error: (error, _) => Stream.error(error),
  );
});

final labourPresentTodayCountProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(attendance_providers.attendanceRepositoryProvider);
  final companyId = ref.watch(userCompanyIdProvider);

  return companyId.when(
    data: (id) => repository
        .getAttendanceForTodayStream(id)
        .map((attendance) => attendance.where((entry) => entry.status.toLowerCase() == 'present').length),
    loading: () => Stream.value(0),
    error: (error, _) => Stream.error(error),
  );
});

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

final outstandingAdvanceTotalProvider = StreamProvider<double>((ref) {
  final repository = ref.watch(advance_providers.advanceRepositoryProvider);
  final companyId = ref.watch(userCompanyIdProvider);

  return companyId.when(
    data: (id) => repository
        .getOutstandingAdvancesByCompanyStream(id)
        .map((advances) => advances.fold<double>(0.0, (sum, item) => sum + item.amount)),
    loading: () => Stream.value(0.0),
    error: (error, _) => Stream.error(error),
  );
});
