enum ExpenseCategory {
  materials('materials'),
  fuel('fuel'),
  food('food'),
  rent('rent'),
  tools('tools'),
  transport('transport'),
  other('other');

  final String value;
  const ExpenseCategory(this.value);

  /// User-friendly label for display in UI
  String get displayName {
    switch (this) {
      case ExpenseCategory.materials:
        return 'Materials';
      case ExpenseCategory.fuel:
        return 'Fuel';
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.rent:
        return 'Rent';
      case ExpenseCategory.tools:
        return 'Tools';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  /// Parses a category string from Firestore safely
  static ExpenseCategory fromString(String? categoryStr) {
    if (categoryStr == null) return ExpenseCategory.other;
    final normalized = categoryStr.trim().toLowerCase();
    return ExpenseCategory.values.firstWhere(
      (e) => e.name == normalized || e.value == normalized,
      orElse: () => ExpenseCategory.other,
    );
  }
}
