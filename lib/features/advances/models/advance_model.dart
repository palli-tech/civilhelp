import 'package:cloud_firestore/cloud_firestore.dart';

class AdvanceModel {
  final String id;
  final String companyId;
  final String labourId;
  final String labourName;
  final double amount;
  final double recoveredAmount;
  final double remainingAmount; // remainingAmount = amount - recoveredAmount
  final String status; // 'pending', 'partial', 'recovered'
  final DateTime date;
  final String description;
  final DateTime createdAt;
  final String createdBy;

  const AdvanceModel({
    required this.id,
    required this.companyId,
    required this.labourId,
    required this.labourName,
    required this.amount,
    required this.recoveredAmount,
    required this.remainingAmount,
    required this.status,
    required this.date,
    required this.description,
    required this.createdAt,
    required this.createdBy,
  });

  factory AdvanceModel.fromMap(Map<String, dynamic> map, String documentId) {
    final amount = (map['amount'] as num?)?.toDouble() ?? 0.0;
    final recoveredAmount = (map['recoveredAmount'] as num?)?.toDouble() ?? 0.0;
    final remainingAmount = amount - recoveredAmount;
    
    // Resolve status based on recovered/total
    String resolvedStatus = map['status'] ?? 'pending';
    if (recoveredAmount <= 0) {
      resolvedStatus = 'pending';
    } else if (recoveredAmount >= amount) {
      resolvedStatus = 'recovered';
    } else {
      resolvedStatus = 'partial';
    }

    return AdvanceModel(
      id: documentId,
      companyId: map['companyId'] ?? '',
      labourId: map['labourId'] ?? '',
      labourName: map['labourName'] ?? '',
      amount: amount,
      recoveredAmount: recoveredAmount,
      remainingAmount: remainingAmount,
      status: resolvedStatus,
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: map['description'] ?? map['reason'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
    );
  }

  factory AdvanceModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Advance document does not exist');
    }
    return AdvanceModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'labourId': labourId,
      'labourName': labourName,
      'amount': amount,
      'recoveredAmount': recoveredAmount,
      'remainingAmount': remainingAmount,
      'status': status,
      'date': Timestamp.fromDate(date),
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  AdvanceModel copyWith({
    String? id,
    String? companyId,
    String? labourId,
    String? labourName,
    double? amount,
    double? recoveredAmount,
    double? remainingAmount,
    String? status,
    DateTime? date,
    String? description,
    DateTime? createdAt,
    String? createdBy,
  }) {
    final newAmount = amount ?? this.amount;
    final newRecoveredAmount = recoveredAmount ?? this.recoveredAmount;
    return AdvanceModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      labourId: labourId ?? this.labourId,
      labourName: labourName ?? this.labourName,
      amount: newAmount,
      recoveredAmount: newRecoveredAmount,
      remainingAmount: remainingAmount ?? (newAmount - newRecoveredAmount),
      status: status ?? this.status,
      date: date ?? this.date,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  // Compatibility Getters for Reports/UI
  String get reason => description;
  String get siteId => '';
  String get siteName => 'All Sites';
}
