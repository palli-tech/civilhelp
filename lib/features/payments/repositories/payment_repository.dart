import 'package:civilhelp/features/advances/repositories/advance_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/payment_model.dart';

class PaymentSummary {
  final double grossAmount;
  final double advancesTotal;

  const PaymentSummary({
    required this.grossAmount,
    required this.advancesTotal,
  });

  double get netAmount => grossAmount - advancesTotal;
}

class PaymentRepository {
  final FirebaseFirestore _firestore;

  PaymentRepository({FirebaseFirestore? firestore, required AdvanceRepository advanceRepository})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<PaymentModel> createPayment({
    required String labourId,
    required String labourName,
    required String siteId,
    required String siteName,
    required DateTime periodStart,
    required DateTime periodEnd,
    required double grossAmount,
    required double advancesTotal,
    required double netAmount,
    required String status,
    required String companyId,
    required String createdBy,
  }) async {
    if (periodStart.isAfter(periodEnd)) {
      throw Exception('Period start date must be before or equal to period end date.');
    }
    if (grossAmount <= 0) {
      throw Exception('No payable attendance found for the selected period.');
    }

    final docRef = await _firestore.collection('payments').add({
      'labourId': labourId,
      'labourName': labourName,
      'siteId': siteId,
      'siteName': siteName,
      'periodStart': Timestamp.fromDate(periodStart),
      'periodEnd': Timestamp.fromDate(periodEnd),
      'grossAmount': grossAmount,
      'advancesTotal': advancesTotal,
      'netAmount': netAmount,
      'status': status,
      'companyId': companyId,
      'createdAt': Timestamp.now(),
      'createdBy': createdBy,
    });

    final doc = await docRef.get();
    return PaymentModel.fromFirestore(doc);
  }

  Future<void> updatePayment(PaymentModel payment) async {
    await _firestore
        .collection('payments')
        .doc(payment.id)
        .update(payment.toMap());
  }

  Future<void> deletePayment(String paymentId) async {
    await _firestore.collection('payments').doc(paymentId).delete();
  }

