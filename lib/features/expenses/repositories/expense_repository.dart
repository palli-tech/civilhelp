import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firestore_path_service.dart';
import '../models/expense_category.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  final FirebaseFirestore _firestore;

  ExpenseRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _expensesCollection(
    String companyId,
  ) {
    return _firestore.collection(
      FirestorePathService.expenses(companyId),
    );
  }

  /// Create a new expense
  Future<ExpenseModel> createExpense({
    required String companyId,
    required double amount,
    required ExpenseCategory category,
    required DateTime date,
    required String description,
    String? siteId,
    String? receiptUrl,
    required String createdBy,
  }) async {
    final docRef = await _expensesCollection(companyId).add({
      'companyId': companyId,
      'siteId': siteId,
      'amount': amount,
      'category': category.name,
      'date': Timestamp.fromDate(date),
      'description': description,
      'receiptUrl': receiptUrl,
      'isDeleted': false,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': createdBy,
      'deletedAt': null,
      'deletedBy': null,
    });

    final doc = await docRef.get();
    return ExpenseModel.fromFirestore(doc);
  }

  /// Update an existing expense
  Future<void> updateExpense(ExpenseModel expense) async {
    await _expensesCollection(expense.companyId).doc(expense.id).update({
      ...expense.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Soft delete an expense
  Future<void> softDeleteExpense({
    required String companyId,
    required String expenseId,
    required String deletedBy,
  }) async {
    await _expensesCollection(companyId).doc(expenseId).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'deletedBy': deletedBy,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': deletedBy,
    });
  }

  /// Fetch a single expense by ID
  Future<ExpenseModel?> getExpenseById({
    required String companyId,
    required String expenseId,
  }) async {
    final doc = await _expensesCollection(companyId).doc(expenseId).get();
    if (doc.exists) {
      final model = ExpenseModel.fromFirestore(doc);
      if (!model.isDeleted) {
        return model;
      }
    }
    return null;
  }

  /// Fetch active expenses for a company as a stream
  Stream<List<ExpenseModel>> getExpensesStream(String companyId) {
    try {
      return _expensesCollection(companyId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => ExpenseModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      return Stream.error(e);
    }
  }

  /// Fetch active expenses for a company filtered by site as a stream
  Stream<List<ExpenseModel>> getExpensesBySiteStream(
    String companyId,
    String siteId,
  ) {
    try {
      return _expensesCollection(companyId)
          .where('isDeleted', isEqualTo: false)
          .where('siteId', isEqualTo: siteId)
          .snapshots()
          .map((snapshot) {
        final list = snapshot.docs
            .map((doc) => ExpenseModel.fromFirestore(doc))
            .toList();
        list.sort((a, b) => b.date.compareTo(a.date));
        return list;
      });
    } catch (e) {
      return Stream.error(e);
    }
  }

  /// Fetch active expenses for a company filtered by date range as a stream
  Stream<List<ExpenseModel>> getExpensesByDateRangeStream({
    required String companyId,
    required DateTime start,
    required DateTime end,
  }) {
    try {
      return _expensesCollection(companyId)
          .where('isDeleted', isEqualTo: false)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThan: Timestamp.fromDate(end))
          .snapshots()
          .map((snapshot) {
        final list = snapshot.docs
            .map((doc) => ExpenseModel.fromFirestore(doc))
            .toList();
        list.sort((a, b) => b.date.compareTo(a.date));
        return list;
      });
    } catch (e) {
      return Stream.error(e);
    }
  }

  /// Fetch active expenses for a company filtered by date range as a Future list
  Future<List<ExpenseModel>> getExpensesByDateRange({
    required String companyId,
    required DateTime start,
    required DateTime end,
  }) async {
    final snapshot = await _expensesCollection(companyId)
        .where('isDeleted', isEqualTo: false)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();

    final list = snapshot.docs
        .map((doc) => ExpenseModel.fromFirestore(doc))
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// Future aggregate: Get total expenses in a date range (excluding soft deleted)
  Future<double> getTotalExpensesForDateRange({
    required String companyId,
    required DateTime start,
    required DateTime end,
  }) async {
    final snapshot = await _expensesCollection(companyId)
        .where('isDeleted', isEqualTo: false)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();

    return snapshot.docs.fold<double>(
      0.0,
      (total, doc) => total + ((doc.data()['amount'] as num?)?.toDouble() ?? 0.0),
    );
  }

  /// Future aggregate: Get total expenses associated with a specific site
  Future<double> getTotalExpensesForSite({
    required String companyId,
    required String siteId,
  }) async {
    final snapshot = await _expensesCollection(companyId)
        .where('isDeleted', isEqualTo: false)
        .where('siteId', isEqualTo: siteId)
        .get();

    return snapshot.docs.fold<double>(
      0.0,
      (total, doc) => total + ((doc.data()['amount'] as num?)?.toDouble() ?? 0.0),
    );
  }
}
