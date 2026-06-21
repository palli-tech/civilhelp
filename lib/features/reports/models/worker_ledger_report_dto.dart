import 'worker_ledger_entry.dart';

class WorkerLedgerReportDTO {
  final List<WorkerLedgerEntry> entries;
  final double totalEarned;
  final double totalAdvances;
  final double totalPayments;
  final double outstandingBalance;

  const WorkerLedgerReportDTO({
    required this.entries,
    required this.totalEarned,
    required this.totalAdvances,
    required this.totalPayments,
    required this.outstandingBalance,
  });
}
