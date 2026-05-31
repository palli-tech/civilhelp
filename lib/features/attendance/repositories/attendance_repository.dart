import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/attendance_model.dart';

class AttendanceRepository {
  final FirebaseFirestore _firestore;

  AttendanceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<AttendanceModel> createAttendance({
    required String labourId,
    required String labourName,
    required String siteId,
    required String siteName,
    required DateTime date,
    required String status,
    required double hoursWorked,
    required String companyId,
    required String createdBy,
  }) async {
    final docRef = await _firestore.collection('attendance').add({
      'labourId': labourId,
      'labourName': labourName,
      'siteId': siteId,
      'siteName': siteName,
      'date': Timestamp.fromDate(date),
      'status': status,
      'hoursWorked': hoursWorked,
      'companyId': companyId,
      'createdAt': Timestamp.now(),
      'createdBy': createdBy,
    });

    final doc = await docRef.get();
    return AttendanceModel.fromFirestore(doc);
  }

Future<void> updateAttendance(AttendanceModel attendance) async {
  await _firestore
      .collection('attendance')
      .doc(attendance.id)
      .update({
    'labourId': attendance.labourId,
    'labourName': attendance.labourName,
    'siteId': attendance.siteId,
    'siteName': attendance.siteName,
    'date': Timestamp.fromDate(attendance.date),
    'status': attendance.status,
    'hoursWorked': attendance.hoursWorked,
    'updatedAt': Timestamp.now(),
  });
}

Future<void> deleteAttendance(String attendanceId) async {
  await _firestore
      .collection('attendance')
      .doc(attendanceId)
      .delete();
}
  Stream<List<AttendanceModel>> getAttendanceByCompanyStream(String companyId) {
    try {
      return _firestore
          .collection('attendance')
          .where('companyId', isEqualTo: companyId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => AttendanceModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      return Stream.error(e);
    }
  }

  Stream<List<AttendanceModel>> getAttendanceBySiteStream(
    String companyId,
    String siteId,
  ) {
    try {
      return _firestore
          .collection('attendance')
          .where('companyId', isEqualTo: companyId)
          .where('siteId', isEqualTo: siteId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => AttendanceModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      return Stream.error(e);
    }
  }

  Stream<List<AttendanceModel>> getAttendanceByLabourStream(
    String companyId,
    String labourId,
  ) {
    try {
      return _firestore
          .collection('attendance')
          .where('companyId', isEqualTo: companyId)
          .where('labourId', isEqualTo: labourId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => AttendanceModel.fromFirestore(doc))
              .toList());
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
      return _firestore
          .collection('attendance')
          .where('companyId', isEqualTo: companyId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThan: Timestamp.fromDate(end))
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => AttendanceModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      return Stream.error(e);
    }
  }

  Stream<List<AttendanceModel>> getAttendanceForTodayStream(String companyId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      return getAttendanceByDateRangeStream(companyId, startOfDay, endOfDay);
    } catch (e) {
      return Stream.error(e);
    }
  }
}
