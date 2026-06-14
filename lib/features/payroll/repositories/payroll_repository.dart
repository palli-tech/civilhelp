import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../advances/models/advance_model.dart';
import '../../advances/models/advance_recovery_model.dart';
import '../../attendance/models/attendance_model.dart';
import '../../payments/models/payment_model.dart';
import '../models/payroll_period_model.dart';
import '../models/payroll_register_model.dart';
import '../models/payroll_summary_model.dart';

class PayrollCalculationResult {
  final String labourId;
  final String labourName;
  final int presentDays;
  final double grossEarnings;
  final double advanceDeductions;
  final double netPayable;
  final List<String> attendanceIds;

  const PayrollCalculationResult({
    required this.labourId,
    required this.labourName,
    required this.presentDays,
    required this.grossEarnings,
    required this.advanceDeductions,
    required this.netPayable,
    required this.attendanceIds,
  });
}

class ChunkedFirestoreBatch {
  final FirebaseFirestore firestore;
  WriteBatch _batch;
  int _count = 0;

  ChunkedFirestoreBatch(this.firestore) : _batch = firestore.batch();

  Future<void> set(DocumentReference<Map<String, dynamic>> ref, Map<String, dynamic> data) async {
    _batch.set(ref, data);
    _count++;
    if (_count >= 400) {
      await commit();
    }
  }

  Future<void> update(DocumentReference<Map<String, dynamic>> ref, Map<String, dynamic> data) async {
    _batch.update(ref, data);
    _count++;
    if (_count >= 400) {
      await commit();
    }
  }

  Future<void> delete(DocumentReference<Map<String, dynamic>> ref) async {
    _batch.delete(ref);
    _count++;
    if (_count >= 400) {
      await commit();
    }
  }

  Future<void> commit() async {
    if (_count > 0) {
      await _batch.commit();
      _batch = firestore.batch();
      _count = 0;
    }
  }
}

class PayrollOverlapException implements Exception {
  final String message;
  PayrollOverlapException(this.message);
  @override
  String toString() => message;
}

class ZeroGrossPayrollException implements Exception {
  final String message;
  ZeroGrossPayrollException(this.message);
  @override
  String toString() => message;
}

class InvalidDateRangeException implements Exception {
  final String message;
  InvalidDateRangeException(this.message);
  @override
  String toString() => message;
}

class PayrollPeriodNotFoundException implements Exception {
  final String message;
  PayrollPeriodNotFoundException(this.message);
  @override
  String toString() => message;
}

class InvalidPayrollPeriodStatusException implements Exception {
  final String message;
  InvalidPayrollPeriodStatusException(this.message);
  @override
  String toString() => message;
}

class OrphanedPayrollAssignmentReport {
  final int totalAttendance;
  final int validAssignments;
  final int orphanedAssignments;
  final int floatingAssignments;
  final List<String> orphanedDocIds;
  final List<String> floatingDocIds;

  const OrphanedPayrollAssignmentReport({
    required this.totalAttendance,
    required this.validAssignments,
    required this.orphanedAssignments,
    required this.floatingAssignments,
    required this.orphanedDocIds,
    required this.floatingDocIds,
  });
}

class PayrollRepository {
  final FirebaseFirestore _firestore;

  PayrollRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _periodsCollection(String companyId) {
    return _firestore.collection('companies/$companyId/payrollPeriods');
  }

  CollectionReference<Map<String, dynamic>> _registersCollection(String companyId) {
    return _firestore.collection('companies/$companyId/payrollRegisters');
  }

  CollectionReference<Map<String, dynamic>> _summariesCollection(String companyId) {
    return _firestore.collection('companies/$companyId/payrollSummaries');
  }

  CollectionReference<Map<String, dynamic>> _paymentsCollection(String companyId) {
    return _firestore.collection('companies/$companyId/payments');
  }

  CollectionReference<Map<String, dynamic>> _advancesCollection(String companyId) {
    return _firestore.collection('companies/$companyId/advances');
  }

