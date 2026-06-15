import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:civilhelp/core/services/firestore_path_service.dart';
import '../../domain/entities/labour_entity.dart';
import '../models/labour_model.dart';

class LabourRepository {
  final FirebaseFirestore _firestore;

  LabourRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> _checkDeactivationPrerequisites(String companyId, String labourId) async {
    final attendancePath = FirestorePathService.attendance(companyId);
    final advancesPath = FirestorePathService.advances(companyId);

    // Unpaid attendance check (where isDeleted != true and paymentStatus != paid)
    final unpaidAttendanceQuery = await _firestore
        .collection(attendancePath)
        .where('labourId', isEqualTo: labourId)
        .where('isDeleted', isNotEqualTo: true)
        .get();

    final hasUnpaidAttendance = unpaidAttendanceQuery.docs.any((doc) => 
        doc.data()['paymentStatus'] != 'paid');

    if (hasUnpaidAttendance) {
      throw Exception('Cannot deactivate worker: unpaid attendance logs exist.');
    }

    // Unpaid advances check (where status is pending or partial)
    final unpaidAdvancesQuery = await _firestore
        .collection(advancesPath)
        .where('labourId', isEqualTo: labourId)
        .where('status', whereIn: ['pending', 'partial'])
        .get();

    if (unpaidAdvancesQuery.docs.isNotEmpty) {
      throw Exception('Cannot deactivate worker: unpaid/unrecovered advances exist.');
    }
  }

  /// Create a new labour record
  Future<LabourModel> createLabour({
    required String fullName,
    required String phoneNumber,
    required String aadhaarNumber,
    required double dailyWage,
    required String assignedSiteId,
    required String assignedSiteName,
    required DateTime joinedDate,
    required String status,
    required String companyId,
    required String createdBy,
  }) async {
    try {
      LabourEntity.validatePhone(phoneNumber);
      LabourEntity.validateAadhaar(aadhaarNumber);

      final docRef = await _firestore.collection(FirestorePathService.labour(companyId)).add({
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'aadhaarNumber': aadhaarNumber,
        'dailyWage': dailyWage,
        'assignedSiteId': assignedSiteId,
        'assignedSiteName': assignedSiteName,
        'joinedDate': Timestamp.fromDate(joinedDate),
        'status': status,
        'companyId': companyId,
        'createdAt': Timestamp.now(),
        'createdBy': createdBy,
      });

      final doc = await docRef.get();
      return LabourModel.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing labour record
  Future<void> updateLabour({
    required String companyId,
    required String labourId,
    required String fullName,
    required String phoneNumber,
    required String aadhaarNumber,
    required double dailyWage,
    required String assignedSiteId,
    required String assignedSiteName,
    required DateTime joinedDate,
    required String status,
  }) async {
    try {
      LabourEntity.validatePhone(phoneNumber);
      LabourEntity.validateAadhaar(aadhaarNumber);

      if (status == 'inactive') {
        await _checkDeactivationPrerequisites(companyId, labourId);
      }

      await _firestore.collection(FirestorePathService.labour(companyId)).doc(labourId).update({
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'aadhaarNumber': aadhaarNumber,
        'dailyWage': dailyWage,
        'assignedSiteId': assignedSiteId,
        'assignedSiteName': assignedSiteName,
        'joinedDate': Timestamp.fromDate(joinedDate),
        'status': status,
        'deactivatedAt': status == 'inactive' ? FieldValue.serverTimestamp() : null,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Update labour status
  Future<void> updateLabourStatus({
    required String companyId,
    required String labourId,
    required String status,
  }) async {
    try {
      if (status == 'inactive') {
        await _checkDeactivationPrerequisites(companyId, labourId);
      }

      await _firestore.collection(FirestorePathService.labour(companyId)).doc(labourId).update({
        'status': status,
        'deactivatedAt': status == 'inactive' ? FieldValue.serverTimestamp() : null,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch all labour records for a company as a stream
  Stream<List<LabourModel>> getLabourByCompanyStream(String companyId) {
    try {
      return _firestore
          .collection(FirestorePathService.labour(companyId))
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => LabourModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      return Stream.error(e);
    }
  }

  /// Fetch labour records assigned to a specific site
  Stream<List<LabourModel>> getLabourBySiteStream(String companyId, String siteId) {

    try {
      return _firestore
          .collection(FirestorePathService.labour(companyId))
          .where('assignedSiteId', isEqualTo: siteId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => LabourModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      return Stream.error(e);
    }
  }

  /// Fetch labour records by status
  Stream<List<LabourModel>> getLabourByStatusStream(
    String companyId,
    String status,
  ) {
    try {
      return _firestore
          .collection(FirestorePathService.labour(companyId))
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => LabourModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      return Stream.error(e);
    }
  }

  /// Search labour by name
  Future<List<LabourModel>> searchLabourByName(
    String companyId,
    String searchTerm,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePathService.labour(companyId))
          .orderBy('fullName')
          .startAt([searchTerm])
          .endAt(['$searchTerm\uf8ff'])
          .get();

      return snapshot.docs
          .map((doc) => LabourModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch a single labour by ID (tenant scoped)
  Future<LabourModel?> getLabourById({
    required String companyId,
    required String labourId,
  }) async {
    try {
      final doc = await _firestore
          .collection(FirestorePathService.labour(companyId))
          .doc(labourId)
          .get();
      if (doc.exists) {
        return LabourModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a labour record (tenant scoped)
  Future<void> deleteLabour({
    required String companyId,
    required String labourId,
  }) async {
    try {
      await _firestore
          .collection(FirestorePathService.labour(companyId))
          .doc(labourId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }
}
