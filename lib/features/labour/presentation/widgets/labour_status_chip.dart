import 'package:flutter/material.dart';

import 'package:civilhelp/app/theme.dart';
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

  Color _getStatusColor(BuildContext context) {
    switch (status) {
      case LabourStatus.active:
        return context.customColors.success;
      case LabourStatus.inactive:
        return context.colors.outline;
      case LabourStatus.onLeave:
        return context.customColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusText = status.toString().split('.').last;
    final displayText = statusText[0].toUpperCase() + statusText.substring(1);

    return Chip(
      label: Text(
        displayText,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize ?? 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: _getStatusColor(context),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
