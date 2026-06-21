import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/company.dart';
import '../../core/services/firestore_path_service.dart';

class CompanyRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CompanyRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  Future<void> createCompany(Company company) async {
    final docRef = _firestore.collection('companies').doc(company.id);
    await docRef.set(company.toFirestore());
  }

  Future<Company?> getCompany(String companyId) async {
    final doc = await _firestore.collection('companies').doc(companyId).get();
    if (!doc.exists) return null;
    return Company.fromFirestore(doc);
  }

  Stream<Company?> watchCompany(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .snapshots()
        .map((doc) => doc.exists ? Company.fromFirestore(doc) : null);
  }

  Future<void> updateCompany(Company company) async {
    final docRef = _firestore.collection('companies').doc(company.id);
    await docRef.update(company.toFirestore());
  }

  Future<String> uploadLogo(String companyId, File imageFile) async {
    final path = FirestorePathService.companyLogo(companyId);
    final ref = _storage.ref().child(path);
    
    final uploadTask = await ref.putFile(imageFile);
    final url = await uploadTask.ref.getDownloadURL();
    
    // Update company document with new logo url
    await _firestore.collection('companies').doc(companyId).update({
      'logoUrl': url,
    });
    
    return url;
  }

  Future<void> deleteLogo(String companyId) async {
    final path = FirestorePathService.companyLogo(companyId);
    final ref = _storage.ref().child(path);
    
    await ref.delete();
    
    // Remove from company doc
    await _firestore.collection('companies').doc(companyId).update({
      'logoUrl': FieldValue.delete(),
    });
  }
}
