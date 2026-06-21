import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String labourId;
  final String labourName;
  final String siteId;
  final String siteName;
  final DateTime date;
  final String status;
  final double hoursWorked;
  final double musterQuantity;
  final String companyId;
  final DateTime createdAt;
  final String createdBy;

  // Snapshot Fields
  final double dailyWageSnapshot;
  final double earningsSnapshot;
  final String labourNameSnapshot;
  final String siteNameSnapshot;

  // Audit Fields
  final String? updatedBy;
  final DateTime? updatedAt;

  // Soft Delete Fields
  final bool isDeleted;
  final String? deletedBy;
  final DateTime? deletedAt;
  final String? deleteReason;

  // Payroll / Settlement Fields
  final String? payrollPeriodId;
  final String paymentStatus; // unpaid, paid
  final String? paymentId;

  const AttendanceModel({
    required this.id,
    required this.labourId,
    required this.labourName,
    required this.siteId,
    required this.siteName,
    required this.date,
    required this.status,
    required this.hoursWorked,
    required this.musterQuantity,
    required this.companyId,
    required this.createdAt,
    required this.createdBy,
    required this.dailyWageSnapshot,
    required this.earningsSnapshot,
    required this.labourNameSnapshot,
    required this.siteNameSnapshot,
    this.updatedBy,
    this.updatedAt,
    this.isDeleted = false,
    this.deletedBy,
    this.deletedAt,
    this.deleteReason,
    this.payrollPeriodId,
    this.paymentStatus = 'unpaid',
    this.paymentId,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String documentId) {
    final status = map['status'] ?? 'unknown';
    final dailyWageSnapshot = (map['dailyWageSnapshot'] as num?)?.toDouble() ?? 
                              (map['dailyWage'] as num?)?.toDouble() ?? 0.0;
    
    final double defaultEarnings = (map['musterQuantity'] as num? ?? 1.0).toDouble() * dailyWageSnapshot;
    final earningsSnapshot = (map['earningsSnapshot'] as num?)?.toDouble() ?? defaultEarnings;

    var pStatus = map['paymentStatus'] ?? 'unpaid';
    if (pStatus == 'open') pStatus = 'unpaid'; // backward compatibility

    return AttendanceModel(
      id: documentId,
      labourId: map['labourId'] ?? '',
      labourName: map['labourName'] ?? '',
      siteId: map['siteId'] ?? '',
      siteName: map['siteName'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: status,
      hoursWorked: (map['hoursWorked'] as num?)?.toDouble() ?? 0.0,
      musterQuantity: (map['musterQuantity'] as num?)?.toDouble() ?? 0.0,
      companyId: map['companyId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
      
      dailyWageSnapshot: dailyWageSnapshot,
      earningsSnapshot: earningsSnapshot,
      labourNameSnapshot: map['labourNameSnapshot'] ?? map['labourName'] ?? '',
      siteNameSnapshot: map['siteNameSnapshot'] ?? map['siteName'] ?? '',
      
      updatedBy: map['updatedBy'] as String?,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      
      isDeleted: map['isDeleted'] as bool? ?? false,
      deletedBy: map['deletedBy'] as String?,
      deletedAt: (map['deletedAt'] as Timestamp?)?.toDate(),
      deleteReason: map['deleteReason'] as String?,
      
      payrollPeriodId: map['payrollPeriodId'] as String?,
      paymentStatus: pStatus,
      paymentId: map['paymentId'] as String?,
    );
  }

  factory AttendanceModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Attendance document does not exist');
    }
    return AttendanceModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'labourId': labourId,
      'labourName': labourName,
      'siteId': siteId,
      'siteName': siteName,
      'date': Timestamp.fromDate(date),
      'status': status,
      'hoursWorked': hoursWorked,
      'musterQuantity': musterQuantity,
      'companyId': companyId,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      
      'dailyWageSnapshot': dailyWageSnapshot,
      'earningsSnapshot': earningsSnapshot,
      'labourNameSnapshot': labourNameSnapshot,
      'siteNameSnapshot': siteNameSnapshot,
      
      'updatedBy': updatedBy,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      
      'isDeleted': isDeleted,
      'deletedBy': deletedBy,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'deleteReason': deleteReason,
      
      'payrollPeriodId': payrollPeriodId,
      'paymentStatus': paymentStatus,
      'paymentId': paymentId,
    };
  }

  AttendanceModel copyWith({
    String? id,
    String? labourId,
    String? labourName,
    String? siteId,
    String? siteName,
    DateTime? date,
    String? status,
    double? hoursWorked,
    double? musterQuantity,
    String? companyId,
    DateTime? createdAt,
    String? createdBy,
    double? dailyWageSnapshot,
    double? earningsSnapshot,
    String? labourNameSnapshot,
    String? siteNameSnapshot,
    String? updatedBy,
    DateTime? updatedAt,
    bool? isDeleted,
    String? deletedBy,
    DateTime? deletedAt,
    String? deleteReason,
    String? payrollPeriodId,
    String? paymentStatus,
    String? paymentId,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      labourId: labourId ?? this.labourId,
      labourName: labourName ?? this.labourName,
      siteId: siteId ?? this.siteId,
      siteName: siteName ?? this.siteName,
      date: date ?? this.date,
      status: status ?? this.status,
      hoursWorked: hoursWorked ?? this.hoursWorked,
      musterQuantity: musterQuantity ?? this.musterQuantity,
      companyId: companyId ?? this.companyId,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      dailyWageSnapshot: dailyWageSnapshot ?? this.dailyWageSnapshot,
      earningsSnapshot: earningsSnapshot ?? this.earningsSnapshot,
      labourNameSnapshot: labourNameSnapshot ?? this.labourNameSnapshot,
      siteNameSnapshot: siteNameSnapshot ?? this.siteNameSnapshot,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedBy: deletedBy ?? this.deletedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      deleteReason: deleteReason ?? this.deleteReason,
      payrollPeriodId: payrollPeriodId ?? this.payrollPeriodId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentId: paymentId ?? this.paymentId,
    );
  }

  double calculateEarnings(double dailyWage) {
    return earningsSnapshot;
  }
}
