# Project Inventory

## Feature Modules

- auth
- dashboard
- sites
- labour
- attendance
- payments
- advances
- expenses
- invoices
- reports
- settings

## Screens per Module

### auth
- `SplashScreen` (`lib/features/auth/screens/splash_screen.dart`)
- `LoginScreen` (`lib/features/auth/screens/login_screen.dart`)

### dashboard
- `DashboardScreen` (`lib/features/dashboard/screens/dashboard_screen.dart`)
- `SupervisorDashboard` (`lib/features/dashboard/screens/supervisor_dashboard.dart`)
- `AdminDashboard` (`lib/features/dashboard/screens/admin_dashboard.dart`)
- `PartnerDashboard` (`lib/features/dashboard/screens/partner_dashboard.dart`)
- `OwnerDashboard` (`lib/features/dashboard/screens/owner_dashboard.dart`)

### sites
- `SitesScreen` (`lib/features/sites/screens/sites_screen.dart`)
- `AddSiteScreen` (`lib/features/sites/screens/add_site_screen.dart`)
- `EditSiteScreen` (`lib/features/sites/screens/edit_site_screen.dart`)
- `SiteDetailsScreen` (`lib/features/sites/screens/site_details_screen.dart`)

### labour
- `LabourListScreen` (`lib/features/labour/presentation/screens/labour_list_screen.dart`)
- `LabourDetailsScreen` (`lib/features/labour/presentation/screens/labour_details_screen.dart`)
- `AddEditLabourScreen` (`lib/features/labour/presentation/screens/add_edit_labour_screen.dart`)

### attendance
- `AttendanceScreen` (`lib/features/attendance/screens/attendance_screen.dart`)

### payments
- `PaymentsScreen` (`lib/features/payments/screens/payments_screen.dart`)

### advances
- `AdvancesScreen` (`lib/features/advances/screens/advances_screen.dart`)

### expenses / invoices / reports / settings
- These modules currently contain only placeholder `index.dart` files and no concrete screens.

## Providers per Module

### core
- `userCompanyIdProvider` (`lib/core/providers/company_provider.dart`)

### auth
- `authProvider` (`lib/features/auth/providers/auth_provider.dart`)

### dashboard
- `dashboardMetricsProvider` (`lib/features/dashboard/providers/dashboard_metrics_provider.dart`)

### sites
- `siteProvider` (`lib/features/sites/providers/site_provider.dart`)

### labour
- `labourProvider` (`lib/features/labour/presentation/providers/labour_provider.dart`)

### attendance
- `attendanceProvider` (`lib/features/attendance/providers/attendance_provider.dart`)

### payments
- `paymentProvider` (`lib/features/payments/providers/payment_provider.dart`)

### advances
- `advanceProvider` (`lib/features/advances/providers/advance_provider.dart`)

## Repositories per Module

### auth
- no repository class currently present in `lib/features/auth/services` (service-based auth)

### sites
- `SiteRepository` (`lib/features/sites/repositories/site_repository.dart`)

### labour
- `LabourRepository` (`lib/features/labour/data/repositories/labour_repository_impl.dart`)
- `AbstractLabourRepository` (`lib/features/labour/domain/repositories/abstract_labour_repository.dart`)

### attendance
- `AttendanceRepository` (`lib/features/attendance/repositories/attendance_repository.dart`)

### payments
- `PaymentRepository` (`lib/features/payments/repositories/payment_repository.dart`)

### advances
- `AdvanceRepository` (`lib/features/advances/repositories/advance_repository.dart`)

## Models per Module

### sites
- `SiteModel` (`lib/features/sites/models/site_model.dart`)

### labour
- `LabourModel` (`lib/features/labour/data/models/labour_model.dart`)
- `LabourEntity` (`lib/features/labour/domain/entities/labour_entity.dart`)

### attendance
- `AttendanceModel` (`lib/features/attendance/models/attendance_model.dart`)

### payments
- `PaymentModel` (`lib/features/payments/models/payment_model.dart`)

### advances
- `AdvanceModel` (`lib/features/advances/models/advance_model.dart`)

## Shared Widgets

- `AppScaffold` (`lib/shared/layouts/app_scaffold.dart`)
- `AppDrawer` (`lib/shared/layouts/app_drawer.dart`)
- `BottomNav` (`lib/shared/layouts/bottom_nav.dart`)
- `ResponsiveLayout` (`lib/shared/layouts/responsive_layout.dart`)
- `DashboardCard` (`lib/features/dashboard/widgets/dashboard_card.dart`)
- `QuickActionTile` (`lib/features/dashboard/widgets/quick_action_tile.dart`)
- `GoogleSignInButton` (`lib/features/auth/widgets/google_signin_button.dart`)
- `SiteCard` (`lib/features/sites/widgets/site_card.dart`)
- `SiteForm` (`lib/features/sites/widgets/site_form.dart`)
- `LabourCard` (`lib/features/labour/presentation/widgets/labour_card.dart`)
- `LabourForm` (`lib/features/labour/presentation/widgets/labour_form.dart`)
- `LabourStatusChip` (`lib/features/labour/presentation/widgets/labour_status_chip.dart`)

## Utility Classes and Core Infrastructure

### core
- `core/constants/index.dart`
- `core/enums/site_status.dart`
- `core/enums/labour_status.dart`
- `core/enums/user_role.dart`
- `core/enums/index.dart`
- `core/errors/index.dart`
- `core/extensions/index.dart`
- `core/providers/company_provider.dart`
- `core/services/index.dart`
- `core/utils/index.dart`

### app
- `CivilHelpApp` (`lib/app/app.dart`)
- `AppRouter` and `AppRoutes` (`lib/app/router.dart`)
- `router_extensions.dart` (`lib/app/router_extensions.dart`)
- `theme.dart` (`lib/app/theme.dart`)

## Routing Structure

Defined in `lib/app/router.dart` with the following named routes:

- `/` → `SplashScreen`
- `/login` → `LoginScreen`
- `/dashboard` → `DashboardScreen`
- `/sites` → `SitesScreen`
- `/add-site` → `AddSiteScreen`
- `/site-details` → `SiteDetailsScreen`
- `/edit-site` → `EditSiteScreen`
- `/labour` → `LabourListScreen`
- `/add-labour` → `AddEditLabourScreen`
- `/labour-details` → `LabourDetailsScreen`
- `/edit-labour` → `AddEditLabourScreen` (with labourId)
- `/attendance` → `AttendanceScreen`
- `/payments` → `PaymentsScreen`
- `/advances` → `AdvancesScreen`

## Potential Duplicates / Dead Code

- No direct duplicate model classes were found in the current inventory.
- No duplicate provider files were found beyond one provider per module.
- Similar card-style widgets exist across features, such as `DashboardCard` / `QuickActionTile` and `SiteCard` / `LabourCard`, but they are module-specific.
- Placeholder feature directories for `expenses`, `invoices`, `reports`, and `settings` appear to contain only `index.dart` markers, suggesting these modules may be incomplete or dormant.
- `LabourEntity` and `LabourModel` are intentionally separate domain/data artifacts rather than duplicates.
