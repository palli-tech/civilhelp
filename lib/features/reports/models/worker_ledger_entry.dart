enum LedgerEntryType { attendance, advance, payment }

class WorkerLedgerEntry {
  final DateTime date;
  final LedgerEntryType type;
  final String description;
  final double credit; // Increase payable balance
  final double debit;  // Decrease payable balance
  final double runningBalance;

  const WorkerLedgerEntry({
    required this.date,
    required this.type,
    required this.description,
    required this.credit,
    required this.debit,
    required this.runningBalance,
  });
}
