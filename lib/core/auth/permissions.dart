import '../enums/user_role.dart';

/// Granular permissions used throughout the application.
///
/// Guards, screens, and providers check permissions rather than roles directly.
/// This allows the permission model to evolve independently of role definitions.
enum Permission {
  // Site management
  viewSites,
  manageSites, // create, edit, delete

  // Labour management
  viewLabour,
  manageLabour, // create, edit, delete

  // Attendance
  viewAttendance,
  createAttendance,
  editAttendance,
  deleteAttendance,

  // Payments
  viewPayments,
  managePayments, // create, mark paid, cancel, delete

  // Advances
  viewAdvances,
  manageAdvances, // create, edit, delete

  // Reports
  viewReports,

  // Company administration
  manageCompany, // edit company profile, logo
  viewSettings,
  manageSettings,

  // User/team management (future)
  manageUsers,

  // Expenses management
  viewExpenses,
  manageExpenses,
}

/// Maps each [UserRole] to the set of [Permission]s it grants.
///
/// To add a new role or modify permissions, update this map only.
/// All guards and permission checks derive from this single source of truth.
const Map<UserRole, Set<Permission>> rolePermissions = {
  UserRole.owner: {
    // Full access
    Permission.viewSites,
    Permission.manageSites,
    Permission.viewLabour,
    Permission.manageLabour,
    Permission.viewAttendance,
    Permission.createAttendance,
    Permission.editAttendance,
    Permission.deleteAttendance,
    Permission.viewPayments,
    Permission.managePayments,
    Permission.viewAdvances,
    Permission.manageAdvances,
    Permission.viewReports,
    Permission.manageCompany,
    Permission.viewSettings,
    Permission.manageSettings,
    Permission.manageUsers,
    Permission.viewExpenses,
    Permission.manageExpenses,
  },

  UserRole.supervisor: {
    Permission.viewAttendance,
    Permission.createAttendance,
    Permission.editAttendance,
    // No deleteAttendance
    // No sites/labour management — read-only for assigned sites via dedicated providers
  },

  // Future: Admin — placeholder
  UserRole.admin: {
    Permission.viewSites,
    Permission.manageSites,
    Permission.viewLabour,
    Permission.manageLabour,
    Permission.viewAttendance,
    Permission.createAttendance,
    Permission.editAttendance,
    Permission.deleteAttendance,
    Permission.viewPayments,
    Permission.managePayments,
    Permission.viewAdvances,
    Permission.manageAdvances,
    Permission.viewReports,
    Permission.manageCompany,
    Permission.viewSettings,
    Permission.manageSettings,
    Permission.manageUsers,
    Permission.viewExpenses,
    Permission.manageExpenses,
  },

  // Future: Partner — placeholder
  UserRole.partner: <Permission>{},

  // Pending — no permissions
  UserRole.pending: <Permission>{},
};

/// Extension on [UserRole] for permission-checking convenience.
extension UserRolePermissions on UserRole {
  /// Returns all permissions granted to this role.
  Set<Permission> get permissions => rolePermissions[this] ?? {};

  /// Whether this role has a specific permission.
  bool hasPermission(Permission permission) =>
      permissions.contains(permission);

  /// Whether this role has ALL of the given permissions.
  bool hasAllPermissions(Iterable<Permission> perms) =>
      perms.every(permissions.contains);

  /// Whether this role has ANY of the given permissions.
  bool hasAnyPermission(Iterable<Permission> perms) =>
      perms.any(permissions.contains);

  /// The set of routes this role is allowed to access.
  ///
  /// Convenience getter used by route guards.
  bool get canAccessSites => hasPermission(Permission.viewSites);
  bool get canAccessLabour => hasPermission(Permission.viewLabour);
  bool get canAccessAttendance => hasPermission(Permission.viewAttendance);
  bool get canAccessPayments => hasPermission(Permission.viewPayments);
  bool get canAccessAdvances => hasPermission(Permission.viewAdvances);
  bool get canAccessExpenses => hasPermission(Permission.viewExpenses);
  bool get canAccessReports => hasPermission(Permission.viewReports);
  bool get canAccessSettings => hasPermission(Permission.viewSettings);
  bool get canAccessCompanyProfile => hasPermission(Permission.manageCompany);
}