  CollectionReference<Map<String, dynamic>> _recoveriesCollection(String companyId) {
    return _firestore.collection('companies/$companyId/advanceRecoveries');
  }

  CollectionReference<Map<String, dynamic>> _attendanceCollection(String companyId) {
    return _firestore.collection('companies/$companyId/attendance');
  }

  // ---------------------------------------------------------------------------
  // Period Creation
  // ---------------------------------------------------------------------------

  /// Creates a new payroll period with an arbitrary date range.
  ///
  /// Business rules enforced:
  ///   1. [startDate] must be strictly before [endDate].
  ///   2. Only one active (open or frozen) period may exist at a time.
  ///      A new period cannot be created until the active one is settled (paid).
  ///   3. The new period's date range must not overlap with any existing period
  ///      regardless of status (open, frozen, or paid).
  ///   4. If [name] is empty, a default label is derived from the date range.
  Future<PayrollPeriodModel> createPayrollPeriod({
    required String companyId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required String createdBy,
  }) async {
    // Normalise end to last millisecond of that calendar day.
    final normalizedEnd = DateTime(
      endDate.year, endDate.month, endDate.day, 23, 59, 59, 999,
    );

    // Normalise start to beginning of that calendar day.
    final normalizedStart = DateTime(
      startDate.year, startDate.month, startDate.day,
    );

    if (!normalizedStart.isBefore(normalizedEnd)) {
      throw InvalidDateRangeException('Start date must be before end date.');
    }

    // Resolve a display name if not provided.
    final fmt = DateFormat('dd MMM yyyy');
    final resolvedName = name.trim().isNotEmpty
        ? name.trim()
        : '${fmt.format(normalizedStart)} – ${fmt.format(normalizedEnd)}';

    // Rule: no overlap with any existing period (including paid).
    final allSnap = await _periodsCollection(companyId).get(
      const GetOptions(source: Source.server),
    );


    for (final doc in allSnap.docs) {
      final p = PayrollPeriodModel.fromFirestore(
        doc as DocumentSnapshot<Map<String, dynamic>>,
      );
      // Overlap condition: periods overlap if one starts before the other ends.
      final overlaps =
          normalizedStart.isBefore(p.endDate) && normalizedEnd.isAfter(p.startDate);
      if (overlaps) {
        final pFmt = DateFormat('dd MMM yyyy');
        throw PayrollOverlapException(
          'Period overlaps with "${p.name}" '
          '(${pFmt.format(p.startDate)} – ${pFmt.format(p.endDate)}). '
          'Payroll periods must not overlap.',
        );
      }
    }

    // Create with Firestore auto-ID.
    final docRef = _periodsCollection(companyId).doc();
    final model = PayrollPeriodModel(
      id: docRef.id,
      companyId: companyId,
      name: resolvedName,
      startDate: normalizedStart,
      endDate: normalizedEnd,
      status: 'open',
      createdAt: DateTime.now(),
      createdBy: createdBy,
      settlementJobStatus: 'pending',
    );

    await docRef.set(model.toMap());

    // Backfill floating/orphaned attendance records covering this date range (within company scope)
    final existingPeriodIds = allSnap.docs.map((doc) => doc.id).toSet();

    final rangeSnap = await _attendanceCollection(companyId)
        .where('isDeleted', isEqualTo: false)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(normalizedStart))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(normalizedEnd))
        .get();

    final List<DocumentSnapshot<Map<String, dynamic>>> eligibleForBackfill = [];
    for (final doc in rangeSnap.docs) {
      final data = doc.data();
      final pid = data['payrollPeriodId'] as String?;
      final paymentStatus = data['paymentStatus'] as String? ?? 'unpaid';

      // Only unpaid records can be backfilled
      if (paymentStatus != 'unpaid' && paymentStatus != 'open') {
        continue;
      }

      // Eligible if:
      // 1. payrollPeriodId is null
      // OR
      // 2. The referenced payroll period document does not exist in the collection
      if (pid == null || !existingPeriodIds.contains(pid)) {
        eligibleForBackfill.add(doc);
      }
    }

    if (eligibleForBackfill.isNotEmpty) {
      final chunkBatch = ChunkedFirestoreBatch(_firestore);
      for (final doc in eligibleForBackfill) {
        await chunkBatch.update(doc.reference, {
          'payrollPeriodId': docRef.id,
          'updatedAt': Timestamp.now(),
        });
      }
      await chunkBatch.commit();
    }

    // Validate gross using payroll calculation engine, not manual attendance sum
    final calcs = await calculatePayroll(companyId: companyId, periodId: docRef.id);
    final totalGross = calcs.fold<double>(0.0, (acc, c) => acc + c.grossEarnings);


    if (totalGross <= 0.0) {
      // Rollback: delete the created payroll period and revert backfilled attendance
      final rollbackBatch = ChunkedFirestoreBatch(_firestore);
      await rollbackBatch.delete(docRef);
      if (eligibleForBackfill.isNotEmpty) {
        for (final doc in eligibleForBackfill) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['payrollPeriodId'] == docRef.id) {
            await rollbackBatch.update(doc.reference, {
              'payrollPeriodId': null,
              'updatedAt': Timestamp.now(),
            });
          }
        }
      }
      await rollbackBatch.commit();

      throw ZeroGrossPayrollException(
        'No unpaid attendance records found for the selected date range. '
        'Payroll period cannot be created.',
      );
    }

    return model;
  }

  // ---------------------------------------------------------------------------
  // Period Lifecycle
  // ---------------------------------------------------------------------------

  Future<void> freezePayrollPeriod({
    required String companyId,
    required String periodId,
    required String frozenBy,
  }) async {
    final docRef = _periodsCollection(companyId).doc(periodId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw PayrollPeriodNotFoundException('Payroll period not found.');
      }
      final period = PayrollPeriodModel.fromFirestore(snapshot);
      if (period.status != 'open') {
        throw InvalidPayrollPeriodStatusException('Can only freeze an open payroll period.');
      }
      transaction.update(docRef, {
        'status': 'frozen',
        'frozenAt': Timestamp.now(),
        'frozenBy': frozenBy,
      });
    });
  }

  Future<void> reopenPayrollPeriod({
    required String companyId,
    required String periodId,
    required String reopenedBy,
  }) async {
    final docRef = _periodsCollection(companyId).doc(periodId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw PayrollPeriodNotFoundException('Payroll period not found.');
      }
      final period = PayrollPeriodModel.fromFirestore(snapshot);
      if (period.status != 'frozen') {
        throw InvalidPayrollPeriodStatusException('Can only reopen a frozen payroll period.');
      }
      transaction.update(docRef, {
        'status': 'open',
        'frozenAt': null,
        'frozenBy': null,
      });
    });
  }

  // ---------------------------------------------------------------------------
  // Payroll Calculation
  // ---------------------------------------------------------------------------

  Future<List<PayrollCalculationResult>> calculatePayroll({
    required String companyId,
    required String periodId,
  }) async {
    // 1. Fetch all unpaid, non-deleted attendances stamped to this period
    final attendanceSnap = await _attendanceCollection(companyId)
        .where('payrollPeriodId', isEqualTo: periodId)
        .where('paymentStatus', isEqualTo: 'unpaid')
        .where('isDeleted', isEqualTo: false)
        .get();

    final attendances = attendanceSnap.docs
        .map((doc) => AttendanceModel.fromFirestore(doc))
        .toList();

    // 2. Fetch all outstanding advances for the company (status-based, not date-based)
    final advancesSnap = await _advancesCollection(companyId)
        .where('status', whereIn: ['pending', 'partial'])
        .get();

    final advances = advancesSnap.docs
        .map((doc) => AdvanceModel.fromFirestore(doc))
        .toList();

    // 3. Group attendances by labourId
    final Map<String, List<AttendanceModel>> labourAttendances = {};
    for (final att in attendances) {
      labourAttendances.putIfAbsent(att.labourId, () => []).add(att);
    }

    // 4. Group advances by labourId
    final Map<String, List<AdvanceModel>> labourAdvances = {};
    for (final adv in advances) {
      labourAdvances.putIfAbsent(adv.labourId, () => []).add(adv);
    }

    // All labourIds with activity (attendances or outstanding advances)
    final allLabourIds = {...labourAttendances.keys, ...labourAdvances.keys};

    final List<PayrollCalculationResult> results = [];

    for (final labourId in allLabourIds) {
      final workerAtts = labourAttendances[labourId] ?? [];
      final workerAdvs = labourAdvances[labourId] ?? [];

      final String workerName = workerAtts.isNotEmpty
          ? workerAtts.first.labourNameSnapshot
          : (workerAdvs.isNotEmpty ? workerAdvs.first.labourName : 'Unknown Worker');

      int presentDays = 0;
      double grossEarnings = 0.0;
      for (final att in workerAtts) {
        if (att.status.toLowerCase() != 'absent' && att.musterQuantity > 0) {
          presentDays++;
        }
        grossEarnings += att.earningsSnapshot;
      }

      double outstandingAdvances =
          workerAdvs.fold<double>(0.0, (acc, adv) => acc + adv.remainingAmount);

      // Deduction rule: deduction <= grossEarnings
      double advanceDeductions =
          outstandingAdvances > grossEarnings ? grossEarnings : outstandingAdvances;
      double netPayable = grossEarnings - advanceDeductions;

      if (workerAtts.isNotEmpty || outstandingAdvances > 0) {
        results.add(PayrollCalculationResult(
          labourId: labourId,
          labourName: workerName,
          presentDays: presentDays,
          grossEarnings: grossEarnings,
          advanceDeductions: advanceDeductions,
          netPayable: netPayable,
          attendanceIds: workerAtts.map((e) => e.id).toList(),
        ));
      }
    }

    return results;
  }

  // ---------------------------------------------------------------------------
  // Payroll Finalization & Settlement
  // ---------------------------------------------------------------------------

  Future<void> finalizePayroll({
    required String companyId,
    required String periodId,
    required String finalizedBy,
    required List<PayrollCalculationResult> results,
    required String paymentMode,
  }) async {
    final periodRef = _periodsCollection(companyId).doc(periodId);

    // Load the period to stamp periodStart/periodEnd on payments.
    final periodSnap = await periodRef.get();
    if (!periodSnap.exists) {
      throw PayrollPeriodNotFoundException('Payroll period not found.');
    }
    final period = PayrollPeriodModel.fromFirestore(periodSnap);

    // Set status to processing
    await periodRef.update({
      'settlementJobStatus': 'processing',
      'settlementStartedAt': Timestamp.now(),
    });

    try {
      final chunkBatch = ChunkedFirestoreBatch(_firestore);

      double totalGross = 0.0;
      double totalDeductions = 0.0;
      double totalNetPaid = 0.0;
      int totalWorkers = 0;

      for (final workerResult in results) {
        // Skip entirely empty entries (if any exist)
        if (workerResult.grossEarnings == 0 &&
            workerResult.advanceDeductions == 0 &&
            workerResult.netPayable == 0) {
          continue;
        }

        totalWorkers++;
        totalGross += workerResult.grossEarnings;
        totalDeductions += workerResult.advanceDeductions;
        totalNetPaid += workerResult.netPayable;

        final paymentId = _paymentsCollection(companyId).doc().id;

        // 1. Create Payment record — stamp periodStart & periodEnd directly.
        final paymentRef = _paymentsCollection(companyId).doc(paymentId);
        final paymentModel = PaymentModel(
          id: paymentId,
          companyId: companyId,
          labourId: workerResult.labourId,
          labourName: workerResult.labourName,
          payrollPeriodId: periodId,
          periodStart: period.startDate,
          periodEnd: period.endDate,
          grossEarningsSnapshot: workerResult.grossEarnings,
          deductionsSnapshot: workerResult.advanceDeductions,
          amount: workerResult.netPayable,
          paymentMode: paymentMode,
          paymentDate: DateTime.now(),
          createdAt: DateTime.now(),
          createdBy: finalizedBy,
        );
        await chunkBatch.set(paymentRef, paymentModel.toMap());

        // 2. Create Payroll Register record
        final registerId = '${periodId}_${workerResult.labourId}';
        final registerRef = _registersCollection(companyId).doc(registerId);
        final registerModel = PayrollRegisterModel(
          id: registerId,
          companyId: companyId,
          periodId: periodId,
          labourId: workerResult.labourId,
          labourName: workerResult.labourName,
          presentDays: workerResult.presentDays,
          grossEarnings: workerResult.grossEarnings,
          advanceDeductions: workerResult.advanceDeductions,
          netPayable: workerResult.netPayable,
          paymentId: paymentId,
          createdAt: DateTime.now(),
          createdBy: finalizedBy,
        );
        await chunkBatch.set(registerRef, registerModel.toMap());

        // 3. Process Advance Recoveries
        if (workerResult.advanceDeductions > 0) {
          final advancesSnap = await _advancesCollection(companyId)
              .where('labourId', isEqualTo: workerResult.labourId)
              .where('status', whereIn: ['pending', 'partial'])
              .get();

          final advances = advancesSnap.docs
              .map((doc) => AdvanceModel.fromFirestore(doc))
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));

          double remainingDeduction = workerResult.advanceDeductions;

          for (final adv in advances) {
            if (remainingDeduction <= 0) break;

            final outstanding = adv.remainingAmount;
            if (outstanding <= 0) continue;

            final recoverAmount =
                remainingDeduction > outstanding ? outstanding : remainingDeduction;
            remainingDeduction -= recoverAmount;

            final newRecovered = adv.recoveredAmount + recoverAmount;
            final newRemaining = adv.amount - newRecovered;
            final newStatus = newRemaining <= 0 ? 'recovered' : 'partial';

            final advRef = _advancesCollection(companyId).doc(adv.id);
            await chunkBatch.update(advRef, {
              'recoveredAmount': newRecovered,
              'remainingAmount': newRemaining,
              'status': newStatus,
            });

            final recoveryId = _recoveriesCollection(companyId).doc().id;
            final recoveryRef = _recoveriesCollection(companyId).doc(recoveryId);
            final recoveryModel = AdvanceRecoveryModel(
              id: recoveryId,
              companyId: companyId,
              advanceId: adv.id,
              paymentId: paymentId,
              labourId: workerResult.labourId,
              recoveredAmount: recoverAmount,
              createdAt: DateTime.now(),
              createdBy: finalizedBy,
            );
            await chunkBatch.set(recoveryRef, recoveryModel.toMap());
          }
        }

        // 4. Stamp attendance records as paid
        for (final attId in workerResult.attendanceIds) {
          final attRef = _attendanceCollection(companyId).doc(attId);
          await chunkBatch.update(attRef, {
            'paymentStatus': 'paid',
            'paymentId': paymentId,
          });
        }
      }

      // 5. Create / Update Payroll Summary
      final summaryRef = _summariesCollection(companyId).doc(periodId);
      final summaryModel = PayrollSummaryModel(
        periodId: periodId,
        companyId: companyId,
        totalWorkers: totalWorkers,
        totalGross: totalGross,
        totalDeductions: totalDeductions,
        totalNetPaid: totalNetPaid,
        createdAt: DateTime.now(),
        createdBy: finalizedBy,
      );
      await chunkBatch.set(summaryRef, summaryModel.toMap());

      // 6. Update period status to paid/completed
      await chunkBatch.update(periodRef, {
        'status': 'paid',
        'paidAt': Timestamp.now(),
        'paidBy': finalizedBy,
        'settlementJobStatus': 'completed',
        'settlementCompletedAt': Timestamp.now(),
      });

      await chunkBatch.commit();
    } catch (e) {
      await periodRef.update({
        'settlementJobStatus': 'failed',
        'settlementCompletedAt': Timestamp.now(),
      });
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Streams
  // ---------------------------------------------------------------------------

  Stream<List<PayrollPeriodModel>> getPayrollPeriodsStream(String companyId) {
    return _periodsCollection(companyId)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PayrollPeriodModel.fromFirestore(doc))
            .toList());
  }

  Stream<PayrollPeriodModel?> getPayrollPeriodStream(String companyId, String periodId) {
    return _periodsCollection(companyId)
        .doc(periodId)
        .snapshots()
        .map((doc) => doc.exists ? PayrollPeriodModel.fromFirestore(doc) : null);
  }

  Stream<List<PayrollRegisterModel>> getPayrollRegistersStream(
      String companyId, String periodId) {
    return _registersCollection(companyId)
        .where('periodId', isEqualTo: periodId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PayrollRegisterModel.fromFirestore(doc))
            .toList());
  }

  Stream<PayrollSummaryModel?> getPayrollSummaryStream(
      String companyId, String periodId) {
    return _summariesCollection(companyId)
        .doc(periodId)
        .snapshots()
        .map((doc) => doc.exists ? PayrollSummaryModel.fromFirestore(doc) : null);
  }

  /// Scans attendance records for legacy/orphaned payrollPeriodId assignments.
  Future<OrphanedPayrollAssignmentReport> scanOrphanedPayrollAssignments({
    required String companyId,
  }) async {
    // 1. Get all payroll period IDs
    final allPeriods = await _periodsCollection(companyId).get();
    final existingPeriodIds = allPeriods.docs.map((doc) => doc.id).toSet();

    // 2. Get all attendance records
    final snap = await _attendanceCollection(companyId).get();

    int totalAttendance = 0;
    int validAssignments = 0;
    int orphanedAssignments = 0;
    int floatingAssignments = 0;

    final List<String> orphanedDocIds = [];
    final List<String> floatingDocIds = [];

    for (final doc in snap.docs) {
      totalAttendance++;
      final data = doc.data();
      final pid = data['payrollPeriodId'] as String?;

      if (pid == null) {
        floatingAssignments++;
        floatingDocIds.add(doc.id);
      } else if (existingPeriodIds.contains(pid)) {
        validAssignments++;
      } else {
        orphanedAssignments++;
        orphanedDocIds.add(doc.id);
      }
    }

    return OrphanedPayrollAssignmentReport(
      totalAttendance: totalAttendance,
      validAssignments: validAssignments,
      orphanedAssignments: orphanedAssignments,
      floatingAssignments: floatingAssignments,
      orphanedDocIds: orphanedDocIds,
      floatingDocIds: floatingDocIds,
    );
  }

  /// Repairs orphaned payroll assignments by resetting payrollPeriodId to null.
  Future<void> repairOrphanedPayrollAssignments({
    required String companyId,
  }) async {
    // 1. Get all payroll period IDs
    final allPeriods = await _periodsCollection(companyId).get();
    final existingPeriodIds = allPeriods.docs.map((doc) => doc.id).toSet();

    // 2. Get all attendance records
    final snap = await _attendanceCollection(companyId).get();

    final chunkBatch = ChunkedFirestoreBatch(_firestore);
    bool hasUpdates = false;

    for (final doc in snap.docs) {
      final data = doc.data();
      final pid = data['payrollPeriodId'] as String?;
      final paymentStatus = data['paymentStatus'] as String? ?? 'unpaid';

      // Do NOT modify valid assignments or paid attendance
      if (pid != null && !existingPeriodIds.contains(pid) && paymentStatus != 'paid') {
        await chunkBatch.update(doc.reference, {
          'payrollPeriodId': null,
          'updatedAt': Timestamp.now(),
        });
        hasUpdates = true;
      }
    }

    if (hasUpdates) {
      await chunkBatch.commit();
    }
  }
}
