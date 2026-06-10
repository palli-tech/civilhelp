class AttendanceSummaryWorkerEntry {
  final String labourId;
  final String labourName;
  final int attendanceDays;
  final double totalEarned;
  final double averageDailyWage;

  const AttendanceSummaryWorkerEntry({
    required this.labourId,
    required this.labourName,
    required this.attendanceDays,
    required this.totalEarned,
    required this.averageDailyWage,
  });
}

class AttendanceSummaryReportDTO {
  final int totalWorkers;
  final int totalAttendanceDays;
  final double totalEarned;
  final double averageDailyWage;
  final List<AttendanceSummaryWorkerEntry> entries;

  const AttendanceSummaryReportDTO({
    required this.totalWorkers,
    required this.totalAttendanceDays,
    required this.totalEarned,
    required this.averageDailyWage,
    required this.entries,
  });
}

class AdvanceReportDTO {
  final int advanceCount;
  final double totalAdvances;
  final double remainingUnapplied;

  const AdvanceReportDTO({
    required this.advanceCount,
    required this.totalAdvances,
    required this.remainingUnapplied,
  });
}

class PaymentReportDTO {
  final int paymentCount;
  final double totalPayments;

  const PaymentReportDTO({
    required this.paymentCount,
    required this.totalPayments,
  });
}

class MonthlyPayrollEntry {
  final String month; // e.g. "Jan 2024"
  final DateTime monthKey; // for sorting
  final double totalEarned;
  final double totalAdvances;
  final double totalPayments;
  final double closingBalance;

  const MonthlyPayrollEntry({
    required this.month,
    required this.monthKey,
    required this.totalEarned,
    required this.totalAdvances,
    required this.totalPayments,
    required this.closingBalance,
  });
}

class MonthlyPayrollReportDTO {
  final List<MonthlyPayrollEntry> entries;

  const MonthlyPayrollReportDTO({
    required this.entries,
  });
}

class OutstandingBalanceWorkerEntry {
  final String labourId;
  final String workerName;
  final double totalEarned;
  final double totalAdvances;
  final double totalPayments;
  final double outstandingBalance;

  const OutstandingBalanceWorkerEntry({
    required this.labourId,
    required this.workerName,
    required this.totalEarned,
    required this.totalAdvances,
    required this.totalPayments,
    required this.outstandingBalance,
  });
}

class OutstandingBalanceReportDTO {
  final List<OutstandingBalanceWorkerEntry> workerEntries;
  final double totalOutstandingBalance;

  const OutstandingBalanceReportDTO({
    required this.workerEntries,
    required this.totalOutstandingBalance,
  });
}
