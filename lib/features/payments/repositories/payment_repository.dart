import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firestore_path_service.dart';
import '../models/payment_model.dart';

class PaymentRepository {
  final FirebaseFirestore _firestore;

  PaymentRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, Object?>> _paymentsCollection(
    String companyId,
  ) {
    return _firestore.collection(
      FirestorePathService.payments(companyId),
    );
  }

  Future<PaymentModel> createPayment({
    required String companyId,
    required String labourId,
    required String labourName,
    required String payrollPeriodId,
    required DateTime periodStart,
    required DateTime periodEnd,
    required double grossEarningsSnapshot,
    required double deductionsSnapshot,
    required double amount,
    required String paymentMode,
    String? referenceNumber,
    required DateTime paymentDate,
    String? notes,
    required String createdBy,
  }) async {
    final docRef = await _paymentsCollection(companyId).add({
      'companyId': companyId,
      'labourId': labourId,
      'labourName': labourName,
      'payrollPeriodId': payrollPeriodId,
      'periodStart': Timestamp.fromDate(periodStart),
      'periodEnd': Timestamp.fromDate(periodEnd),
      'grossEarningsSnapshot': grossEarningsSnapshot,
      'deductionsSnapshot': deductionsSnapshot,
      'amount': amount,
      'paymentMode': paymentMode,
      'referenceNumber': referenceNumber,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'notes': notes,
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
    await _paymentsCollection(companyId).doc(paymentId).delete();
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

  Stream<List<PaymentModel>> getPaymentsByLabourStream(
    String companyId,
    String labourId,
  ) {
    try {
      return _paymentsCollection(companyId)
          .where('labourId', isEqualTo: labourId)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => PaymentModel.fromFirestore(doc))
                .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
          );
    } catch (e) {
      return Stream.error(e);
    }
  }

  // Compatibility Methods for Legacy UI & Providers
  Stream<List<PaymentModel>> getPaymentsByStatusStream(String companyId, String status) {
    if (status == 'pending') {
      return Stream.value([]); // In new system, all payments are created immediately as paid
    }
    return getPaymentsByCompanyStream(companyId);
  }

  Future<PaymentSummary> calculatePaymentSummaryForPeriod({
    required String companyId,
    required String labourId,
    required String siteId,
    required double dailyWage,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final snap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('attendance')
        .where('labourId', isEqualTo: labourId)
        .where('siteId', isEqualTo: siteId)
        .where('isDeleted', isEqualTo: false)
        .get();

    double gross = 0.0;
    for (final doc in snap.docs) {
      final date = (doc.data()['date'] as Timestamp).toDate();
      if (date.isBefore(periodStart) || date.isAfter(periodEnd)) continue;
      final earnings = (doc.data()['earningsSnapshot'] as num?)?.toDouble() ?? 0.0;
      gross += earnings;
    }

    final advSnap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('advances')
        .where('labourId', isEqualTo: labourId)
        .where('status', whereIn: ['pending', 'partial'])
        .get();

    double outstanding = 0.0;
    for (final doc in advSnap.docs) {
      outstanding += (doc.data()['remainingAmount'] as num?)?.toDouble() ?? 0.0;
    }

    final deductions = outstanding > gross ? gross : outstanding;
    return PaymentSummary(
      grossAmount: gross,
      advancesTotal: deductions,
      netAmount: gross - deductions,
    );
  }

  /// Legacy method — creates a one-off payment with advances applied.
  /// Note: periodStart/periodEnd are passed in directly; no period ID reconstruction.
  Future<PaymentModel> createPaymentWithAdvancesApplied({
    required String companyId,
    required String labourId,
    required String labourName,
    required String siteId,
    required String siteName,
    required DateTime periodStart,
    required DateTime periodEnd,
    required double grossAmount,
    required String createdBy,
  }) async {
    final advSnap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('advances')
        .where('labourId', isEqualTo: labourId)
        .where('status', whereIn: ['pending', 'partial'])
        .get();

    double outstanding = 0.0;
    for (final doc in advSnap.docs) {
      outstanding += (doc.data()['remainingAmount'] as num?)?.toDouble() ?? 0.0;
    }
    final deductions = outstanding > grossAmount ? grossAmount : outstanding;
    final net = grossAmount - deductions;

    return createPayment(
      companyId: companyId,
      labourId: labourId,
      labourName: labourName,
      payrollPeriodId: '',
      periodStart: periodStart,
      periodEnd: periodEnd,
      grossEarningsSnapshot: grossAmount,
      deductionsSnapshot: deductions,
      amount: net,
      paymentMode: 'cash',
      paymentDate: DateTime.now(),
      createdBy: createdBy,
    );
  }

  Future<void> markPaymentAsPaid({
    required String paymentId,
    required String companyId,
  }) async {
    // Payments are already paid/settled in the new engine
  }

  Future<void> updatePaymentStatus({
    required String paymentId,
    required String status,
    required String companyId,
  }) async {
    // Status is always paid/completed in the new engine
  }

  Future<bool> hasOverlappingPayment({
    required String companyId,
    required String labourId,
    required String payrollPeriodId,
  }) async {
    // Checks by actual period document ID — no inline ID construction.
    if (payrollPeriodId.isEmpty) return false;
    final snap = await _paymentsCollection(companyId)
        .where('labourId', isEqualTo: labourId)
        .where('payrollPeriodId', isEqualTo: payrollPeriodId)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<PaymentSummary> calculateFinalPaymentSummary(PaymentModel payment) async {
    return PaymentSummary(
      grossAmount: payment.grossAmount,
      advancesTotal: payment.advancesTotal,
      netAmount: payment.netAmount,
    );
  }
}
