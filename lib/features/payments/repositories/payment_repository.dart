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

  PaymentRepository({FirebaseFirestore? firestore})
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
}
