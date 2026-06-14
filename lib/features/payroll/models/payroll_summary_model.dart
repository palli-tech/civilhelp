import 'package:cloud_firestore/cloud_firestore.dart';

class PayrollSummaryModel {
  final String periodId;
  final String companyId;
  final int totalWorkers;
  final double totalGross;
  final double totalDeductions;
  final double totalNetPaid;
  final DateTime createdAt;
  final String createdBy;

  const PayrollSummaryModel({
    required this.periodId,
    required this.companyId,
    required this.totalWorkers,
    required this.totalGross,
    required this.totalDeductions,
    required this.totalNetPaid,
    required this.createdAt,
    required this.createdBy,
  });

  factory PayrollSummaryModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PayrollSummaryModel(
      periodId: documentId,
      companyId: map['companyId'] ?? '',
      totalWorkers: map['totalWorkers'] as int? ?? 0,
      totalGross: (map['totalGross'] as num?)?.toDouble() ?? 0.0,
      totalDeductions: (map['totalDeductions'] as num?)?.toDouble() ?? 0.0,
      totalNetPaid: (map['totalNetPaid'] as num?)?.toDouble() ?? 0.0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
    );
  }

  factory PayrollSummaryModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Payroll summary document does not exist');
    }
    return PayrollSummaryModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'totalWorkers': totalWorkers,
      'totalGross': totalGross,
      'totalDeductions': totalDeductions,
      'totalNetPaid': totalNetPaid,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  PayrollSummaryModel copyWith({
    String? periodId,
    String? companyId,
    int? totalWorkers,
    double? totalGross,
    double? totalDeductions,
    double? totalNetPaid,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return PayrollSummaryModel(
      periodId: periodId ?? this.periodId,
      companyId: companyId ?? this.companyId,
      totalWorkers: totalWorkers ?? this.totalWorkers,
      totalGross: totalGross ?? this.totalGross,
      totalDeductions: totalDeductions ?? this.totalDeductions,
      totalNetPaid: totalNetPaid ?? this.totalNetPaid,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
