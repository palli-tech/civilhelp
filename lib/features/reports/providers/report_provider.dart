import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report_filter.dart';
import '../models/worker_ledger_report_dto.dart';
import '../repositories/report_repository.dart';

final reportRepositoryProvider = Provider.autoDispose<ReportRepository>((ref) {
  return ReportRepository();
});

final workerLedgerReportProvider = FutureProvider.autoDispose.family<WorkerLedgerReportDTO, ReportFilter>((ref, filter) async {
  final repository = ref.watch(reportRepositoryProvider);
  return repository.getWorkerLedgerReport(filter);
});
