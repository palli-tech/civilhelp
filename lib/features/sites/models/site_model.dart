import 'package:cloud_firestore/cloud_firestore.dart';

class SiteModel {
  final String id;
  final String name;
  final String location;
  final String client;
  final DateTime startDate;
  final String status;
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

  factory SiteModel.fromMap(Map<String, dynamic> map, String id) {
    return SiteModel(
      id: id,
      name: map['name'] as String? ?? '',
      location: map['location'] as String? ?? '',
      client: map['client'] as String? ?? '',
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] as String? ?? 'active',
      companyId: map['companyId'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] as String? ?? '',
    );
  }

  factory SiteModel.fromFirestore(DocumentSnapshot doc) {
    return SiteModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'client': client,
      'startDate': Timestamp.fromDate(startDate),
      'status': status,
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
    String? status,
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

  @override
  String toString() {
    return 'SiteModel(id: $id, name: $name, location: $location, client: $client, startDate: $startDate, status: $status, companyId: $companyId, createdAt: $createdAt, createdBy: $createdBy)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SiteModel &&
        other.id == id &&
        other.name == name &&
        other.location == location &&
        other.client == client &&
        other.startDate == startDate &&
        other.status == status &&
        other.companyId == companyId &&
        other.createdAt == createdAt &&
        other.createdBy == createdBy;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        location.hashCode ^
        client.hashCode ^
        startDate.hashCode ^
        status.hashCode ^
        companyId.hashCode ^
        createdAt.hashCode ^
        createdBy.hashCode;
  }
}
