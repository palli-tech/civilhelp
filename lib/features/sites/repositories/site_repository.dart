import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firestore_path_service.dart';
import '../models/site_model.dart';


class SiteRepository {
  final FirebaseFirestore _firestore;

  SiteRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create a new site
  Future<SiteModel> createSite({
    required String name,
    required String location,
    required String client,
    required DateTime startDate,
    required String status,
    required String companyId,
    required String createdBy,
  }) async {
    try {
      final docRef = await _firestore.collection(FirestorePathService.sites(companyId)).add({
        'name': name,
        'location': location,
        'client': client,
        'startDate': Timestamp.fromDate(startDate),
        'status': status,
        'companyId': companyId,
        'createdAt': Timestamp.now(),
        'createdBy': createdBy,
      });

      final doc = await docRef.get();
      return SiteModel.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing site
  Future<void> updateSite({
    required String siteId,
    required String name,
    required String location,
    required String client,
    required DateTime startDate,
    required String status,
    required String companyId,
  }) async {
    try {
      await _firestore.collection(FirestorePathService.sites(companyId)).doc(siteId).update({
        'name': name,
        'location': location,
        'client': client,
        'startDate': Timestamp.fromDate(startDate),
        'status': status,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch all sites for a company as a stream
  Stream<List<SiteModel>> getSitesByCompanyStream(String companyId) {
    try {
      return _firestore
          .collection(FirestorePathService.sites(companyId))
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => SiteModel.fromFirestore(doc))
            .toList();
      });

    } catch (e) {
      return Stream.error(e);
    }
  }

  /// Fetch a single site by ID (tenant scoped)
  Future<SiteModel?> getSiteById({
    required String companyId,
    required String siteId,
  }) async {
    try {
      final doc = await _firestore
          .collection(FirestorePathService.sites(companyId))
          .doc(siteId)
          .get();

      if (doc.exists) {
        return SiteModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a site (tenant scoped)
  Future<void> deleteSite({
    required String companyId,
    required String siteId,
  }) async {
    try {
      await _firestore
          .collection(FirestorePathService.sites(companyId))
          .doc(siteId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }
}
