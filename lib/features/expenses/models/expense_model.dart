import 'package:cloud_firestore/cloud_firestore.dart';
import 'expense_category.dart';

class ExpenseModel {
  final String id;
  final String companyId;
  final String? siteId;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String description;
  final String? receiptUrl;
  final bool isDeleted;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final DateTime? deletedAt;
  final String? deletedBy;

  const ExpenseModel({
    required this.id,
    required this.companyId,
    this.siteId,
    required this.amount,
    required this.category,
    required this.date,
    required this.description,
    this.receiptUrl,
    required this.isDeleted,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
    this.deletedBy,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ExpenseModel(
      id: documentId,
      companyId: map['companyId'] ?? '',
      siteId: map['siteId'],
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: ExpenseCategory.fromString(map['category']),
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: map['description'] ?? '',
      receiptUrl: map['receiptUrl'],
      isDeleted: map['isDeleted'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedBy: map['updatedBy'] ?? '',
      deletedAt: (map['deletedAt'] as Timestamp?)?.toDate(),
      deletedBy: map['deletedBy'],
    );
  }

  factory ExpenseModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Expense document does not exist');
    }
    return ExpenseModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'siteId': siteId,
      'amount': amount,
      'category': category.name,
      'date': Timestamp.fromDate(date),
      'description': description,
      'receiptUrl': receiptUrl,
      'isDeleted': isDeleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'deletedBy': deletedBy,
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? companyId,
    String? siteId,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    String? description,
    String? receiptUrl,
    bool? isDeleted,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      siteId: siteId ?? this.siteId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      description: description ?? this.description,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }
}
