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
  final String companyId;
  final DateTime createdAt;
  final String createdBy;

  const AttendanceModel({
    required this.id,
    required this.labourId,
    required this.labourName,
    required this.siteId,
    required this.siteName,
    required this.date,
    required this.status,
    required this.hoursWorked,
    required this.companyId,
    required this.createdAt,
    required this.createdBy,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AttendanceModel(
      id: documentId,
      labourId: map['labourId'] ?? '',
      labourName: map['labourName'] ?? '',
      siteId: map['siteId'] ?? '',
      siteName: map['siteName'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'unknown',
      hoursWorked: (map['hoursWorked'] as num?)?.toDouble() ?? 0.0,
      companyId: map['companyId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
    );
  }

  factory AttendanceModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
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
      'companyId': companyId,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
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
    String? companyId,
    DateTime? createdAt,
    String? createdBy,
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
      companyId: companyId ?? this.companyId,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
