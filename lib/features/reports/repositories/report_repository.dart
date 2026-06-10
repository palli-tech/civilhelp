import 'package:flutter/foundation.dart';
import 'package:civilhelp/features/advances/models/advance_model.dart';
import 'package:civilhelp/features/attendance/models/attendance_model.dart';
import 'package:civilhelp/features/labour/data/models/labour_model.dart';
import 'package:civilhelp/features/payments/models/payment_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/report_filter.dart';
import '../models/worker_ledger_entry.dart';
import '../models/worker_ledger_report_dto.dart';
import '../models/report_dtos.dart';
import 'package:intl/intl.dart';

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
    debugPrint('[DEBUG] ReportRepository: getWorkerLedgerReport execution started');
    if (filter.labourId == null || filter.labourId!.isEmpty) {
      throw Exception('Worker Ledger Report requires a labourId');
    }

    final labourId = filter.labourId!;
    final companyId = filter.companyId;
    final startDate = Timestamp.fromDate(filter.startDate);
    final endDate = Timestamp.fromDate(filter.endDate);

    // Fetch Labour to get daily wage
    debugPrint('[DEBUG] ReportRepository: Fetching labour: $labourId');
    final labour = await _getLabour(labourId);
    final dailyWage = labour.dailyWage;
    debugPrint('[DEBUG] ReportRepository: Fetched labour successfully');

    // Fetch Attendances
    debugPrint('[DEBUG] ReportRepository: Executing attendance query');
    final attendanceSnap = await _firestore
        .collection('attendance')
        .where('companyId', isEqualTo: companyId)
        .where('labourId', isEqualTo: labourId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .get();
    debugPrint('[DEBUG] ReportRepository: Attendance query completed. Found ${attendanceSnap.docs.length}');

    final attendances = attendanceSnap.docs
        .map((doc) => AttendanceModel.fromFirestore(doc))
        .toList();

    // Fetch Advances
    debugPrint('[DEBUG] ReportRepository: Executing advances query');
    final advancesSnap = await _firestore
        .collection('advances')
        .where('companyId', isEqualTo: companyId)
        .where('labourId', isEqualTo: labourId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .get();
    debugPrint('[DEBUG] ReportRepository: Advances query completed. Found ${advancesSnap.docs.length}');

    final advances = advancesSnap.docs
        .map((doc) => AdvanceModel.fromFirestore(doc))
        .toList();

    // Fetch Payments
    debugPrint('[DEBUG] ReportRepository: Executing payments query');
    final paymentsSnap = await _firestore
        .collection('payments')
        .where('companyId', isEqualTo: companyId)
        .where('labourId', isEqualTo: labourId)
        .where('periodStart', isGreaterThanOrEqualTo: startDate) // Note: Using periodStart to align with payment timeline
        .where('periodStart', isLessThanOrEqualTo: endDate)
        .get();
    debugPrint('[DEBUG] ReportRepository: Payments query completed. Found ${paymentsSnap.docs.length}');

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

  Future<AttendanceSummaryReportDTO> getAttendanceSummaryReport(ReportFilter filter) async {
    final startDate = Timestamp.fromDate(filter.startDate);
    final endDate = Timestamp.fromDate(filter.endDate);

    Query query = _firestore.collection('attendance')
        .where('companyId', isEqualTo: filter.companyId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate);

    if (filter.labourId != null && filter.labourId!.isNotEmpty) {
      query = query.where('labourId', isEqualTo: filter.labourId);
    }

    final snap = await query.get();
    final attendances = snap.docs.map((doc) => AttendanceModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>)).toList();

    int presentCount = 0;
    int halfDayCount = 0;
    int absentCount = 0;
    double totalEarned = 0.0;

    for (final att in attendances) {
      if (att.status.toLowerCase() == 'present') {
        presentCount++;
      } else if (att.status.toLowerCase() == 'half day') {
        halfDayCount++;
      } else if (att.status.toLowerCase() == 'absent') {
        absentCount++;
      }
      
      final labour = await _getLabour(att.labourId);
      totalEarned += att.calculateEarnings(labour.dailyWage);
    }

    return AttendanceSummaryReportDTO(
      totalDays: attendances.length,
      presentCount: presentCount,
      halfDayCount: halfDayCount,
      absentCount: absentCount,
      totalEarned: totalEarned,
    );
  }

  Future<AdvanceReportDTO> getAdvanceReport(ReportFilter filter) async {
    final startDate = Timestamp.fromDate(filter.startDate);
    final endDate = Timestamp.fromDate(filter.endDate);

    Query query = _firestore.collection('advances')
        .where('companyId', isEqualTo: filter.companyId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate);

    if (filter.labourId != null && filter.labourId!.isNotEmpty) {
      query = query.where('labourId', isEqualTo: filter.labourId);
    }

    final snap = await query.get();
    final advances = snap.docs.map((doc) => AdvanceModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>)).toList();

    double totalAdvances = 0.0;
    double remainingUnapplied = 0.0;

    for (final adv in advances) {
      totalAdvances += adv.amount;
      remainingUnapplied += (adv.amount - adv.recoveredAmount);
    }

    return AdvanceReportDTO(
      advanceCount: advances.length,
      totalAdvances: totalAdvances,
      remainingUnapplied: remainingUnapplied,
    );
  }

  Future<PaymentReportDTO> getPaymentReport(ReportFilter filter) async {
    final startDate = Timestamp.fromDate(filter.startDate);
    final endDate = Timestamp.fromDate(filter.endDate);

    Query query = _firestore.collection('payments')
        .where('companyId', isEqualTo: filter.companyId)
        .where('periodStart', isGreaterThanOrEqualTo: startDate)
        .where('periodStart', isLessThanOrEqualTo: endDate);

    if (filter.labourId != null && filter.labourId!.isNotEmpty) {
      query = query.where('labourId', isEqualTo: filter.labourId);
    }

    final snap = await query.get();
    final payments = snap.docs.map((doc) => PaymentModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>)).toList();

    double totalPayments = 0.0;

    for (final pay in payments) {
      totalPayments += pay.netAmount;
    }

    return PaymentReportDTO(
      paymentCount: payments.length,
      totalPayments: totalPayments,
    );
  }

  Future<MonthlyPayrollReportDTO> getMonthlyPayrollReport(ReportFilter filter) async {
    // For this, we just reuse the data fetching logic without worker ledger specifics,
    // but grouped by month.
    
    final companyId = filter.companyId;
    final startDate = Timestamp.fromDate(filter.startDate);
    final endDate = Timestamp.fromDate(filter.endDate);

    Query attQuery = _firestore.collection('attendance')
        .where('companyId', isEqualTo: companyId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate);
        
    Query advQuery = _firestore.collection('advances')
        .where('companyId', isEqualTo: companyId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate);
        
    Query payQuery = _firestore.collection('payments')
        .where('companyId', isEqualTo: companyId)
        .where('periodStart', isGreaterThanOrEqualTo: startDate)
        .where('periodStart', isLessThanOrEqualTo: endDate);

    if (filter.labourId != null && filter.labourId!.isNotEmpty) {
      attQuery = attQuery.where('labourId', isEqualTo: filter.labourId);
      advQuery = advQuery.where('labourId', isEqualTo: filter.labourId);
      payQuery = payQuery.where('labourId', isEqualTo: filter.labourId);
    }

    final results = await Future.wait([
      attQuery.get(),
      advQuery.get(),
      payQuery.get(),
    ]);

    final attendances = results[0].docs.map((doc) => AttendanceModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>)).toList();
    final advances = results[1].docs.map((doc) => AdvanceModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>)).toList();
    final payments = results[2].docs.map((doc) => PaymentModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>)).toList();

    Map<String, MonthlyPayrollEntry> monthlyData = {};
    
    String getMonthKey(DateTime date) {
      return DateFormat('MMM yyyy').format(date);
    }
    
    DateTime getMonthStart(DateTime date) {
      return DateTime(date.year, date.month, 1);
    }

    void initializeMonth(DateTime date) {
      final key = getMonthKey(date);
      if (!monthlyData.containsKey(key)) {
        monthlyData[key] = MonthlyPayrollEntry(
          month: key,
          monthKey: getMonthStart(date),
          totalEarned: 0,
          totalAdvances: 0,
          totalPayments: 0,
          closingBalance: 0,
        );
      }
    }

    for (final att in attendances) {
      initializeMonth(att.date);
      final key = getMonthKey(att.date);
      final labour = await _getLabour(att.labourId);
      final earned = att.calculateEarnings(labour.dailyWage);
      
      final current = monthlyData[key]!;
      monthlyData[key] = MonthlyPayrollEntry(
        month: current.month,
        monthKey: current.monthKey,
        totalEarned: current.totalEarned + earned,
        totalAdvances: current.totalAdvances,
        totalPayments: current.totalPayments,
        closingBalance: 0,
      );
    }

    for (final adv in advances) {
      initializeMonth(adv.date);
      final key = getMonthKey(adv.date);
      
      final current = monthlyData[key]!;
      monthlyData[key] = MonthlyPayrollEntry(
        month: current.month,
        monthKey: current.monthKey,
        totalEarned: current.totalEarned,
        totalAdvances: current.totalAdvances + adv.amount,
        totalPayments: current.totalPayments,
        closingBalance: 0,
      );
    }

    for (final pay in payments) {
      final date = pay.paidDate ?? pay.periodStart;
      initializeMonth(date);
      final key = getMonthKey(date);
      
      final current = monthlyData[key]!;
      monthlyData[key] = MonthlyPayrollEntry(
        month: current.month,
        monthKey: current.monthKey,
        totalEarned: current.totalEarned,
        totalAdvances: current.totalAdvances,
        totalPayments: current.totalPayments + pay.netAmount,
        closingBalance: 0,
      );
    }

    final entries = monthlyData.values.toList();
    entries.sort((a, b) => a.monthKey.compareTo(b.monthKey));
    
    // Calculate closing balance sequentially
    double runningBalance = 0;
    List<MonthlyPayrollEntry> finalEntries = [];
    
    for (var entry in entries) {
      runningBalance += entry.totalEarned;
      runningBalance -= entry.totalAdvances;
      runningBalance -= entry.totalPayments;
      
      finalEntries.add(MonthlyPayrollEntry(
        month: entry.month,
        monthKey: entry.monthKey,
        totalEarned: entry.totalEarned,
        totalAdvances: entry.totalAdvances,
        totalPayments: entry.totalPayments,
        closingBalance: runningBalance,
      ));
    }

    return MonthlyPayrollReportDTO(entries: finalEntries);
  }

  Future<OutstandingBalanceReportDTO> getOutstandingBalanceReport(ReportFilter filter) async {
    final companyId = filter.companyId;
    final startDate = Timestamp.fromDate(filter.startDate);
    final endDate = Timestamp.fromDate(filter.endDate);

    Query attQuery = _firestore.collection('attendance')
        .where('companyId', isEqualTo: companyId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate);
        
    Query advQuery = _firestore.collection('advances')
        .where('companyId', isEqualTo: companyId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate);
        
    Query payQuery = _firestore.collection('payments')
        .where('companyId', isEqualTo: companyId)
        .where('periodStart', isGreaterThanOrEqualTo: startDate)
        .where('periodStart', isLessThanOrEqualTo: endDate);

    if (filter.labourId != null && filter.labourId!.isNotEmpty) {
      attQuery = attQuery.where('labourId', isEqualTo: filter.labourId);
      advQuery = advQuery.where('labourId', isEqualTo: filter.labourId);
      payQuery = payQuery.where('labourId', isEqualTo: filter.labourId);
    }

    final results = await Future.wait([
      attQuery.get(),
      advQuery.get(),
      payQuery.get(),
    ]);

    final attendances = results[0].docs.map((doc) => AttendanceModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>)).toList();
    final advances = results[1].docs.map((doc) => AdvanceModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>)).toList();
    final payments = results[2].docs.map((doc) => PaymentModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>)).toList();

    Map<String, OutstandingBalanceWorkerEntry> workerData = {};

    Future<void> initializeWorker(String labourId) async {
      if (!workerData.containsKey(labourId)) {
        final labour = await _getLabour(labourId);
        workerData[labourId] = OutstandingBalanceWorkerEntry(
          labourId: labourId,
          workerName: labour.fullName,
          totalEarned: 0,
          totalAdvances: 0,
          totalPayments: 0,
          outstandingBalance: 0,
        );
      }
    }

    for (final att in attendances) {
      await initializeWorker(att.labourId);
      final labour = await _getLabour(att.labourId);
      final earned = att.calculateEarnings(labour.dailyWage);
      
      final current = workerData[att.labourId]!;
      workerData[att.labourId] = OutstandingBalanceWorkerEntry(
        labourId: current.labourId,
        workerName: current.workerName,
        totalEarned: current.totalEarned + earned,
        totalAdvances: current.totalAdvances,
        totalPayments: current.totalPayments,
        outstandingBalance: 0,
      );
    }

    for (final adv in advances) {
      await initializeWorker(adv.labourId);
      final current = workerData[adv.labourId]!;
      workerData[adv.labourId] = OutstandingBalanceWorkerEntry(
        labourId: current.labourId,
        workerName: current.workerName,
        totalEarned: current.totalEarned,
        totalAdvances: current.totalAdvances + adv.amount,
        totalPayments: current.totalPayments,
        outstandingBalance: 0,
      );
    }

    for (final pay in payments) {
      await initializeWorker(pay.labourId);
      final current = workerData[pay.labourId]!;
      workerData[pay.labourId] = OutstandingBalanceWorkerEntry(
        labourId: current.labourId,
        workerName: current.workerName,
        totalEarned: current.totalEarned,
        totalAdvances: current.totalAdvances,
        totalPayments: current.totalPayments + pay.netAmount,
        outstandingBalance: 0,
      );
    }

    List<OutstandingBalanceWorkerEntry> finalEntries = [];
    double totalOutstandingBalance = 0;

    for (var entry in workerData.values) {
      final outBalance = entry.totalEarned - entry.totalAdvances - entry.totalPayments;
      totalOutstandingBalance += outBalance;
      
      finalEntries.add(OutstandingBalanceWorkerEntry(
        labourId: entry.labourId,
        workerName: entry.workerName,
        totalEarned: entry.totalEarned,
        totalAdvances: entry.totalAdvances,
        totalPayments: entry.totalPayments,
        outstandingBalance: outBalance,
      ));
    }

    finalEntries.sort((a, b) => b.outstandingBalance.compareTo(a.outstandingBalance));

    return OutstandingBalanceReportDTO(
      workerEntries: finalEntries,
      totalOutstandingBalance: totalOutstandingBalance,
    );
  }
}
