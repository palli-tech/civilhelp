class AttendanceSummaryReportDTO {
  final int totalDays;
  final int presentCount;
  final int halfDayCount;
  final int absentCount;
  final double totalEarned;

  const AttendanceSummaryReportDTO({
    required this.totalDays,
    required this.presentCount,
    required this.halfDayCount,
    required this.absentCount,
    required this.totalEarned,
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
