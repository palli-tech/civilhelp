import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:civilhelp/core/enums/labour_status.dart';
import 'package:civilhelp/core/enums/payment_mode.dart';
import 'package:civilhelp/features/labour/domain/entities/labour_entity.dart';

class LabourModel extends LabourEntity {
  LabourModel({
    required super.id,
    required super.fullName,
    required super.phoneNumber,
    required super.aadhaarNumber,
    required super.dailyWage,
    super.paymentMode = PaymentMode.dailyWage,
    required super.assignedSiteId,
    required super.assignedSiteName,
    required super.status,
    required super.joinedDate,
    required super.companyId,
    required super.createdAt,
    required super.createdBy,
    super.deactivatedAt,
  });

  factory LabourModel.fromMap(Map<String, dynamic> map, String documentId) {
    return LabourModel(
      id: documentId,
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      aadhaarNumber: map['aadhaarNumber'] ?? '',
      dailyWage: (map['dailyWage'] as num?)?.toDouble() ?? 0.0,
      paymentMode: map['paymentMode'] != null
          ? PaymentMode.values.firstWhere(
              (e) => e.name == map['paymentMode'],
              orElse: () => PaymentMode.dailyWage,
            )
          : PaymentMode.dailyWage,
      assignedSiteId: map['assignedSiteId'] ?? '',
      assignedSiteName: map['assignedSiteName'] ?? '',
      status: LabourStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => LabourStatus.active,
      ),
      joinedDate: map['joinedDate'] != null
          ? (map['joinedDate'] as Timestamp).toDate()
          : DateTime.now(),
      companyId: map['companyId'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      createdBy: map['createdBy'] ?? '',
      deactivatedAt: map['deactivatedAt'] != null
          ? (map['deactivatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  factory LabourModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    if (data == null) {
      throw Exception('Labour document does not exist');
    }

    return LabourModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'aadhaarNumber': aadhaarNumber,
      'dailyWage': dailyWage,
      'paymentMode': paymentMode.name,
      'assignedSiteId': assignedSiteId,
      'assignedSiteName': assignedSiteName,
      'status': status.name,
      'joinedDate': Timestamp.fromDate(joinedDate),
      'companyId': companyId,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'deactivatedAt': deactivatedAt != null ? Timestamp.fromDate(deactivatedAt!) : null,
    };
  }

  @override
  LabourModel copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    String? aadhaarNumber,
    double? dailyWage,
    PaymentMode? paymentMode,
    String? assignedSiteId,
    String? assignedSiteName,
    LabourStatus? status,
    DateTime? joinedDate,
    String? companyId,
    DateTime? createdAt,
    String? createdBy,
    DateTime? deactivatedAt,
  }) {
    return LabourModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      dailyWage: dailyWage ?? this.dailyWage,
      paymentMode: paymentMode ?? this.paymentMode,
      assignedSiteId: assignedSiteId ?? this.assignedSiteId,
      assignedSiteName: assignedSiteName ?? this.assignedSiteName,
      status: status ?? this.status,
      joinedDate: joinedDate ?? this.joinedDate,
      companyId: companyId ?? this.companyId,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      deactivatedAt: deactivatedAt ?? this.deactivatedAt,
    );
  }

  LabourEntity toEntity() {
    return LabourEntity(
      id: id,
      fullName: fullName,
      phoneNumber: phoneNumber,
      aadhaarNumber: aadhaarNumber,
      dailyWage: dailyWage,
      paymentMode: paymentMode,
      assignedSiteId: assignedSiteId,
      assignedSiteName: assignedSiteName,
      status: status,
      joinedDate: joinedDate,
      companyId: companyId,
      createdAt: createdAt,
      createdBy: createdBy,
      deactivatedAt: deactivatedAt,
    );
  }
}
