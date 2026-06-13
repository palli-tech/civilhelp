import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firestore_path_service.dart';
import '../models/advance_model.dart';

class AdvanceRepository {
  final FirebaseFirestore _firestore;

  AdvanceRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, Object?>> _advancesCollection(
    String companyId,
  ) {
    return _firestore.collection(
      FirestorePathService.advances(companyId),
    );
  }

  Future<AdvanceModel> createAdvance({
    required String labourId,
    required String labourName,
    required String siteId,
    required String siteName,
    required double amount,
    required String reason,
    required DateTime date,
    required bool paidBack,
    required String companyId,
    required String createdBy,
  }) async {
    final docRef = await _advancesCollection(companyId).add({
      'labourId': labourId,
      'labourName': labourName,
      'siteId': siteId,
      'siteName': siteName,
      'amount': amount,
      'reason': reason,
      'date': Timestamp.fromDate(date),
      'paidBack': paidBack,
      'companyId': companyId,
      'createdAt': Timestamp.now(),
      'createdBy': createdBy,
    });

    final doc = await docRef.get();
    return AdvanceModel.fromFirestore(doc);
  }

  Future<void> updateAdvance(AdvanceModel advance) async {
    await _advancesCollection(advance.companyId)
        .doc(advance.id)
        .update(advance.toMap());
  }

  Future<void> deleteAdvance({
    required String advanceId,
    required String companyId,
  }) async {
    await _advancesCollection(companyId).doc(advanceId).delete();
  }

  Stream<List<AdvanceModel>> getAdvancesByCompanyStream(String companyId) {
    try {
      return _advancesCollection(companyId)
          .orderBy('date', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => AdvanceModel.fromFirestore(doc))
                .toList(),
          );
    } catch (e) {
      return Stream.error(e);
    }
  }

  Stream<List<AdvanceModel>> getOutstandingAdvancesByCompanyStream(
    String companyId,
  ) {
    try {
      return _advancesCollection(companyId)
          .where('paidBack', isEqualTo: false)
          .orderBy('date', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => AdvanceModel.fromFirestore(doc))
                .toList(),
          );
    } catch (e) {
      return Stream.error(e);
    }
  }

  Stream<List<AdvanceModel>> getAdvancesByLabourStream(
    String companyId,
    String labourId,
  ) {
    try {
      return _advancesCollection(companyId)
          .where('labourId', isEqualTo: labourId)
          .orderBy('date', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => AdvanceModel.fromFirestore(doc))
                .toList(),
          );
    } catch (e) {
      return Stream.error(e);
    }
  }
}

