import 'package:civilhelp/core/enums/labour_status.dart';

class LabourEntity {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String aadhaarNumber;
  final double dailyWage;
  final String assignedSiteId;
  final String assignedSiteName;
  final LabourStatus status;
  final DateTime joinedDate;
  final String companyId;
  final DateTime createdAt;
  final String createdBy;

  const LabourEntity({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.aadhaarNumber,
    required this.dailyWage,
    required this.assignedSiteId,
    required this.assignedSiteName,
    required this.status,
    required this.joinedDate,
    required this.companyId,
    required this.createdAt,
    required this.createdBy,
  });

  LabourEntity copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    String? aadhaarNumber,
    double? dailyWage,
    String? assignedSiteId,
    String? assignedSiteName,
    LabourStatus? status,
    DateTime? joinedDate,
    String? companyId,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return LabourEntity(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      dailyWage: dailyWage ?? this.dailyWage,
      assignedSiteId: assignedSiteId ?? this.assignedSiteId,
      assignedSiteName: assignedSiteName ?? this.assignedSiteName,
      status: status ?? this.status,
      joinedDate: joinedDate ?? this.joinedDate,
      companyId: companyId ?? this.companyId,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
