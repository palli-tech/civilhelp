import 'package:flutter/foundation.dart';
import 'package:civilhelp/features/advances/models/advance_model.dart';
import 'package:civilhelp/features/attendance/models/attendance_model.dart';
import 'package:civilhelp/features/labour/data/models/labour_model.dart';
import 'package:civilhelp/features/payments/models/payment_model.dart';
import 'package:civilhelp/features/sites/models/site_model.dart';
import 'package:civilhelp/features/payroll/models/payroll_period_model.dart';
import 'package:civilhelp/features/payroll/models/payroll_register_model.dart';
import 'package:civilhelp/features/payroll/models/payroll_summary_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firestore_path_service.dart';
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

  CollectionReference<Map<String, Object?>> _labourCollection(String companyId) {
    return _firestore.collection(FirestorePathService.labour(companyId));
  }

  CollectionReference<Map<String, Object?>> _attendanceCollection(String companyId) {
    return _firestore.collection(FirestorePathService.attendance(companyId));
  }

  CollectionReference<Map<String, Object?>> _advancesCollection(String companyId) {
    return _firestore.collection(FirestorePathService.advances(companyId));
  }

  CollectionReference<Map<String, Object?>> _paymentsCollection(String companyId) {
    return _firestore.collection(FirestorePathService.payments(companyId));
  }

  CollectionReference<Map<String, Object?>> _sitesCollection(String companyId) {
    return _firestore.collection(FirestorePathService.sites(companyId));
  }

  CollectionReference<Map<String, Object?>> _periodsCollection(String companyId) {
    return _firestore.collection('companies/$companyId/payrollPeriods');
  }

  CollectionReference<Map<String, Object?>> _registersCollection(String companyId) {
    return _firestore.collection('companies/$companyId/payrollRegisters');
  }

  CollectionReference<Map<String, Object?>> _summariesCollection(String companyId) {
    return _firestore.collection('companies/$companyId/payrollSummaries');
  }

  Future<LabourModel> _getLabour(String companyId, String labourId) async {
    if (_labourCache.containsKey(labourId)) {
      return _labourCache[labourId]!;
    }
    final doc = await _labourCollection(companyId).doc(labourId).get();
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

    // Fetch Attendances (non-deleted only)
    debugPrint('[DEBUG] ReportRepository: Executing attendance query');
    Query attQuery = _attendanceCollection(companyId)
        .where('labourId', isEqualTo: labourId)
        .where('isDeleted', isEqualTo: false)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate);
        
    if (filter.siteId != null && filter.siteId!.isNotEmpty) {
      attQuery = attQuery.where('siteId', isEqualTo: filter.siteId);
    }
    
    final attendanceSnap = await attQuery.get();
    debugPrint('[DEBUG] ReportRepository: Attendance query completed. Found ${attendanceSnap.docs.length}');

    final attendances = attendanceSnap.docs
        .map((doc) => AttendanceModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
        .toList();

    // Fetch Advances
    debugPrint('[DEBUG] ReportRepository: Executing advances query');
    Query advQuery = _advancesCollection(companyId)
        .where('labourId', isEqualTo: labourId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate);
        
    if (filter.siteId != null && filter.siteId!.isNotEmpty) {
      advQuery = advQuery.where('siteId', isEqualTo: filter.siteId);
    }
    
    final advancesSnap = await advQuery.get();
    debugPrint('[DEBUG] ReportRepository: Advances query completed. Found ${advancesSnap.docs.length}');

    final advances = advancesSnap.docs
        .map((doc) => AdvanceModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
        .toList();

    // Fetch Payments
    debugPrint('[DEBUG] ReportRepository: Executing payments query');
    Query payQuery = _paymentsCollection(companyId)
        .where('labourId', isEqualTo: labourId)
        .where('paymentDate', isGreaterThanOrEqualTo: startDate)
        .where('paymentDate', isLessThanOrEqualTo: endDate);
    
    final paymentsSnap = await payQuery.get();
    debugPrint('[DEBUG] ReportRepository: Payments query completed. Found ${paymentsSnap.docs.length}');

    final payments = paymentsSnap.docs
        .map((doc) => PaymentModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
        .toList();

    // Combine into events
    final List<WorkerLedgerEntry> entries = [];

    double totalEarned = 0.0;
    double totalAdvances = 0.0;
    double totalPayments = 0.0;
    
    // Process attendances
    for (final att in attendances) {
      final earned = att.earningsSnapshot;
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
      final date = pay.paidDate ?? pay.periodStart; 
      // Only netAmount (pay.amount) is a real debit against the ledger, since advances are debited when given
      totalPayments += pay.amount;
      entries.add(WorkerLedgerEntry(
        date: date,
        type: LedgerEntryType.payment,
        description: 'Payment Settled (Net)',
        credit: 0.0,
        debit: pay.amount,
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

    Query query = _attendanceCollection(filter.companyId)
        .where('isDeleted', isEqualTo: false) // exclude soft deleted
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate);

    if (filter.labourId != null && filter.labourId!.isNotEmpty) {
      query = query.where('labourId', isEqualTo: filter.labourId);
    }
    if (filter.siteId != null && filter.siteId!.isNotEmpty) {
      query = query.where('siteId', isEqualTo: filter.siteId);
    }

    final snap = await query.get();
    final attendances = snap.docs.map((doc) => AttendanceModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>)).toList();

    Map<String, AttendanceSummaryWorkerEntry> workerData = {};

    int totalPresent = 0;
    int totalHalfDay = 0;
    int totalAbsent = 0;

    for (final att in attendances) {
      final statusLower = att.status.toLowerCase();
      final isPresent = statusLower == 'present';
      final isHalfDay = statusLower == 'half-day';
      final isAbsent = statusLower == 'absent';

      if (isPresent) {
        totalPresent++;
      } else if (isHalfDay) {
        totalHalfDay++;
      } else if (isAbsent) {
        totalAbsent++;
      }

      final earned = att.earningsSnapshot;
      
      if (!workerData.containsKey(att.labourId)) {
        workerData[att.labourId] = AttendanceSummaryWorkerEntry(
          labourId: att.labourId,
          labourName: att.labourNameSnapshot,
          attendanceDays: 0,
          totalEarned: 0,
          averageDailyWage: 0,
          presentCount: 0,
          halfDayCount: 0,
          absentCount: 0,
        );
      }
      
      final current = workerData[att.labourId]!;
      workerData[att.labourId] = AttendanceSummaryWorkerEntry(
        labourId: current.labourId,
        labourName: current.labourName,
        attendanceDays: current.attendanceDays + 1,
        totalEarned: current.totalEarned + earned,
        averageDailyWage: 0, // Calculated later
        presentCount: current.presentCount + (isPresent ? 1 : 0),
        halfDayCount: current.halfDayCount + (isHalfDay ? 1 : 0),
        absentCount: current.absentCount + (isAbsent ? 1 : 0),
      );
    }

    List<AttendanceSummaryWorkerEntry> finalEntries = [];
    int globalAttendanceDays = 0;
    double globalTotalEarned = 0;

    for (var entry in workerData.values) {
      globalAttendanceDays += entry.attendanceDays;
      globalTotalEarned += entry.totalEarned;
      
      double avgWage = entry.attendanceDays > 0 ? entry.totalEarned / entry.attendanceDays : 0;
      
      finalEntries.add(AttendanceSummaryWorkerEntry(
        labourId: entry.labourId,
        labourName: entry.labourName,
        attendanceDays: entry.attendanceDays,
        totalEarned: entry.totalEarned,
        averageDailyWage: avgWage,
        presentCount: entry.presentCount,
        halfDayCount: entry.halfDayCount,
        absentCount: entry.absentCount,
      ));
    }

    finalEntries.sort((a, b) => b.attendanceDays.compareTo(a.attendanceDays));

    double globalAvgWage = globalAttendanceDays > 0 ? globalTotalEarned / globalAttendanceDays : 0;

    return AttendanceSummaryReportDTO(
      totalWorkers: workerData.length,
      totalAttendanceDays: globalAttendanceDays,
      totalEarned: globalTotalEarned,
      averageDailyWage: globalAvgWage,
      totalPresentCount: totalPresent,
      totalHalfDayCount: totalHalfDay,
      totalAbsentCount: totalAbsent,
      entries: finalEntries,
    );
  }

  Future<AdvanceReportDTO> getAdvanceReport(ReportFilter filter) async {
    final startDate = Timestamp.fromDate(filter.startDate);
    final endDate = Timestamp.fromDate(filter.endDate);

    Query query = _advancesCollection(filter.companyId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate);

    if (filter.labourId != null && filter.labourId!.isNotEmpty) {
      query = query.where('labourId', isEqualTo: filter.labourId);
    }
    if (filter.siteId != null && filter.siteId!.isNotEmpty) {
      query = query.where('siteId', isEqualTo: filter.siteId);
    }

    final snap = await query.get();
    final advances = snap.docs.map((doc) => AdvanceModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>)).toList();

    double totalAdvances = 0.0;
    double remainingUnapplied = 0.0;

    for (final adv in advances) {
      totalAdvances += adv.amount;
      remainingUnapplied += adv.remainingAmount;
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

    Query query = _paymentsCollection(filter.companyId)
        .where('paymentDate', isGreaterThanOrEqualTo: startDate)
        .where('paymentDate', isLessThanOrEqualTo: endDate);

    if (filter.labourId != null && filter.labourId!.isNotEmpty) {
      query = query.where('labourId', isEqualTo: filter.labourId);
    }

    final snap = await query.get();
    final payments = snap.docs.map((doc) => PaymentModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>)).toList();

    double totalPayments = 0.0;

    for (final pay in payments) {
      totalPayments += pay.amount;
    }

    return PaymentReportDTO(
      paymentCount: payments.length,
      totalPayments: totalPayments,
    );
  }

  Future<MonthlyPayrollReportDTO> getMonthlyPayrollReport(ReportFilter filter) async {
    final companyId = filter.companyId;
    final filterStart = filter.startDate;
    final filterEnd = filter.endDate;

    // Fetch all payroll periods for this company
    final periodsSnap = await _periodsCollection(companyId).get();
    final periods = periodsSnap.docs
        .map((doc) => PayrollPeriodModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
        .where((p) {
          // Check if the period overlaps with the filter range
          return (p.startDate.isBefore(filterEnd) || p.startDate.isAtSameMomentAs(filterEnd)) &&
                 (p.endDate.isAfter(filterStart) || p.endDate.isAtSameMomentAs(filterStart));
        })
        .toList();

    if (periods.isEmpty) {
      return const MonthlyPayrollReportDTO(entries: []);
    }

    final periodIds = periods.map((p) => p.id).toList();

    Map<String, List<PayrollRegisterModel>> registersByPeriod = {};
    Map<String, PayrollSummaryModel> summariesByPeriod = {};

    if (filter.labourId != null && filter.labourId!.isNotEmpty) {
      // Query registers for this worker
      for (final periodId in periodIds) {
        final regSnap = await _registersCollection(companyId)
            .where('periodId', isEqualTo: periodId)
            .where('labourId', isEqualTo: filter.labourId)
            .get();
        if (regSnap.docs.isNotEmpty) {
          registersByPeriod[periodId] = regSnap.docs
              .map((doc) => PayrollRegisterModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
              .toList();
        }
      }
    } else {
      // Fetch summaries for these periods
      for (final periodId in periodIds) {
        final sumSnap = await _summariesCollection(companyId).doc(periodId).get();
        if (sumSnap.exists) {
          summariesByPeriod[periodId] = PayrollSummaryModel.fromFirestore(sumSnap as DocumentSnapshot<Map<String, dynamic>>);
        }
      }
    }

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

    for (final period in periods) {
      initializeMonth(period.startDate);
      final key = getMonthKey(period.startDate);
      final current = monthlyData[key]!;

      double gross = 0.0;
      double deductions = 0.0;
      double net = 0.0;

      if (filter.labourId != null && filter.labourId!.isNotEmpty) {
        final regs = registersByPeriod[period.id] ?? [];
        for (final reg in regs) {
          gross += reg.grossEarnings;
          deductions += reg.advanceDeductions;
          net += reg.netPayable;
        }
      } else {
        final sum = summariesByPeriod[period.id];
        if (sum != null) {
          gross += sum.totalGross;
          deductions += sum.totalDeductions;
          net += sum.totalNetPaid;
        }
      }

      monthlyData[key] = MonthlyPayrollEntry(
        month: current.month,
        monthKey: current.monthKey,
        totalEarned: current.totalEarned + gross,
        totalAdvances: current.totalAdvances + deductions,
        totalPayments: current.totalPayments + net,
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

    // Fetch non-deleted unpaid attendances in range
    Query attQuery = _attendanceCollection(companyId)
        .where('isDeleted', isEqualTo: false)
        .where('paymentStatus', isEqualTo: 'unpaid')
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate);

    if (filter.labourId != null && filter.labourId!.isNotEmpty) {
      attQuery = attQuery.where('labourId', isEqualTo: filter.labourId);
    }
    if (filter.siteId != null && filter.siteId!.isNotEmpty) {
      attQuery = attQuery.where('siteId', isEqualTo: filter.siteId);
    }

    final attSnap = await attQuery.get();
    final attendances = attSnap.docs
        .map((doc) => AttendanceModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
        .toList();

    // Fetch outstanding advances (pending or partial) in range
    Query advQuery = _advancesCollection(companyId)
        .where('status', whereIn: ['pending', 'partial'])
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate);

    if (filter.labourId != null && filter.labourId!.isNotEmpty) {
      advQuery = advQuery.where('labourId', isEqualTo: filter.labourId);
    }
    if (filter.siteId != null && filter.siteId!.isNotEmpty) {
      advQuery = advQuery.where('siteId', isEqualTo: filter.siteId);
    }

    final advSnap = await advQuery.get();
    final advances = advSnap.docs
        .map((doc) => AdvanceModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
        .toList();

    Map<String, OutstandingBalanceWorkerEntry> workerData = {};

    void initializeWorker(String labourId, String workerName) {
      if (!workerData.containsKey(labourId)) {
        workerData[labourId] = OutstandingBalanceWorkerEntry(
          labourId: labourId,
          workerName: workerName,
          totalEarned: 0.0,
          totalAdvances: 0.0,
          totalPayments: 0.0,
          outstandingBalance: 0.0,
        );
      }
    }

    for (final att in attendances) {
      initializeWorker(att.labourId, att.labourNameSnapshot);
      final current = workerData[att.labourId]!;
      workerData[att.labourId] = OutstandingBalanceWorkerEntry(
        labourId: current.labourId,
        workerName: current.workerName,
        totalEarned: current.totalEarned + att.earningsSnapshot,
        totalAdvances: current.totalAdvances,
        totalPayments: current.totalPayments,
        outstandingBalance: 0.0,
      );
    }

    for (final adv in advances) {
      initializeWorker(adv.labourId, adv.labourName);
      final current = workerData[adv.labourId]!;
      workerData[adv.labourId] = OutstandingBalanceWorkerEntry(
        labourId: current.labourId,
        workerName: current.workerName,
        totalEarned: current.totalEarned,
        totalAdvances: current.totalAdvances + adv.remainingAmount,
        totalPayments: current.totalPayments,
        outstandingBalance: 0.0,
      );
    }

    List<OutstandingBalanceWorkerEntry> finalEntries = [];
    double totalOutstandingBalance = 0;

    for (var entry in workerData.values) {
      final outBalance = entry.totalEarned - entry.totalAdvances;
      totalOutstandingBalance += outBalance;
      
      finalEntries.add(OutstandingBalanceWorkerEntry(
        labourId: entry.labourId,
        workerName: entry.workerName,
        totalEarned: entry.totalEarned,
        totalAdvances: entry.totalAdvances,
        totalPayments: 0.0,
        outstandingBalance: outBalance,
      ));
    }

    finalEntries.sort((a, b) => b.outstandingBalance.compareTo(a.outstandingBalance));

    return OutstandingBalanceReportDTO(
      workerEntries: finalEntries,
      totalOutstandingBalance: totalOutstandingBalance,
    );
  }

  Future<SitePerformanceReportDTO> getSitePerformanceReport(ReportFilter filter) async {
    final companyId = filter.companyId;
    final startDate = Timestamp.fromDate(filter.startDate);
    final endDate = Timestamp.fromDate(filter.endDate);

    final sitesSnap = await _sitesCollection(companyId).get();
    final sites = sitesSnap.docs
        .map((doc) => SiteModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
        .toList();

    Query attQuery = _attendanceCollection(companyId)
        .where('isDeleted', isEqualTo: false)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate);

    final attSnap = await attQuery.get();
    final attendances = attSnap.docs
        .map((doc) => AttendanceModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
        .toList();

    Query advQuery = _advancesCollection(companyId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate);

    final advSnap = await advQuery.get();
    
    Query payQuery = _paymentsCollection(companyId)
        .where('paymentDate', isGreaterThanOrEqualTo: startDate)
        .where('paymentDate', isLessThanOrEqualTo: endDate);

    final paySnap = await payQuery.get();

    // Site Resolution Helper implementing Priority historical site attribution
    Future<String> resolveHistoricalSiteId({
      required String labourId,
      required String? payrollPeriodId,
      required DateTime date,
      required Map<String, dynamic> rawDocData,
    }) async {
      // Priority 1: siteIdSnapshot or siteId on payment/advance
      final directSiteId = rawDocData['siteId'] as String? ?? rawDocData['siteIdSnapshot'] as String?;
      if (directSiteId != null && directSiteId.isNotEmpty) {
        return directSiteId;
      }

      // Priority 2: payrollRegister.siteId for payroll-linked transactions
      if (payrollPeriodId != null && payrollPeriodId.isNotEmpty) {
        final regSnap = await _registersCollection(companyId).doc('${payrollPeriodId}_$labourId').get();
        if (regSnap.exists) {
          final regSiteId = regSnap.data()?['siteId'] as String? ?? regSnap.data()?['siteIdSnapshot'] as String?;
          if (regSiteId != null && regSiteId.isNotEmpty) {
            return regSiteId;
          }
        }
      }

      // Priority 3: Attendance records associated with the reporting period
      Query histAttQuery = _attendanceCollection(companyId)
          .where('labourId', isEqualTo: labourId)
          .where('isDeleted', isEqualTo: false);

      if (payrollPeriodId != null && payrollPeriodId.isNotEmpty) {
        histAttQuery = histAttQuery.where('payrollPeriodId', isEqualTo: payrollPeriodId);
      } else {
        final rangeStart = Timestamp.fromDate(date.subtract(const Duration(days: 15)));
        final rangeEnd = Timestamp.fromDate(date.add(const Duration(days: 15)));
        histAttQuery = histAttQuery.where('date', isGreaterThanOrEqualTo: rangeStart).where('date', isLessThanOrEqualTo: rangeEnd);
      }

      final histAttSnap = await histAttQuery.get();
      if (histAttSnap.docs.isNotEmpty) {
        final Map<String, int> siteCounts = {};
        for (final doc in histAttSnap.docs) {
          final data = doc.data() as Map<String, dynamic>?;
          final sId = data?['siteId'] as String? ?? '';
          if (sId.isNotEmpty) {
            siteCounts[sId] = (siteCounts[sId] ?? 0) + 1;
          }
        }
        if (siteCounts.isNotEmpty) {
          final sortedSites = siteCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          return sortedSites.first.key;
        }
      }

      // Fallback: get worker's current assignedSiteId
      try {
        final labour = await _getLabour(companyId, labourId);
        return labour.assignedSiteId;
      } catch (_) {
        return '';
      }
    }

    Map<String, SitePerformanceEntry> siteData = {};
    Map<String, Set<String>> siteWorkers = {};

    for (final site in sites) {
      siteData[site.id] = SitePerformanceEntry(
        siteId: site.id,
        siteName: site.name,
        workerCount: 0,
        attendanceDays: 0,
        totalEarned: 0,
        totalAdvances: 0,
        totalPayments: 0,
        outstandingBalance: 0,
      );
      siteWorkers[site.id] = {};
    }

    SitePerformanceEntry getOrCreateSiteEntry(String siteId, {String fallbackName = 'Unknown Site'}) {
      if (!siteData.containsKey(siteId)) {
        siteData[siteId] = SitePerformanceEntry(
          siteId: siteId,
          siteName: '$fallbackName ($siteId)',
          workerCount: 0,
          attendanceDays: 0,
          totalEarned: 0,
          totalAdvances: 0,
          totalPayments: 0,
          outstandingBalance: 0,
        );
        siteWorkers[siteId] = {};
      }
      return siteData[siteId]!;
    }

    for (final att in attendances) {
      if (att.siteId.isEmpty) continue;
      
      final current = getOrCreateSiteEntry(att.siteId);
      siteWorkers[att.siteId]!.add(att.labourId);
      
      siteData[att.siteId] = SitePerformanceEntry(
        siteId: current.siteId,
        siteName: current.siteName,
        workerCount: current.workerCount,
        attendanceDays: current.attendanceDays + 1,
        totalEarned: current.totalEarned + att.earningsSnapshot,
        totalAdvances: current.totalAdvances,
        totalPayments: current.totalPayments,
        outstandingBalance: 0,
      );
    }

    for (final doc in advSnap.docs) {
      final adv = AdvanceModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
      final rawData = doc.data() as Map<String, dynamic>;
      final targetSiteId = await resolveHistoricalSiteId(
        labourId: adv.labourId,
        payrollPeriodId: null,
        date: adv.date,
        rawDocData: rawData,
      );
      if (targetSiteId.isEmpty) continue;

      final current = getOrCreateSiteEntry(targetSiteId, fallbackName: adv.siteName.isNotEmpty ? adv.siteName : 'Unknown Site');
      siteData[targetSiteId] = SitePerformanceEntry(
        siteId: current.siteId,
        siteName: current.siteName,
        workerCount: current.workerCount,
        attendanceDays: current.attendanceDays,
        totalEarned: current.totalEarned,
        totalAdvances: current.totalAdvances + adv.amount,
        totalPayments: current.totalPayments,
        outstandingBalance: 0,
      );
    }

    for (final doc in paySnap.docs) {
      final pay = PaymentModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
      final rawData = doc.data() as Map<String, dynamic>;
      final targetSiteId = await resolveHistoricalSiteId(
        labourId: pay.labourId,
        payrollPeriodId: pay.payrollPeriodId,
        date: pay.paymentDate,
        rawDocData: rawData,
      );
      if (targetSiteId.isEmpty) continue;

      final current = getOrCreateSiteEntry(targetSiteId, fallbackName: pay.siteName.isNotEmpty ? pay.siteName : 'Unknown Site');
      siteData[targetSiteId] = SitePerformanceEntry(
        siteId: current.siteId,
        siteName: current.siteName,
        workerCount: current.workerCount,
        attendanceDays: current.attendanceDays,
        totalEarned: current.totalEarned,
        totalAdvances: current.totalAdvances,
        totalPayments: current.totalPayments + pay.amount,
        outstandingBalance: 0,
      );
    }

    List<SitePerformanceEntry> finalEntries = [];
    double globalEarned = 0;
    double globalAdvances = 0;
    double globalPayments = 0;
    double globalOutstanding = 0;
    
    Set<String> allWorkers = {};

    for (var entry in siteData.values) {
      final workers = siteWorkers[entry.siteId]!;
      allWorkers.addAll(workers);
      
      final outBalance = entry.totalEarned - entry.totalAdvances - entry.totalPayments;
      
      globalEarned += entry.totalEarned;
      globalAdvances += entry.totalAdvances;
      globalPayments += entry.totalPayments;
      globalOutstanding += outBalance;
      
      finalEntries.add(SitePerformanceEntry(
        siteId: entry.siteId,
        siteName: entry.siteName,
        workerCount: workers.length,
        attendanceDays: entry.attendanceDays,
        totalEarned: entry.totalEarned,
        totalAdvances: entry.totalAdvances,
        totalPayments: entry.totalPayments,
        outstandingBalance: outBalance,
      ));
    }

    finalEntries.sort((a, b) => b.outstandingBalance.compareTo(a.outstandingBalance));

    return SitePerformanceReportDTO(
      totalSites: siteData.length,
      totalWorkers: allWorkers.length,
      totalEarned: globalEarned,
      totalAdvances: globalAdvances,
      totalPayments: globalPayments,
      totalOutstanding: globalOutstanding,
      entries: finalEntries,
    );
  }
}
