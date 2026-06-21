import 'package:flutter/material.dart';

class CivilHelpColors extends ThemeExtension<CivilHelpColors> {
  final Color attendance;
  final Color payroll;
  final Color advance;
  final Color worker;
  final Color site;
  final Color surfaceHigh;

  final Color success;
  final Color successContainer;
  final Color onSuccess;

  final Color warning;
  final Color warningContainer;
  final Color onWarning;

  final Color error;
  final Color errorContainer;
  final Color onError;

  final Color info;
  final Color infoContainer;
  final Color onInfo;

  const CivilHelpColors({
    required this.attendance,
    required this.payroll,
    required this.advance,
    required this.worker,
    required this.site,
    required this.surfaceHigh,
    required this.success,
    required this.successContainer,
    required this.onSuccess,
    required this.warning,
    required this.warningContainer,
    required this.onWarning,
    required this.error,
    required this.errorContainer,
    required this.onError,
    required this.info,
    required this.infoContainer,
    required this.onInfo,
  });

  @override
  CivilHelpColors copyWith({
    Color? attendance,
    Color? payroll,
    Color? advance,
    Color? worker,
    Color? site,
    Color? surfaceHigh,
    Color? success,
    Color? successContainer,
    Color? onSuccess,
    Color? warning,
    Color? warningContainer,
    Color? onWarning,
    Color? error,
    Color? errorContainer,
    Color? onError,
    Color? info,
    Color? infoContainer,
    Color? onInfo,
  }) {
    return CivilHelpColors(
      attendance: attendance ?? this.attendance,
      payroll: payroll ?? this.payroll,
      advance: advance ?? this.advance,
      worker: worker ?? this.worker,
      site: site ?? this.site,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarning: onWarning ?? this.onWarning,
      error: error ?? this.error,
      errorContainer: errorContainer ?? this.errorContainer,
      onError: onError ?? this.onError,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfo: onInfo ?? this.onInfo,
    );
  }

  @override
  CivilHelpColors lerp(ThemeExtension<CivilHelpColors>? other, double t) {
    if (other is! CivilHelpColors) {
      return this;
    }
    return CivilHelpColors(
      attendance: Color.lerp(attendance, other.attendance, t)!,
      payroll: Color.lerp(payroll, other.payroll, t)!,
      advance: Color.lerp(advance, other.advance, t)!,
      worker: Color.lerp(worker, other.worker, t)!,
      site: Color.lerp(site, other.site, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      onError: Color.lerp(onError, other.onError, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
    );
  }

  // Helper factory for Light Mode semantic colors
  static CivilHelpColors get light => const CivilHelpColors(
        attendance: Color(0xFF6750A4), // Primary theme deep purple for attendance
        payroll: Color(0xFF3F51B5),    // Secondary theme indigo for payroll
        advance: Color(0xFFEF6C00),    // Orange warning/financial highlights
        worker: Color(0xFF1565C0),     // Blue theme for workers
        site: Color(0xFF00796B),       // Teal theme for sites
        surfaceHigh: Color(0xFFECE6F2), // Light surface container high
        success: Color(0xFF2E7D32),
        successContainer: Color(0xFFE8F5E9),
        onSuccess: Color(0xFF2E7D32),
        warning: Color(0xFFEF6C00),
        warningContainer: Color(0xFFFFF3E0),
        onWarning: Color(0xFFEF6C00),
        error: Color(0xFFC62828),
        errorContainer: Color(0xFFFFEBEE),
        onError: Color(0xFFC62828),
        info: Color(0xFF1565C0),
        infoContainer: Color(0xFFE3F2FD),
        onInfo: Color(0xFF1565C0),
      );

  // Helper factory for Dark Mode semantic colors
  static CivilHelpColors get dark => const CivilHelpColors(
        attendance: Color(0xFFD0BCFF), // Light purple contrast for dark mode
        payroll: Color(0xFFC5CAE9),    // Light indigo contrast for dark mode
        advance: Color(0xFFFFB74D),    // Bright orange highlight
        worker: Color(0xFF64B5F6),     // Bright blue
        site: Color(0xFF4DB6AC),       // Bright teal
        surfaceHigh: Color(0xFF2A1F44), // Eedu dark surface high
        success: Color(0xFF81C784),
        successContainer: Color(0xFF1B5E20),
        onSuccess: Color(0xFFE8F5E9),
        warning: Color(0xFFFFB74D),
        warningContainer: Color(0xFFE65100),
        onWarning: Color(0xFFFFF3E0),
        error: Color(0xFFE57373),
        errorContainer: Color(0xFF601410),
        onError: Color(0xFFFFEBEE),
        info: Color(0xFF64B5F6),
        infoContainer: Color(0xFF0D47A1),
        onInfo: Color(0xFFE3F2FD),
      );
}
