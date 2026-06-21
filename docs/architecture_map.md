# Architecture Map

## Overview
This document maps the current CivilHelp app architecture without modifying application code. It captures module dependencies, providers, repositories, routing flow, and shared widgets.

## Module Dependencies

### Core
- `core/providers/company_provider.dart`
  - Provides `userCompanyIdProvider` used by multiple modules to scope data to the current company.
- `features/auth/providers/auth_provider.dart`
  - Exposes `currentUserProvider` and authentication state used by labour, sites, and attendance modules.

### Auth
- Base authentication module.
- Feeds identity to other modules via `currentUserProvider`.
- No dedicated repository class; uses service-based auth.

### Sites
- Contains `SiteRepository` and `siteProvider`.
- Depends on `core/providers/company_provider.dart` and auth provider.
- Provides site streams to:
  - `attendance` (site attendance selection)
  - `payments` (site payment summaries)
  - `advances` (advance allocations by site)
  - `dashboard` (active site counts)

### Labour
- Contains `LabourRepository` and `labourProvider`.
- Depends on auth provider as a source of company / user context.
- Provides labour streams to:
  - `attendance` (labour attendance assignment)
  - `payments` (labour payment records)
  - `advances` (labour advance records)
  - `dashboard` (active labour counts)

### Attendance
- Contains `AttendanceRepository` and `attendanceProvider`.
- Depends on `userCompanyIdProvider` and auth provider for create actions.
- In-app dependencies:
  - `labour` provider for labour selection and attendance updates
  - `sites` provider for site selection and attendance filtering
- Provides attendance streams to:
  - `dashboard` (attendance metrics)
  - `sites` details (attendance summary by site)

### Payments
- Contains `PaymentRepository` and `paymentProvider`.
- Depends on `userCompanyIdProvider`.
- In-app dependencies:
  - `labour` provider for worker payment details
  - `sites` provider for site-specific payments
- Provides payment streams and summaries to:
  - `dashboard` (pending payments count)

### Advances
- Contains `AdvanceRepository` and `advanceProvider`.
- Depends on `userCompanyIdProvider`.
- In-app dependencies:
  - `labour` provider for advance recipient details
  - `sites` provider for site-linked advances
- Provides advance streams to:
  - `dashboard` (outstanding advance totals)

### Dashboard
- Central aggregation module.
- Contains `dashboardMetricsProvider`.
- Depends on:
  - `siteProvider`
  - `labourProvider`
  - `attendanceProvider`
  - `paymentProvider`
  - `advanceProvider`
- Computes metrics such as:
  - active sites count
  - active labour count
  - labour present today
  - pending payments count
  - outstanding advance total

### Placeholder modules
- `expenses`, `invoices`, `reports`, `settings`
- Currently contain only `index.dart` marker files and have no concrete implementation or routing.

## Providers

### Core Provider
- `userCompanyIdProvider` (`lib/core/providers/company_provider.dart`)

### Feature Providers
- `authProvider` (`lib/features/auth/providers/auth_provider.dart`)
- `dashboardMetricsProvider` (`lib/features/dashboard/providers/dashboard_metrics_provider.dart`)
- `siteProvider` (`lib/features/sites/providers/site_provider.dart`)
- `labourProvider` (`lib/features/labour/presentation/providers/labour_provider.dart`)
- `attendanceProvider` (`lib/features/attendance/providers/attendance_provider.dart`)
- `paymentProvider` (`lib/features/payments/providers/payment_provider.dart`)
- `advanceProvider` (`lib/features/advances/providers/advance_provider.dart`)

## Repositories

### Feature Repositories
- `SiteRepository` (`lib/features/sites/repositories/site_repository.dart`)
- `LabourRepository` (`lib/features/labour/data/repositories/labour_repository_impl.dart`)
- `AttendanceRepository` (`lib/features/attendance/repositories/attendance_repository.dart`)
- `PaymentRepository` (`lib/features/payments/repositories/payment_repository.dart`)
- `AdvanceRepository` (`lib/features/advances/repositories/advance_repository.dart`)

### Domain Abstraction
- `AbstractLabourRepository` (`lib/features/labour/domain/repositories/abstract_labour_repository.dart`)
  - Defines the labour repository contract.

## Routing Flow

### App Router
- Implemented in `lib/app/router.dart` via `AppRouter.generateRoute()`.
- Uses named routes in `AppRoutes`.

### Route mapping
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

### Flow summary
1. App starts at splash screen.
2. User navigates to login if unauthenticated.
3. Authenticated users land on dashboard.
4. Dashboard navigates to feature modules via named routes.
5. Sites, labour, attendance, payments, and advances are accessed through the shared routing layer.

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

## Notes
- The architecture is strongly feature-driven and centered on Riverpod providers and repository-backed streams.
- Dashboard metrics are computed from multiple feature repositories, making the dashboard a cross-module aggregation point.
- `expenses`, `invoices`, `reports`, and `settings` are currently placeholders and are not part of the active routing or provider graph.
