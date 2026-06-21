import 'package:flutter/material.dart';
import 'package:civilhelp/app/theme.dart';
import 'app_design_system.dart';

/// A standardized status chip used throughout CivilHelp.
///
/// Automatically resolves the correct foreground/background colors from
/// the theme based on the [status] string.
///
/// Usage:
/// ```dart
/// StatusChip(status: 'active')
/// StatusChip(status: 'frozen')
/// StatusChip(status: 'paid')
/// StatusChip(status: 'pending')
/// ```
class StatusChip extends StatelessWidget {
  final String status;
  final String? label;
  final double fontSize;

  const StatusChip({
    super.key,
    required this.status,
    this.label,
    this.fontSize = 11.0,
  });

  @override
  Widget build(BuildContext context) {
    // Resolve theme-aware colors
    Color fg;
    Color bg;

    switch (status.toLowerCase()) {
      case 'active':
      case 'paid':
      case 'completed':
      case 'recovered':
      case 'present':
        fg = context.customColors.success;
        bg = context.customColors.successContainer;
        break;
      case 'pending':
      case 'open':
      case 'outstanding':
      case 'partial':
      case 'half day':
      case 'half-day':
        fg = context.customColors.warning;
        bg = context.customColors.warningContainer;
        break;
      case 'frozen':
      case 'paused':
        fg = context.customColors.info;
        bg = context.customColors.infoContainer;
        break;
      case 'inactive':
      case 'cancelled':
      case 'failed':
      case 'overdue':
      case 'absent':
        fg = context.customColors.error;
        bg = context.customColors.errorContainer;
        break;
      default:
        fg = context.colors.outline;
        bg = context.colors.surfaceVariant;
    }

    final text = label ?? AppDesignSystem.statusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
