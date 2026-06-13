import 'dart:developer' as developer;

import 'package:civilhelp/features/advances/repositories/advance_repository.dart';
import 'package:civilhelp/features/attendance/models/attendance_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firestore_path_service.dart';

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

  CollectionReference<Map<String, Object?>> _paymentsCollection(
    String companyId,
  ) {
    return _firestore.collection(
      FirestorePathService.payments(companyId),
    );
  }

  CollectionReference<Map<String, Object?>> _advancesCollection(
    String companyId,
  ) {
    return _firestore.collection(
      FirestorePathService.advances(companyId),
    );
  }

  CollectionReference<Map<String, Object?>> _attendanceCollection(
    String companyId,
  ) {
    return _firestore.collection(
      FirestorePathService.attendance(companyId),
    );
  }


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

    final docRef = await _paymentsCollection(companyId).add({
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
    await _paymentsCollection(payment.companyId)
        .doc(payment.id)
        .update(payment.toMap());
  }


  Future<void> deletePayment({
    required String paymentId,
    required String companyId,
  }) async {
    final paymentDoc = await _paymentsCollection(companyId).doc(paymentId).get();
    if (!paymentDoc.exists) return;

    final data = paymentDoc.data()!;
    final appliedAmounts = (data['appliedAdvanceAmounts'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble())) ?? {};

    await _firestore.runTransaction((tx) async {
      // Revert the recovered amounts on the associated advances
      for (final entry in appliedAmounts.entries) {
        final advRef = _advancesCollection(companyId).doc(entry.key);
        final advSnap = await tx.get(advRef);
        if (advSnap.exists) {
          final advData = advSnap.data()!;
          final currentRecovered = (advData['recoveredAmount'] as num?)?.toDouble() ?? 0.0;
          final newRecovered = (currentRecovered - entry.value).clamp(0.0, double.infinity);
          
          tx.update(advRef, {
            'recoveredAmount': newRecovered,
            'paidBack': false, // Unmark paidBack if we revert any amount
          });
        }
      }
      tx.delete(paymentDoc.reference);
    });
  }

  Future<void> markPaymentAsPaid({
    required String paymentId,
    required String companyId,
  }) async {
    final paymentRef = _paymentsCollection(companyId).doc(paymentId);
    
    // 1. Fetch payment outside transaction to get companyId and labourId
    final initialSnap = await paymentRef.get();
    if (!initialSnap.exists) {
      throw Exception('Payment not found');
    }
    
    final initialData = initialSnap.data()!;
    if (initialData['status'] == 'paid') {
      return; // Already paid
    }

    final labourId = initialData['labourId'] as String;
    
    // 2. Query candidate advances outside transaction
    final advancesSnapshot = await _advancesCollection(companyId)
        .where('labourId', isEqualTo: labourId)
        .where('paidBack', isEqualTo: false)
        .get();

    final candidateRefs = advancesSnapshot.docs.map((d) => d.reference).toList();
    
    await _firestore.runTransaction((tx) async {
      final paymentSnap = await tx.get(paymentRef);
      if (!paymentSnap.exists) {
        throw Exception('Payment not found');
      }
      
      final data = paymentSnap.data()!;
      if (data['status'] == 'paid') {
        return; // Already paid
      }

      final grossAmount = (data['grossAmount'] as num).toDouble();
      double remainingDeduction = grossAmount;
      double appliedTotal = 0.0;
      final List<String> appliedIds = [];
      final Map<String, double> appliedAmounts = {};

      for (final ref in candidateRefs) {
        if (remainingDeduction <= 0) break;

        final advSnap = await tx.get(ref);
        final advData = advSnap.data();
        if (advData == null) continue;

        final paidBack = advData['paidBack'] as bool? ?? false;
        if (!paidBack) {
          final amount = (advData['amount'] as num?)?.toDouble() ?? 0.0;
          final recovered = (advData['recoveredAmount'] as num?)?.toDouble() ?? 0.0;
          final outstanding = amount - recovered;

          if (outstanding > 0) {
            final toApply = outstanding > remainingDeduction ? remainingDeduction : outstanding;
            appliedTotal += toApply;
            remainingDeduction -= toApply;
            appliedIds.add(advSnap.id);
            appliedAmounts[advSnap.id] = toApply;
            
            final newRecovered = recovered + toApply;
            final isFullyPaid = newRecovered >= amount;
            
            tx.update(ref, {
              'recoveredAmount': newRecovered,
              'paidBack': isFullyPaid,
            });
          }
        }
      }

      final netAmount = grossAmount - appliedTotal;

      tx.update(paymentRef, {
        'status': 'paid',
        'paidDate': Timestamp.now(),
        'advancesTotal': appliedTotal,
        'netAmount': netAmount,
        'appliedAdvanceIds': appliedIds,
        'appliedAdvanceAmounts': appliedAmounts,
      });
    });
  }

  Future<void> updatePaymentStatus({
    required String paymentId,
    required String status,
    required String companyId,
  }) async {
    await _paymentsCollection(companyId).doc(paymentId).update({'status': status});
  }



  Stream<List<PaymentModel>> getPaymentsByCompanyStream(String companyId) {
    try {
      return _paymentsCollection(companyId)
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
      return _paymentsCollection(companyId)
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

  Future<PaymentSummary> calculateFinalPaymentSummary(PaymentModel payment) async {
    final advancesSnapshot = await _advancesCollection(payment.companyId)
        .where('labourId', isEqualTo: payment.labourId)
        .where('paidBack', isEqualTo: false)
        .get();

    final totalOutstandingAdvances = advancesSnapshot.docs.fold<double>(0.0, (sumx, doc) {
      final data = doc.data();
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      final recoveredAmount = (data['recoveredAmount'] as num?)?.toDouble() ?? 0.0;
      final outstanding = amount - recoveredAmount;
      return sumx + (outstanding > 0 ? outstanding : 0.0);
    });
    
    final advancesTotal = totalOutstandingAdvances > payment.grossAmount ? payment.grossAmount : totalOutstandingAdvances;

    return PaymentSummary(grossAmount: payment.grossAmount, advancesTotal: advancesTotal);
  }

  Future<PaymentSummary> calculatePaymentSummaryForPeriod({
    required String companyId,
    required String labourId,
    required double dailyWage,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final attendanceSnapshot = await _attendanceCollection(companyId)
        .where('labourId', isEqualTo: labourId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(periodStart))
        .where('date', isLessThan: Timestamp.fromDate(periodEnd))
        .get();

    var gross = 0.0;
    for (final doc in attendanceSnapshot.docs) {
      final attendance = AttendanceModel.fromFirestore(doc);
      gross += attendance.calculateEarnings(dailyWage);
    }

    final advancesSnapshot = await _advancesCollection(companyId)
        .where('labourId', isEqualTo: labourId)
        .where('paidBack', isEqualTo: false)
        .get();

    final totalOutstandingAdvances = advancesSnapshot.docs.fold<double>(0.0, (sumx, doc) {
      final data = doc.data();
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      final recoveredAmount = (data['recoveredAmount'] as num?)?.toDouble() ?? 0.0;
      final outstanding = amount - recoveredAmount;
      return sumx + (outstanding > 0 ? outstanding : 0.0);
    });
    
    // Cap the advance deduction to the gross amount so netAmount is not negative
    final advancesTotal = totalOutstandingAdvances > gross ? gross : totalOutstandingAdvances;

    return PaymentSummary(grossAmount: gross, advancesTotal: advancesTotal);
  }

  Stream<List<PaymentModel>> getPaymentsByLabourStream(
    String companyId,
    String labourId,
  ) {
    try {
      return _paymentsCollection(companyId)
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
    final snapshot = await _paymentsCollection(companyId)
        .where('labourId', isEqualTo: labourId)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final existingStart = (data['periodStart'] as Timestamp?)?.toDate();
      final existingEnd = (data['periodEnd'] as Timestamp?)?.toDate();
      
      if (existingStart != null && existingEnd != null) {
        // Overlap check: newStart <= existingEnd AND newEnd >= existingStart
        if (periodStart.compareTo(existingEnd) <= 0 && periodEnd.compareTo(existingStart) >= 0) {
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
    required String companyId,
    required String createdBy,
  }) async {
    developer.log('DEBUG: Starting createPaymentWithAdvancesApplied for labourId: $labourId, grossAmount: $grossAmount');
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
      throw Exception('Payment periods cannot overlap. A payment already exists for these dates.');
    }

    // Candidate unpaid advances (snapshot outside transaction). We'll re-check
    // inside the transaction to avoid races.
    final advancesSnapshot = await _advancesCollection(companyId)
        .where('labourId', isEqualTo: labourId)
        .where('paidBack', isEqualTo: false)
        .get();

    final candidateRefs = advancesSnapshot.docs.map((d) => d.reference).toList();
    developer.log('DEBUG: Candidate advance refs count: ${candidateRefs.length}');

    final prefix = 'PAY-${periodStart.year}${periodStart.month.toString().padLeft(2, '0')}-';
    final lastPaymentQuery = await _paymentsCollection(companyId)
        .where('paymentNumber', isGreaterThanOrEqualTo: prefix)
        .where('paymentNumber', isLessThan: '$prefix\uf8ff')
        .orderBy('paymentNumber', descending: true)
        .limit(1)
        .get();

    int sequence = 1;
    if (lastPaymentQuery.docs.isNotEmpty) {
      final lastNum = lastPaymentQuery.docs.first.data()['paymentNumber'] as String?;
      if (lastNum != null && lastNum.startsWith(prefix)) {
        final seqStr = lastNum.substring(prefix.length);
        sequence = (int.tryParse(seqStr) ?? 0) + 1;
      }
    }
    final paymentNumber = '$prefix${sequence.toString().padLeft(4, '0')}';
    developer.log('DEBUG: Generated payment number: $paymentNumber');

    final paymentsCol = _paymentsCollection(companyId);
    final newDocRef = paymentsCol.doc();

    await _firestore.runTransaction((tx) async {
      double remainingDeduction = grossAmount;
      double appliedTotal = 0.0;
      final List<String> appliedIds = [];
      final Map<String, double> appliedAmounts = {};

      developer.log('DEBUG: Transaction starting. remainingDeduction: $remainingDeduction');

      // Re-check each candidate advance inside the transaction and accumulate intended deductions.
      for (final ref in candidateRefs) {
        if (remainingDeduction <= 0) break;

        final advSnap = await tx.get(ref);
        final advData = advSnap.data();
        if (advData == null) continue;

        final paidBack = advData['paidBack'] as bool? ?? false;
        if (!paidBack) {
          final amount = (advData['amount'] as num?)?.toDouble() ?? 0.0;
          final recovered = (advData['recoveredAmount'] as num?)?.toDouble() ?? 0.0;
          final outstanding = amount - recovered;

          if (outstanding > 0) {
            final toApply = outstanding > remainingDeduction ? remainingDeduction : outstanding;
            developer.log('DEBUG: Applying to advance ${advSnap.id}. outstanding: $outstanding, toApply: $toApply');
            appliedTotal += toApply;
            remainingDeduction -= toApply;
            appliedIds.add(advSnap.id);
            appliedAmounts[advSnap.id] = toApply;
            // DO NOT mutate the advance here. This is a Pending payment.
          }
        }
      }

      final netAmount = grossAmount - appliedTotal;
      developer.log('DEBUG: Transaction completing. appliedTotal: $appliedTotal, netAmount: $netAmount');

      final paymentData = {
        'paymentNumber': paymentNumber,
        'labourId': labourId,
        'labourName': labourName,
        'siteId': siteId,
        'siteName': siteName,
        'periodStart': Timestamp.fromDate(periodStart),
        'periodEnd': Timestamp.fromDate(periodEnd),
        'grossAmount': grossAmount,
        'advancesTotal': appliedTotal,
        'netAmount': netAmount,
        'status': 'pending',
        'companyId': companyId,
        'createdAt': Timestamp.now(),
        'createdBy': createdBy,
        'appliedAdvanceIds': appliedIds,
        'appliedAdvanceAmounts': appliedAmounts,
      };

      tx.set(newDocRef, paymentData);
    });

    final created = await newDocRef.get();
    return PaymentModel.fromFirestore(created);
  }
}
