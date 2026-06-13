import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/attendance_model.dart';
import '../../../core/services/firestore_path_service.dart';

class AttendanceRepository {
  final FirebaseFirestore _firestore;

  AttendanceRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, Object?>> _attendanceCollection(
    String companyId,
  ) {
    return _firestore.collection(
      FirestorePathService.attendance(companyId),
    );
  }

  Future<AttendanceModel> createAttendance({
    required String labourId,
    required String labourName,
    required String siteId,
    required String siteName,
    required DateTime date,
    required String status,
    required double hoursWorked,
    required double musterQuantity,
    required String companyId,
    required String createdBy,
  }) async {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day, 23, 59, 59, 999);
    if (date.isAfter(normalizedToday)) {
      throw Exception('Attendance date cannot be in the future.');
    }
    final docRef = await _attendanceCollection(companyId).add({
      'labourId': labourId,
      'labourName': labourName,
      'siteId': siteId,
      'siteName': siteName,
      'date': Timestamp.fromDate(date),
      'status': status,
      'hoursWorked': hoursWorked,
      'musterQuantity': musterQuantity,
      'companyId': companyId,
      'createdAt': Timestamp.now(),
      'createdBy': createdBy,
    });

    final doc = await docRef.get();
    return AttendanceModel.fromFirestore(doc);
  }

  Future<(int created, int skipped)> createBulkAttendance({
    required String siteId,
    required String siteName,
    required DateTime date,
    required String companyId,
    required String createdBy,
    required List<({String labourId, String labourName, String status, double hoursWorked, double musterQuantity})> labourRecords,
  }) async {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day, 23, 59, 59, 999);
    if (date.isAfter(normalizedToday)) {
      throw Exception('Attendance date cannot be in the future.');
    }
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // 1. Fetch existing attendances for this site and date to prevent duplicates
    final existingQuery = await _attendanceCollection(companyId)
        .where('siteId', isEqualTo: siteId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    final existingLabourIds = existingQuery.docs
        .map((doc) => doc.data()['labourId'] as String)
        .toSet();

    int skipped = 0;
    int created = 0;

    // 2. Use a WriteBatch for efficient creation
    WriteBatch batch = _firestore.batch();
    int batchCount = 0;

    final attendanceCollection = _attendanceCollection(companyId);

    for (final record in labourRecords) {
      if (existingLabourIds.contains(record.labourId)) {
        skipped++;
        continue;
      }

      final docRef = attendanceCollection.doc();
      batch.set(docRef, {
        'labourId': record.labourId,
        'labourName': record.labourName,
        'siteId': siteId,
        'siteName': siteName,
        'date': Timestamp.fromDate(date),
        'status': record.status,
        'hoursWorked': record.hoursWorked,
        'musterQuantity': record.musterQuantity,
        'companyId': companyId,
        'createdAt': Timestamp.now(),
        'createdBy': createdBy,
      });

      created++;
      batchCount++;

      // Firestore batch limit is 500
      if (batchCount == 499) {
        await batch.commit();
        batch = _firestore.batch();
        batchCount = 0;
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    return (created, skipped);
  }

  Future<void> updateAttendance(AttendanceModel attendance) async {
    await _attendanceCollection(attendance.companyId)
        .doc(attendance.id)
        .update({
      'labourId': attendance.labourId,
      'labourName': attendance.labourName,
      'siteId': attendance.siteId,
      'siteName': attendance.siteName,
      'date': Timestamp.fromDate(attendance.date),
      'status': attendance.status,
      'hoursWorked': attendance.hoursWorked,
      'musterQuantity': attendance.musterQuantity,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> deleteAttendance({
    required String attendanceId,
    required String companyId,
  }) async {
    await _attendanceCollection(companyId).doc(attendanceId).delete();
  }

  Stream<List<AttendanceModel>> getAttendanceByCompanyStream(
    String companyId,
  ) {
    try {
      return _attendanceCollection(companyId)
          .orderBy('date', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => AttendanceModel.fromFirestore(doc))
                .toList(),
          );
    } catch (e) {
      return Stream.error(e);
    }
  }

  Stream<List<AttendanceModel>> getAttendanceBySiteStream(
    String companyId,
    String siteId,
  ) {
    try {
      return _attendanceCollection(companyId)
          .where('siteId', isEqualTo: siteId)
          .orderBy('date', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => AttendanceModel.fromFirestore(doc))
                .toList(),
          );
    } catch (e) {
      return Stream.error(e);
    }
  }

  Stream<List<AttendanceModel>> getAttendanceByLabourStream(
    String companyId,
    String labourId,
  ) {
    try {
      return _attendanceCollection(companyId)
          .where('labourId', isEqualTo: labourId)
          .orderBy('date', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => AttendanceModel.fromFirestore(doc))
                .toList(),
          );
    } catch (e) {
      return Stream.error(e);
    }
  }

  Stream<List<AttendanceModel>> getAttendanceByDateRangeStream(
    String companyId,
    DateTime start,
    DateTime end,
  ) {
    try {
      return _attendanceCollection(companyId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThan: Timestamp.fromDate(end))
          .orderBy('date', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => AttendanceModel.fromFirestore(doc))
                .toList(),
          );
    } catch (e) {
      return Stream.error(e);
    }
  }

  Stream<List<AttendanceModel>> getAttendanceForTodayStream(
    String companyId,
  ) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      return getAttendanceByDateRangeStream(companyId, startOfDay, endOfDay);
    } catch (e) {
      return Stream.error(e);
    }
  }

  /// Get a single attendance for a labour on the given date (day range).
  /// Returns the first matching AttendanceModel or null if none.
  Future<AttendanceModel?> getAttendanceForLabourOnDate({
    required String companyId,
    required String labourId,
    required DateTime date,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      debugPrint(
        'QUERY -> company=$companyId labour=$labourId '
        'start=$startOfDay end=$endOfDay',
      );

      final query = await _attendanceCollection(companyId)
          .where('labourId', isEqualTo: labourId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();
      debugPrint('QUERY RESULT -> docs=${query.docs.length}');

      if (query.docs.isEmpty) return null;

      return AttendanceModel.fromFirestore(query.docs.first);
    } catch (e) {
      rethrow;
    }
  }
}



