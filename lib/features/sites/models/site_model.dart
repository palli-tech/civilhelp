import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:civilhelp/core/enums/site_status.dart';

class SiteModel {
  final String id;
  final String name;
  final String location;
  final String client;
  final DateTime startDate;
  final SiteStatus status;
  final String companyId;
  final DateTime createdAt;
  final String createdBy;

  const SiteModel({
    required this.id,
    required this.name,
    required this.location,
    required this.client,
    required this.startDate,
    required this.status,
    required this.companyId,
    required this.createdAt,
    required this.createdBy,
  });

  factory SiteModel.fromMap(Map<String, dynamic> map, String documentId) {
    return SiteModel(
      id: documentId,
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      client: map['client'] ?? '',
      startDate: (map['startDate'] as Timestamp).toDate(),
      status: SiteStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SiteStatus.active,
      ),
      companyId: map['companyId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] ?? '',
    );
  }

  factory SiteModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    if (data == null) {
      throw Exception('Site document does not exist');
    }

    return SiteModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'client': client,
      'startDate': Timestamp.fromDate(startDate),
      'status': status.name,
      'companyId': companyId,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  SiteModel copyWith({
    String? id,
    String? name,
    String? location,
    String? client,
    DateTime? startDate,
    SiteStatus? status,
    String? companyId,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return SiteModel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      client: client ?? this.client,
      startDate: startDate ?? this.startDate,
      status: status ?? this.status,
      companyId: companyId ?? this.companyId,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