  Stream<List<PaymentModel>> getPaymentsByCompanyStream(String companyId) {
    try {
      return _firestore
          .collection('payments')
          .where('companyId', isEqualTo: companyId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => PaymentModel.fromFirestore(doc))
                .toList(),
          );
    } catch (e) {
      return Stream.error(e);
    }
  }

  Stream<List<PaymentModel>> getPaymentsByStatusStream(
    String companyId,
    String status,
  ) {
    try {
      return _firestore
          .collection('payments')
          .where('companyId', isEqualTo: companyId)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => PaymentModel.fromFirestore(doc))
                .toList(),
          );
    } catch (e) {
      return Stream.error(e);
    }
  }

  Future<PaymentSummary> calculatePaymentSummaryForPeriod({
    required String companyId,
    required String labourId,
    required double dailyWage,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final attendanceSnapshot = await _firestore
        .collection('attendance')
        .where('companyId', isEqualTo: companyId)
        .where('labourId', isEqualTo: labourId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(periodStart))
        .where('date', isLessThan: Timestamp.fromDate(periodEnd))
        .get();

    var gross = 0.0;
    for (final doc in attendanceSnapshot.docs) {
      final data = doc.data();
      final status = data['status'] as String? ?? 'absent';
      final hoursWorked = (data['hoursWorked'] as num?)?.toDouble() ?? 0.0;

      if (status.toLowerCase() == 'present') {
        gross +=
            dailyWage *
            (hoursWorked > 0 ? (hoursWorked / 8.0).clamp(0.0, 1.0) : 1.0);
      } else if (status.toLowerCase() == 'half day') {
        gross += dailyWage * 0.5;
      }
    }

    final advancesSnapshot = await _firestore
        .collection('advances')
        .where('companyId', isEqualTo: companyId)
        .where('labourId', isEqualTo: labourId)
        .where('paidBack', isEqualTo: false)
        .get();

    final advancesTotal = advancesSnapshot.docs.fold<double>(0.0, (sumx, doc) {
      final data = doc.data();
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      return sumx + amount;
    });

    return PaymentSummary(grossAmount: gross, advancesTotal: advancesTotal);
  }

  Stream<List<PaymentModel>> getPaymentsByLabourStream(
    String companyId,
    String labourId,
  ) {
    try {
      return _firestore
          .collection('payments')
          .where('companyId', isEqualTo: companyId)
          .where('labourId', isEqualTo: labourId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => PaymentModel.fromFirestore(doc))
                .toList(),
          );
    } catch (e) {
      return Stream.error(e);
    }
  }

  /// Returns true if there exists a payment for [labourId] in [companyId]
  /// that overlaps with the given [periodStart, periodEnd) interval.
  /// Performs overlap detection entirely in Dart to avoid composite index.
  Future<bool> hasOverlappingPayment({
    required String companyId,
    required String labourId,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final snapshot = await _firestore
        .collection('payments')
        .where('companyId', isEqualTo: companyId)
        .where('labourId', isEqualTo: labourId)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final existingStart = (data['periodStart'] as Timestamp?)?.toDate();
      final existingEnd = (data['periodEnd'] as Timestamp?)?.toDate();
      
      if (existingStart != null && existingEnd != null) {
        // Overlap check: existing.periodStart < new.periodEnd AND existing.periodEnd > new.periodStart
        if (existingStart.isBefore(periodEnd) && existingEnd.isAfter(periodStart)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Create a payment and atomically mark applied advances as paid.
  /// This method will re-check and only apply advances that are still unpaid
  /// at the moment of the transaction. It will also prevent creating a
  /// duplicate/overlapping payment by throwing if one exists.
  Future<PaymentModel> createPaymentWithAdvancesApplied({
    required String labourId,
    required String labourName,
    required String siteId,
    required String siteName,
    required DateTime periodStart,
    required DateTime periodEnd,
    required double grossAmount,
    required String status,
    required String companyId,
    required String createdBy,
  }) async {
    if (periodStart.isAfter(periodEnd)) {
      throw Exception('Period start date must be before or equal to period end date.');
    }
    if (grossAmount <= 0) {
      throw Exception('No payable attendance found for the selected period.');
    }

    // Pre-check for overlapping payment to provide fast validation.
    final exists = await hasOverlappingPayment(
      companyId: companyId,
      labourId: labourId,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );

    if (exists) {
      throw Exception('A payment for this labour and period already exists');
    }

    // Candidate unpaid advances (snapshot outside transaction). We'll re-check
    // inside the transaction to avoid races.
    final advancesSnapshot = await _firestore
        .collection('advances')
        .where('companyId', isEqualTo: companyId)
        .where('labourId', isEqualTo: labourId)
        .where('paidBack', isEqualTo: false)
        .get();

    final candidateRefs = advancesSnapshot.docs.map((d) => d.reference).toList();

    final paymentsCol = _firestore.collection('payments');
    final newDocRef = paymentsCol.doc();

    await _firestore.runTransaction((tx) async {
      double appliedTotal = 0.0;
      final List<String> appliedIds = [];

      // Re-check each candidate advance inside the transaction and accumulate.
      for (final ref in candidateRefs) {
        final advSnap = await tx.get(ref);
        final advData = advSnap.data();
        if (advData == null) continue;
        final paidBack = advData['paidBack'] as bool? ?? false;
        if (!paidBack) {
          final amount = (advData['amount'] as num?)?.toDouble() ?? 0.0;
          appliedTotal += amount;
          appliedIds.add(advSnap.id);
        }
      }

      final netAmount = grossAmount - appliedTotal;

      final paymentData = {
        'labourId': labourId,
        'labourName': labourName,
        'siteId': siteId,
        'siteName': siteName,
        'periodStart': Timestamp.fromDate(periodStart),
        'periodEnd': Timestamp.fromDate(periodEnd),
        'grossAmount': grossAmount,
        'advancesTotal': appliedTotal,
        'netAmount': netAmount,
        'status': status,
        'companyId': companyId,
        'createdAt': Timestamp.now(),
        'createdBy': createdBy,
        'appliedAdvanceIds': appliedIds,
      };

      tx.set(newDocRef, paymentData);

      // Mark applied advances as paid and reference the payment id.
      for (final id in appliedIds) {
        final advRef = _firestore.collection('advances').doc(id);
        tx.update(advRef, {
          'paidBack': true,
          'appliedToPaymentId': newDocRef.id,
        });
      }
    });

    final created = await newDocRef.get();
    return PaymentModel.fromFirestore(created);
  }
}
