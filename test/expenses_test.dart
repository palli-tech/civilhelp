import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civilhelp/core/enums/user_role.dart';
import 'package:civilhelp/core/auth/permissions.dart';
import 'package:civilhelp/features/expenses/index.dart';

void main() {
  group('ExpenseCategory Tests', () {
    test('displays correct displayName labels', () {
      expect(ExpenseCategory.materials.displayName, 'Materials');
      expect(ExpenseCategory.fuel.displayName, 'Fuel');
      expect(ExpenseCategory.transport.displayName, 'Transport');
    });

    test('parses from String correctly and falls back to other', () {
      expect(ExpenseCategory.fromString('materials'), ExpenseCategory.materials);
      expect(ExpenseCategory.fromString('MATERIALS '), ExpenseCategory.materials);
      expect(ExpenseCategory.fromString('transport'), ExpenseCategory.transport);
      expect(ExpenseCategory.fromString('unknown_category'), ExpenseCategory.other);
      expect(ExpenseCategory.fromString(null), ExpenseCategory.other);
    });
  });

  group('ExpenseModel Serialization Tests', () {
    final now = DateTime.now();

    test('converts to map correctly', () {
      final model = ExpenseModel(
        id: 'exp-789',
        companyId: 'comp-123',
        siteId: 'site-456',
        amount: 1500.50,
        category: ExpenseCategory.materials,
        date: now,
        description: 'Buy cement bags',
        receiptUrl: 'https://example.com/receipt.jpg',
        isDeleted: false,
        createdAt: now,
        createdBy: 'user-owner',
        updatedAt: now,
        updatedBy: 'user-owner',
      );

      final map = model.toMap();
      expect(map['companyId'], 'comp-123');
      expect(map['siteId'], 'site-456');
      expect(map['amount'], 1500.50);
      expect(map['category'], 'materials');
      expect(map['description'], 'Buy cement bags');
      expect(map['receiptUrl'], 'https://example.com/receipt.jpg');
      expect(map['isDeleted'], false);
      expect(map['createdBy'], 'user-owner');
    });

    test('converts from map correctly', () {
      final timestamp = Timestamp.fromDate(now);
      final expenseMap = {
        'companyId': 'comp-123',
        'siteId': 'site-456',
        'amount': 1500.50,
        'category': 'materials',
        'date': timestamp,
        'description': 'Buy cement bags',
        'receiptUrl': 'https://example.com/receipt.jpg',
        'isDeleted': false,
        'createdAt': timestamp,
        'createdBy': 'user-owner',
        'updatedAt': timestamp,
        'updatedBy': 'user-owner',
      };

      final model = ExpenseModel.fromMap(expenseMap, 'exp-789');
      expect(model.id, 'exp-789');
      expect(model.companyId, 'comp-123');
      expect(model.siteId, 'site-456');
      expect(model.amount, 1500.50);
      expect(model.category, ExpenseCategory.materials);
      expect(model.description, 'Buy cement bags');
      expect(model.receiptUrl, 'https://example.com/receipt.jpg');
      expect(model.isDeleted, false);
      expect(model.createdBy, 'user-owner');
    });
  });

  group('Permissions & Role Guard Verification', () {
    test('Owner role has view and manage expenses permissions', () {
      final role = UserRole.owner;
      expect(role.hasPermission(Permission.viewExpenses), isTrue);
      expect(role.hasPermission(Permission.manageExpenses), isTrue);
      expect(role.canAccessExpenses, isTrue);
    });

    test('Admin role has view and manage expenses permissions', () {
      final role = UserRole.admin;
      expect(role.hasPermission(Permission.viewExpenses), isTrue);
      expect(role.hasPermission(Permission.manageExpenses), isTrue);
      expect(role.canAccessExpenses, isTrue);
    });

    test('Supervisor role DOES NOT have view or manage expenses permissions', () {
      final role = UserRole.supervisor;
      expect(role.hasPermission(Permission.viewExpenses), isFalse);
      expect(role.hasPermission(Permission.manageExpenses), isFalse);
      expect(role.canAccessExpenses, isFalse);
    });
  });
}
