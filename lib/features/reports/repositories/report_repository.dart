import 'package:civilhelp/features/advances/models/advance_model.dart';
import 'package:civilhelp/features/attendance/models/attendance_model.dart';
import 'package:civilhelp/features/labour/data/models/labour_model.dart';
import 'package:civilhelp/features/payments/models/payment_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/report_filter.dart';
import '../models/worker_ledger_entry.dart';
import '../models/worker_ledger_report_dto.dart';

class ReportRepository {
  final FirebaseFirestore _firestore;
  final Map<String, LabourModel> _labourCache = {};

  ReportRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<LabourModel> _getLabour(String labourId) async {
    if (_labourCache.containsKey(labourId)) {
      return _labourCache[labourId]!;
    }
    final doc = await _firestore.collection('labour').doc(labourId).get();
    if (!doc.exists) {
      throw Exception('Labour not found: $labourId');
    }
    final labour = LabourModel.fromFirestore(doc);
    _labourCache[labourId] = labour;
    return labour;
  }

  Future<WorkerLedgerReportDTO> getWorkerLedgerReport(ReportFilter filter) async {
    if (filter.labourId == null || filter.labourId!.isEmpty) {
      throw Exception('Worker Ledger Report requires a labourId');
    }

    final labourId = filter.labourId!;
    final companyId = filter.companyId;
    final startDate = Timestamp.fromDate(filter.startDate);
    final endDate = Timestamp.fromDate(filter.endDate);

    // Fetch Labour to get daily wage
    final labour = await _getLabour(labourId);
    final dailyWage = labour.dailyWage;

    // Fetch Attendances
    final attendanceSnap = await _firestore
        .collection('attendance')
        .where('companyId', isEqualTo: companyId)
        .where('labourId', isEqualTo: labourId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .get();

    final attendances = attendanceSnap.docs
        .map((doc) => AttendanceModel.fromFirestore(doc))
        .toList();

    // Fetch Advances
    final advancesSnap = await _firestore
        .collection('advances')
        .where('companyId', isEqualTo: companyId)
        .where('labourId', isEqualTo: labourId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .get();

    final advances = advancesSnap.docs
        .map((doc) => AdvanceModel.fromFirestore(doc))
        .toList();

    // Fetch Payments
    final paymentsSnap = await _firestore
        .collection('payments')
        .where('companyId', isEqualTo: companyId)
        .where('labourId', isEqualTo: labourId)
        .where('periodStart', isGreaterThanOrEqualTo: startDate) // Note: Using periodStart to align with payment timeline
        .where('periodStart', isLessThanOrEqualTo: endDate)
        .get();

    final payments = paymentsSnap.docs
        .map((doc) => PaymentModel.fromFirestore(doc))
        .toList();

    // Combine into events
    final List<WorkerLedgerEntry> entries = [];

    double totalEarned = 0.0;
    double totalAdvances = 0.0;
    double totalPayments = 0.0;
    
    // Sort all raw data by their relevant dates
    
    // Process attendances
    for (final att in attendances) {
      final earned = att.calculateEarnings(dailyWage);
      if (earned > 0) {
        totalEarned += earned;
        entries.add(WorkerLedgerEntry(
          date: att.date,
          type: LedgerEntryType.attendance,
          description: 'Attendance (${att.status})',
          credit: earned,
          debit: 0.0,
          runningBalance: 0.0, // Calculated later
        ));
      }
    }

    // Process advances
    for (final adv in advances) {
      totalAdvances += adv.amount;
      entries.add(WorkerLedgerEntry(
        date: adv.date,
        type: LedgerEntryType.advance,
        description: 'Advance Given: ${adv.reason}',
        credit: 0.0,
        debit: adv.amount,
        runningBalance: 0.0, // Calculated later
      ));
    }

    // Process payments
    for (final pay in payments) {
      // Use paidDate if available, otherwise periodStart or createdAt
      final date = pay.paidDate ?? pay.periodStart; 
      // Only netAmount is a real debit against the ledger, since advances are debited when given
      totalPayments += pay.netAmount;
      entries.add(WorkerLedgerEntry(
        date: date,
        type: LedgerEntryType.payment,
        description: 'Payment Settled (Net)',
        credit: 0.0,
        debit: pay.netAmount,
        runningBalance: 0.0, // Calculated later
      ));
    }

    // Sort entries chronologically
    entries.sort((a, b) => a.date.compareTo(b.date));

    // Calculate running balance
    double currentBalance = 0.0;
    final List<WorkerLedgerEntry> finalEntries = [];

    for (final entry in entries) {
      currentBalance += entry.credit;
      currentBalance -= entry.debit;
      
      finalEntries.add(WorkerLedgerEntry(
        date: entry.date,
        type: entry.type,
        description: entry.description,
        credit: entry.credit,
        debit: entry.debit,
        runningBalance: currentBalance,
      ));
    }

    return WorkerLedgerReportDTO(
      entries: finalEntries.reversed.toList(), // Most recent first for UI
      totalEarned: totalEarned,
      totalAdvances: totalAdvances,
      totalPayments: totalPayments,
      outstandingBalance: currentBalance,
    );
  }
}
