import 'package:cloud_firestore/cloud_firestore.dart';

class Company {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final String gstNumber;
  final String logoUrl;
  final String ownerUid;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  Company({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.gstNumber,
    required this.logoUrl,
    this.ownerUid = '',
    this.createdAt,
    this.updatedAt,
    required this.isActive,
  });

  factory Company.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Company(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      gstNumber: data['gstNumber'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
      ownerUid: data['ownerUid'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'gstNumber': gstNumber,
      'logoUrl': logoUrl,
      'ownerUid': ownerUid,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
      'isActive': isActive,
    };
  }

  Company copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? gstNumber,
    String? logoUrl,
    String? ownerUid,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gstNumber: gstNumber ?? this.gstNumber,
      logoUrl: logoUrl ?? this.logoUrl,
      ownerUid: ownerUid ?? this.ownerUid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
