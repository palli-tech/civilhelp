class ReportFilter {
  final String companyId;
  final DateTime startDate;
  final DateTime endDate;
  final String? labourId;

  const ReportFilter({
    required this.companyId,
    required this.startDate,
    required this.endDate,
    this.labourId,
  });

  ReportFilter copyWith({
    String? companyId,
    DateTime? startDate,
    DateTime? endDate,
    String? labourId,
  }) {
    return ReportFilter(
      companyId: companyId ?? this.companyId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      labourId: labourId ?? this.labourId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is ReportFilter &&
      other.companyId == companyId &&
      other.startDate == startDate &&
      other.endDate == endDate &&
      other.labourId == labourId;
  }

  @override
  int get hashCode {
    return companyId.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      labourId.hashCode;
  }
}
