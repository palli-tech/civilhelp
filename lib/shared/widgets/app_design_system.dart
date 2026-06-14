import 'package:flutter/material.dart';

/// CivilHelp centralized design system.
///
/// All screens and widgets must source colors, spacing, radii, and text styles
/// from this file to maintain visual consistency across the app.
class AppDesignSystem {
  AppDesignSystem._();

  // ─── Brand Colors ────────────────────────────────────────────────────────

  /// Primary brand gradient — used in app bar headers
  static const List<Color> brandGradient = [
    Color(0xFF1E3C72),
    Color(0xFF2A5298),
  ];

  // ─── Semantic Status Colors ───────────────────────────────────────────────

  /// Success — Active, Paid, Recovered, Completed
  static const Color successColor = Color(0xFF388E3C);
  static const Color successLight = Color(0xFFE8F5E9);

  /// Warning — Outstanding, Pending, Needs Attention, Open
  static const Color warningColor = Color(0xFFF57C00);
  static const Color warningLight = Color(0xFFFFF3E0);

  /// Info — Payroll, Reports, Frozen, Informational
  static const Color infoColor = Color(0xFF1565C0);
  static const Color infoLight = Color(0xFFE3F2FD);

  /// Error — Overdue, Failed, Blocked, Cancelled
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFEBEE);

  /// Neutral — Inactive, Unknown, Default
  static const Color neutralColor = Color(0xFF616161);
  static const Color neutralLight = Color(0xFFF5F5F5);

  // ─── Semantic Domain Colors ───────────────────────────────────────────────

  /// Advances / outstanding liabilities — amber/orange
  static const Color advanceColor = Color(0xFFF57C00);
  static const Color advanceLight = Color(0xFFFFF3E0);

  /// Payroll / salary — deep blue
  static const Color payrollColor = Color(0xFF1E3C72);
  static const Color payrollLight = Color(0xFFE8EAF6);

  /// Recovery / resolved debts — blue (informational, not success)
  static const Color recoveryColor = Color(0xFF1565C0);
  static const Color recoveryLight = Color(0xFFE3F2FD);

  // ─── Spacing ──────────────────────────────────────────────────────────────

  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // ─── Border Radius ────────────────────────────────────────────────────────

  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;

  // ─── Elevation ────────────────────────────────────────────────────────────

  static const double elevationCard = 1.5;
  static const double elevationDialog = 8.0;

  // ─── Status Color Resolver ────────────────────────────────────────────────

  /// Returns the foreground (text/icon) color for a given status string.
  static Color statusForeground(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'paid':
      case 'completed':
      case 'recovered':
      case 'present':
        return successColor;
      case 'pending':
      case 'open':
      case 'outstanding':
      case 'partial':
      case 'half day':
      case 'half-day':
        return warningColor;
      case 'frozen':
      case 'paused':
        return infoColor;
      case 'inactive':
      case 'cancelled':
      case 'failed':
      case 'overdue':
      case 'absent':
        return errorColor;
      default:
        return neutralColor;
    }
  }

  /// Returns the background color for a given status string.
  static Color statusBackground(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'paid':
      case 'completed':
      case 'recovered':
      case 'present':
        return successLight;
      case 'pending':
      case 'open':
      case 'outstanding':
      case 'partial':
      case 'half day':
      case 'half-day':
        return warningLight;
      case 'frozen':
      case 'paused':
        return infoLight;
      case 'inactive':
      case 'cancelled':
      case 'failed':
      case 'overdue':
      case 'absent':
        return errorLight;
      default:
        return neutralLight;
    }
  }

  /// Returns the display label for a given status string.
  static String statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'open': return 'Open';
      case 'frozen': return 'Frozen';
      case 'paid': return 'Paid';
      case 'active': return 'Active';
      case 'inactive': return 'Inactive';
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      case 'paused': return 'Paused';
      case 'pending': return 'Pending';
      case 'partial': return 'Partial';
      case 'recovered': return 'Recovered';
      case 'failed': return 'Failed';
      case 'present': return 'Present';
      case 'absent': return 'Absent';
      case 'half day': return 'Half Day';
      case 'half-day': return 'Half Day';
      default: return status.isNotEmpty
          ? status[0].toUpperCase() + status.substring(1)
          : 'Unknown';
    }
  }
}
