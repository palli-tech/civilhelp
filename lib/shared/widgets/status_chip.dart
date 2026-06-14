import 'package:flutter/material.dart';
import 'app_design_system.dart';

/// A standardized status chip used throughout CivilHelp.
///
/// Automatically resolves the correct foreground/background colors from
/// [AppDesignSystem] based on the [status] string.
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
    final fg = AppDesignSystem.statusForeground(status);
    final bg = AppDesignSystem.statusBackground(status);
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
