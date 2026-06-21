import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report_filter.dart';
import '../models/worker_ledger_report_dto.dart';
import '../models/report_dtos.dart';
import '../repositories/report_repository.dart';

final reportRepositoryProvider = Provider.autoDispose<ReportRepository>((ref) {
  debugPrint('[DEBUG] reportRepositoryProvider: instantiated');
  return ReportRepository();
});

final workerLedgerReportProvider = FutureProvider.autoDispose.family<WorkerLedgerReportDTO, ReportFilter>((ref, filter) async {
  debugPrint('[DEBUG] workerLedgerReportProvider: execution started');
  final repository = ref.watch(reportRepositoryProvider);
  return await repository.getWorkerLedgerReport(filter);
});

final attendanceSummaryReportProvider = FutureProvider.autoDispose.family<AttendanceSummaryReportDTO, ReportFilter>((ref, filter) async {
  final repository = ref.watch(reportRepositoryProvider);
  return await repository.getAttendanceSummaryReport(filter);
});

final advanceReportProvider = FutureProvider.autoDispose.family<AdvanceReportDTO, ReportFilter>((ref, filter) async {
  final repository = ref.watch(reportRepositoryProvider);
  return await repository.getAdvanceReport(filter);
});

final paymentReportProvider = FutureProvider.autoDispose.family<PaymentReportDTO, ReportFilter>((ref, filter) async {
  final repository = ref.watch(reportRepositoryProvider);
  return await repository.getPaymentReport(filter);
});

final monthlyPayrollReportProvider = FutureProvider.autoDispose.family<MonthlyPayrollReportDTO, ReportFilter>((ref, filter) async {
  final repository = ref.watch(reportRepositoryProvider);
  return await repository.getMonthlyPayrollReport(filter);
});

final outstandingBalanceReportProvider = FutureProvider.autoDispose.family<OutstandingBalanceReportDTO, ReportFilter>((ref, filter) async {
  final repository = ref.watch(reportRepositoryProvider);
  return await repository.getOutstandingBalanceReport(filter);
});

final sitePerformanceReportProvider = FutureProvider.autoDispose.family<SitePerformanceReportDTO, ReportFilter>((ref, filter) async {
  final repository = ref.watch(reportRepositoryProvider);
  return await repository.getSitePerformanceReport(filter);
});
