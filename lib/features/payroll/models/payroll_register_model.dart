import 'package:cloud_firestore/cloud_firestore.dart';

class PayrollRegisterModel {
  final String id;
  final String companyId;
  final String periodId;
  final String labourId;
  final String labourName;
  final int presentDays;
  final double grossEarnings;
  final double advanceDeductions;
  final double netPayable;
  final String? paymentId;
  final DateTime createdAt;
  final String createdBy;

  const PayrollRegisterModel({
    required this.id,
    required this.companyId,
    required this.periodId,
    required this.labourId,
    required this.labourName,
    required this.presentDays,
    required this.grossEarnings,
    required this.advanceDeductions,
    required this.netPayable,
    this.paymentId,
    required this.createdAt,
    required this.createdBy,
  });

  factory PayrollRegisterModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PayrollRegisterModel(
      id: documentId,
      companyId: map['companyId'] ?? '',
      periodId: map['periodId'] ?? '',
      labourId: map['labourId'] ?? '',
      labourName: map['labourName'] ?? '',
      presentDays: map['presentDays'] as int? ?? 0,
      grossEarnings: (map['grossEarnings'] as num?)?.toDouble() ?? 0.0,
      advanceDeductions: (map['advanceDeductions'] as num?)?.toDouble() ?? 0.0,
      netPayable: (map['netPayable'] as num?)?.toDouble() ?? 0.0,
      paymentId: map['paymentId'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
    );
  }

  factory PayrollRegisterModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Payroll register document does not exist');
    }
    return PayrollRegisterModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'periodId': periodId,
      'labourId': labourId,
      'labourName': labourName,
      'presentDays': presentDays,
      'grossEarnings': grossEarnings,
      'advanceDeductions': advanceDeductions,
      'netPayable': netPayable,
      'paymentId': paymentId,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  PayrollRegisterModel copyWith({
    String? id,
    String? companyId,
    String? periodId,
    String? labourId,
    String? labourName,
    int? presentDays,
    double? grossEarnings,
    double? advanceDeductions,
    double? netPayable,
    String? paymentId,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return PayrollRegisterModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      periodId: periodId ?? this.periodId,
      labourId: labourId ?? this.labourId,
      labourName: labourName ?? this.labourName,
      presentDays: presentDays ?? this.presentDays,
      grossEarnings: grossEarnings ?? this.grossEarnings,
      advanceDeductions: advanceDeductions ?? this.advanceDeductions,
      netPayable: netPayable ?? this.netPayable,
      paymentId: paymentId ?? this.paymentId,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
