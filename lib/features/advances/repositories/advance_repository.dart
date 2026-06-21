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
    required double amount,
    required String description,
    required DateTime date,
    required String companyId,
    required String createdBy,
  }) async {
    // Enforce that labour must be active
    final labourDoc = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('labour')
        .doc(labourId)
        .get();
    if (!labourDoc.exists) {
      throw Exception('Labour record not found.');
    }
    final workerStatus = labourDoc.data()?['status'] as String? ?? 'active';
    if (workerStatus != 'active') {
      throw Exception('Cannot issue advance to inactive worker.');
    }

    final docRef = await _advancesCollection(companyId).add({
      'companyId': companyId,
      'labourId': labourId,
      'labourName': labourName,
      'amount': amount,
      'recoveredAmount': 0.0,
      'remainingAmount': amount,
      'status': 'pending',
      'date': Timestamp.fromDate(date),
      'description': description,
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
          .where('status', whereIn: ['pending', 'partial'])
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => AdvanceModel.fromFirestore(doc))
                .toList()
                ..sort((a, b) => b.date.compareTo(a.date)),
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
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => AdvanceModel.fromFirestore(doc))
                .toList()
                ..sort((a, b) => b.date.compareTo(a.date)),
          );
    } catch (e) {
      return Stream.error(e);
    }
  }
}
