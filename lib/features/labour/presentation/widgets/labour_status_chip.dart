import 'package:flutter/material.dart';

import 'package:civilhelp/core/enums/labour_status.dart';

class LabourStatusChip extends StatelessWidget {
  final LabourStatus status;
  final double? fontSize;
  final EdgeInsets? padding;

  const LabourStatusChip({
    super.key,
    required this.status,
    this.fontSize,
    this.padding,
  });

  Color _getStatusColor() {
    switch (status) {
      case LabourStatus.active:
        return Colors.green;
      case LabourStatus.inactive:
        return Colors.grey;
      case LabourStatus.onLeave:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        status.name[0].toUpperCase() + status.name.substring(1),
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize ?? 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: _getStatusColor(),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
