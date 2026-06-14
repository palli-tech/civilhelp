import 'package:cloud_firestore/cloud_firestore.dart';

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

  /// Generate a deterministic document ID to prevent duplicate worker/site/date logs
  String generateAttendanceDocId({
    required String labourId,
    required String siteId,
    required DateTime date,
  }) {
    final dateString = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return "${labourId}_${siteId}_$dateString";
  }

  /// Check company backdate configuration limit
  Future<void> _checkBackdateLimit({
    required String companyId,
    required DateTime date,
  }) async {
    final companyDoc = await _firestore.collection('companies').doc(companyId).get();
    final limitDays = companyDoc.data()?['attendanceBackdateLimitDays'] as int? ?? 3;
    
    final today = DateTime.now();
    final maxBackdateDate = DateTime(today.year, today.month, today.day).subtract(Duration(days: limitDays));
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate.isBefore(maxBackdateDate)) {
      throw Exception('Attendance date exceeds the company backdate limit of $limitDays days.');
    }
  }

  /// Finds the payroll period document whose date range encloses [date], if any.
  ///
  /// Returns the period document ID to stamp on the attendance record, or null
  /// if no period covers this date (attendance floats — Q1 decision).
  /// Also enforces the payroll lock: throws if the enclosing period is frozen or paid.
  Future<String?> _findEnclosingPeriodId({
    required String companyId,
    required DateTime date,
    required String action, // 'create', 'modify', 'delete'
  }) async {
    final dateTs = Timestamp.fromDate(date);

    // Query: periods that started on or before this attendance date.
    // We limit to 10 and filter by endDate in Dart (endDate can't be in a Firestore
    // inequality alongside startDate without a composite index on both).
    final snap = await _firestore
        .collection('companies/$companyId/payrollPeriods')
        .where('startDate', isLessThanOrEqualTo: dateTs)
        .orderBy('startDate', descending: true)
        .limit(10)
        .get();

    for (final doc in snap.docs) {
      final endDate = (doc.data()['endDate'] as Timestamp?)?.toDate();
      if (endDate == null) continue;

      // Check if the attendance date falls within this period's end boundary.
      if (!date.isAfter(endDate)) {
        final status = doc.data()['status'] as String? ?? 'open';
        if (status == 'frozen' || status == 'paid') {
          final periodName = doc.data()['name'] as String? ?? doc.id;
          if (action == 'delete') {
            throw Exception(
              'Cannot delete attendance: payroll period "$periodName" is $status.');
          } else if (action == 'modify') {
            throw Exception(
              'Cannot modify attendance: payroll period "$periodName" is $status.');
          } else {
            throw Exception(
              'Cannot create attendance: payroll period "$periodName" is $status.');
          }
        }
        return doc.id;
      }
    }

    // No enclosing period found — attendance floats (payrollPeriodId = null).
    return null;
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

    // 1. Enforce backdate limit
    await _checkBackdateLimit(companyId: companyId, date: date);

    // 2. Find enclosing payroll period and check lock
    final periodId = await _findEnclosingPeriodId(
      companyId: companyId,
      date: date,
      action: 'create',
    );

    // 3. Fetch Labour and Site details to write immutable snapshots
    final labourDoc = await _firestore.collection(FirestorePathService.labour(companyId)).doc(labourId).get();
    if (!labourDoc.exists) {
      throw Exception('Labour record not found.');
    }
    final workerStatus = labourDoc.data()?['status'] as String? ?? 'active';
    if (workerStatus != 'active') {
      throw Exception('Cannot log attendance for inactive worker.');
    }
    final dailyWageSnapshot = (labourDoc.data()?['dailyWage'] as num?)?.toDouble() ?? 0.0;
    final labourNameSnapshot = labourDoc.data()?['fullName'] as String? ?? labourName;

    final siteDoc = await _firestore.collection(FirestorePathService.sites(companyId)).doc(siteId).get();
    final siteNameSnapshot = siteDoc.data()?['name'] as String? ?? siteName;
    final double earningsSnapshot = musterQuantity * dailyWageSnapshot;

    // 4. Generate deterministic document ID
    final docId = generateAttendanceDocId(labourId: labourId, siteId: siteId, date: date);
    final docRef = _attendanceCollection(companyId).doc(docId);

    final data = {
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
      
      'dailyWageSnapshot': dailyWageSnapshot,
      'earningsSnapshot': earningsSnapshot,
      'labourNameSnapshot': labourNameSnapshot,
      'siteNameSnapshot': siteNameSnapshot,
      
      'payrollPeriodId': periodId,
      'paymentStatus': 'unpaid',
      'paymentId': null,
      'isDeleted': false,
    };

    await docRef.set(data);
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

    // 1. Enforce backdate limit once for performance
    await _checkBackdateLimit(companyId: companyId, date: date);

    // 2. Find enclosing payroll period and check lock
    final periodId = await _findEnclosingPeriodId(
      companyId: companyId,
      date: date,
      action: 'create',
    );

    // 3. Fetch metadata in bulk to compile snapshots efficiently
    final siteDoc = await _firestore.collection(FirestorePathService.sites(companyId)).doc(siteId).get();
    final siteNameSnapshot = siteDoc.data()?['name'] as String? ?? siteName;

    final labourSnap = await _firestore.collection(FirestorePathService.labour(companyId)).get();
    final labourWages = {for (var doc in labourSnap.docs) doc.id: (doc.data()['dailyWage'] as num?)?.toDouble() ?? 0.0};
    final labourNames = {for (var doc in labourSnap.docs) doc.id: doc.data()['fullName'] as String? ?? ''};
    final labourStatuses = {for (var doc in labourSnap.docs) doc.id: doc.data()['status'] as String? ?? 'active'};

    int skipped = 0;
    int created = 0;

    WriteBatch batch = _firestore.batch();
    int batchCount = 0;

    final attendanceCollection = _attendanceCollection(companyId);

    for (final record in labourRecords) {
      final docId = generateAttendanceDocId(labourId: record.labourId, siteId: siteId, date: date);
      final docRef = attendanceCollection.doc(docId);

      // Verify status: skip inactive
      final workerStatus = labourStatuses[record.labourId] ?? 'active';
      if (workerStatus != 'active') {
        skipped++;
        continue;
      }

      // Verify existing document (active log) to prevent duplicates
      final existingDoc = await docRef.get();
      if (existingDoc.exists && !(existingDoc.data()?['isDeleted'] as bool? ?? false)) {
        skipped++;
        continue;
      }

      final wage = labourWages[record.labourId] ?? 0.0;
      final nameSnap = labourNames[record.labourId] ?? record.labourName;
      final double earnings = record.musterQuantity * wage;

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
        
        'dailyWageSnapshot': wage,
        'earningsSnapshot': earnings,
        'labourNameSnapshot': nameSnap,
        'siteNameSnapshot': siteNameSnapshot,
        
        'payrollPeriodId': periodId,
        'paymentStatus': 'unpaid',
        'paymentId': null,
        'isDeleted': false,
      });

      created++;
      batchCount++;

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

  Future<void> updateAttendance({
    required AttendanceModel attendance,
    required String updatedBy,
  }) async {
    final expectedId = generateAttendanceDocId(
      labourId: attendance.labourId,
      siteId: attendance.siteId,
      date: attendance.date,
    );
    if (expectedId != attendance.id) {
      throw Exception('Cannot modify the identity fields (date, labour, or site) of an existing attendance record.');
    }

    final docRef = _attendanceCollection(attendance.companyId).doc(attendance.id);
    final snap = await docRef.get();
    if (!snap.exists) {
      throw Exception('Attendance record not found.');
    }

    // 1. Find enclosing payroll period and check lock
    final periodId = await _findEnclosingPeriodId(
      companyId: attendance.companyId,
      date: attendance.date,
      action: 'modify',
    );

    // 2. Lock updates if attendance is already paid
    final existingPaymentStatus = snap.data()?['paymentStatus'] as String? ?? 'unpaid';
    if (existingPaymentStatus == 'paid') {
      throw Exception('Cannot modify attendance record that is paid.');
    }

    // Enforce backdate limits on date updates
    await _checkBackdateLimit(companyId: attendance.companyId, date: attendance.date);

    final double dailyWage = (snap.data()?['dailyWageSnapshot'] as num?)?.toDouble() ?? 0.0;
    final double earnings = attendance.musterQuantity * dailyWage;

    await docRef.update({
      'date': Timestamp.fromDate(attendance.date),
      'status': attendance.status,
      'hoursWorked': attendance.hoursWorked,
      'musterQuantity': attendance.musterQuantity,
      'earningsSnapshot': earnings,
      'payrollPeriodId': periodId,
      'updatedAt': Timestamp.now(),
      'updatedBy': updatedBy,
    });
  }

  /// Soft deletes an attendance record
  Future<void> deleteAttendance({
    required String attendanceId,
    required String companyId,
    required String deletedBy,
    required String deleteReason,
  }) async {
    final docRef = _attendanceCollection(companyId).doc(attendanceId);
    final snap = await docRef.get();
    if (!snap.exists) {
      throw Exception('Attendance record not found.');
    }

    // 1. Find enclosing payroll period and check lock
    final existingDate = (snap.data()?['date'] as Timestamp).toDate();
    await _findEnclosingPeriodId(
      companyId: companyId,
      date: existingDate,
      action: 'delete',
    );

    // 2. Lock deletes if attendance is already paid
    final existingPaymentStatus = snap.data()?['paymentStatus'] as String? ?? 'unpaid';
    if (existingPaymentStatus == 'paid') {
      throw Exception('Cannot delete attendance record that is paid.');
    }

    await docRef.update({
      'isDeleted': true,
      'deletedBy': deletedBy,
      'deletedAt': Timestamp.now(),
      'deleteReason': deleteReason,
      'updatedAt': Timestamp.now(),
      'updatedBy': deletedBy,
    });
  }

  Stream<List<AttendanceModel>> getAttendanceByCompanyStream(
    String companyId,
  ) {
    try {
      return _attendanceCollection(companyId)
          .where('isDeleted', isEqualTo: false)
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
          .where('isDeleted', isEqualTo: false)
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
          .where('isDeleted', isEqualTo: false)
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
          .where('isDeleted', isEqualTo: false)
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
      final query = await _attendanceCollection(companyId)
          .where('labourId', isEqualTo: labourId)
          .where('isDeleted', isEqualTo: false)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      final activeDocs = query.docs
          .map((doc) => AttendanceModel.fromFirestore(doc))
          .toList();

      if (activeDocs.isEmpty) return null;
      return activeDocs.first;
    } catch (e) {
      rethrow;
    }
  }

  /// Migration Utility: Migrates legacy records to the deterministic ID scheme and fills snapshots
  Future<void> migrateLegacyRecords({required String companyId}) async {
    final snap = await _attendanceCollection(companyId).get();
    final batch = _firestore.batch();
    int migrated = 0;

    for (final doc in snap.docs) {
      final docId = doc.id;
      final data = doc.data();
      final labourId = data['labourId'] as String? ?? '';
      final siteId = data['siteId'] as String? ?? '';
      final dateTimestamp = data['date'] as Timestamp?;
      
      if (labourId.isEmpty || siteId.isEmpty || dateTimestamp == null) continue;
      
      final date = dateTimestamp.toDate();
      final deterministicId = generateAttendanceDocId(labourId: labourId, siteId: siteId, date: date);
      
      // If already correct ID, check if snapshot details are set, otherwise skip
      if (docId == deterministicId && data.containsKey('dailyWageSnapshot')) continue;

      // Fetch labour details for snapshots, but fallback to any stored values first to preserve history
      final labourDoc = await _firestore.collection(FirestorePathService.labour(companyId)).doc(labourId).get();
      final dailyWage = (data['dailyWageSnapshot'] as num?)?.toDouble() ??
                        (data['dailyWage'] as num?)?.toDouble() ??
                        (labourDoc.data()?['dailyWage'] as num?)?.toDouble() ?? 0.0;
      
      final labourNameSnapshot = (data['labourNameSnapshot'] as String?) ??
                                 (labourDoc.data()?['fullName'] as String?) ??
                                 (data['labourName'] as String? ?? '');
      
      final siteDoc = await _firestore.collection(FirestorePathService.sites(companyId)).doc(siteId).get();
      final siteNameSnapshot = (data['siteNameSnapshot'] as String?) ??
                               (siteDoc.data()?['name'] as String?) ??
                               (data['siteName'] as String? ?? '');

      final double musterQty = (data['musterQuantity'] as num? ?? 1.0).toDouble();
      final double earnings = (data['earningsSnapshot'] as num?)?.toDouble() ??
                              (data['earnings'] as num?)?.toDouble() ??
                              (musterQty * dailyWage);

      final targetDocRef = _attendanceCollection(companyId).doc(deterministicId);
      batch.set(targetDocRef, {
        ...data,
        'dailyWageSnapshot': dailyWage,
        'earningsSnapshot': earnings,
        'labourNameSnapshot': labourNameSnapshot,
        'siteNameSnapshot': siteNameSnapshot,
        'paymentStatus': data['paymentStatus'] ?? 'open',
        'isDeleted': data['isDeleted'] ?? false,
      });

      // If old doc had random ID, soft delete/remove it
      if (docId != deterministicId) {
        batch.delete(doc.reference);
      }

      migrated++;
      if (migrated == 499) {
        await batch.commit();
        return migrateLegacyRecords(companyId: companyId); // recursive next batch
      }
    }

    if (migrated > 0) {
      await batch.commit();
    }
  }

  /// Scans the attendance collection for legacy structures and missing fields.
  ///
  /// Returns a summary report containing statistics on:
  /// - totalRecords
  /// - legacyStatusCount (paymentStatus == "open")
  /// - missingPaymentStatus
  /// - missingPayrollPeriodId
  /// - missingPaymentId
  /// - missingIsDeleted
  /// - recordsMissingRequiredFields (any record having one or more of the above issues)
  Future<Map<String, dynamic>> scanLegacyAttendance({
    required String companyId,
  }) async {
    final snap = await _attendanceCollection(companyId).get();
    
    int totalRecords = 0;
    int legacyStatusCount = 0;
    int missingPaymentStatus = 0;
    int missingPayrollPeriodId = 0;
    int missingPaymentId = 0;
    int missingIsDeleted = 0;
    int recordsMissingRequiredFields = 0;

    final List<String> corruptDocIds = [];

    for (final doc in snap.docs) {
      totalRecords++;
      final data = doc.data() as Map<String, dynamic>;
      
      bool hasIssue = false;

      // 1. paymentStatus check
      if (data['paymentStatus'] == 'open') {
        legacyStatusCount++;
        hasIssue = true;
      }
      if (!data.containsKey('paymentStatus')) {
        missingPaymentStatus++;
        hasIssue = true;
      }

      // 2. payrollPeriodId check
      if (!data.containsKey('payrollPeriodId')) {
        missingPayrollPeriodId++;
        hasIssue = true;
      }

      // 3. paymentId check
      if (!data.containsKey('paymentId')) {
        missingPaymentId++;
        hasIssue = true;
      }

      // 4. isDeleted check
      if (!data.containsKey('isDeleted')) {
        missingIsDeleted++;
        hasIssue = true;
      }

      if (hasIssue) {
        recordsMissingRequiredFields++;
        corruptDocIds.add(doc.id);
      }
    }

    return {
      'totalRecords': totalRecords,
      'legacyStatusCount': legacyStatusCount,
      'missingPaymentStatus': missingPaymentStatus,
      'missingPayrollPeriodId': missingPayrollPeriodId,
      'missingPaymentId': missingPaymentId,
      'missingIsDeleted': missingIsDeleted,
      'recordsMissingRequiredFields': recordsMissingRequiredFields,
      'corruptDocIds': corruptDocIds,
    };
  }
}



