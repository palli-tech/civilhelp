# Navigation Audit

This audit verifies app routes defined in `lib/app/router.dart` and navigation calls from the dashboard, `AppDrawer`, `BottomNav`, `QuickActionTile`, and dashboard card entry points.

## Route verification

### `/` (Splash)
- Reachable: ✅
- Source: initial app startup route is expected to load `SplashScreen`.
- Broken navigation: none.
- Missing route registration: no.
- Missing screen: no.
- Recommended fix: none.

### `/login`
- Reachable: ✅
- Source: `SplashScreen` uses `pushReplacementNamed('/login')` when no auth state exists; `AppDrawer` and `BottomNav` logout flows use `pushReplacementNamed('/login')`.
- Broken navigation: none.
- Missing route registration: no.
- Missing screen: no.
- Recommended fix: none.

### `/dashboard`
- Reachable: ✅
- Source: `LoginScreen` navigates to `/dashboard`; `AppDrawer` and `BottomNav` navigate to `/dashboard`.
- Broken navigation: none.
- Missing route registration: no.
- Missing screen: no.
- Recommended fix: none.

### `/sites`
- Reachable: ✅
- Source: `AppDrawer` and `BottomNav` navigate to `/sites`.
- Broken navigation: none.
- Missing route registration: no.
- Missing screen: no.
- Recommended fix: none.

### `/add-site`
- Reachable: ✅
- Source: `SitesScreen` FAB and empty-state CTA use `/add-site`.
- Broken navigation: none.
- Missing route registration: no.
- Missing screen: no.
- Recommended fix: none.

### `/site-details`
- Reachable: ✅
- Source: `SitesScreen` list item tap navigates to `/site-details` with `arguments: site.id`.
- Broken navigation: none; argument type is correct.
- Missing route registration: no.
- Missing screen: no.
- Recommended fix: none.

### `/edit-site`
- Reachable: ✅
- Source: `SiteCard` popup menu `Edit` action navigates to `/edit-site` with `arguments: site.id`.
- Broken navigation: none; argument type is correct.
- Missing route registration: no.
- Missing screen: no.
- Recommended fix: none.

### `/labour`
- Reachable: ✅
- Source: `AppDrawer` and `BottomNav` navigate to `/labour`.
- Broken navigation: none.
- Missing route registration: no.
- Missing screen: no.
- Recommended fix: none.

### `/add-labour`
- Reachable: ✅
- Source: `LabourListScreen` FAB and empty-state CTA use `/add-labour`.
- Broken navigation: none.
- Missing route registration: no.
- Missing screen: no.
- Recommended fix: none.

### `/labour-details`
- Reachable: ✅
- Source: `LabourListScreen` item tap navigates to `/labour-details` with `arguments: labour.id`.
- Broken navigation: none; argument type is correct.
- Missing route registration: no.
- Missing screen: no.
- Recommended fix: none.

### `/edit-labour`
- Reachable: ✅
- Source: `LabourListScreen` item edit action navigates to `/edit-labour` with `arguments: labour.id`.
- Broken navigation: none; argument type is correct.
- Missing route registration: no.
- Missing screen: no.
- Recommended fix: none.

### `/attendance`
- Reachable: ✅
- Source: `AppDrawer`, `BottomNav` More menu, and `SupervisorDashboard` quick action navigate to `AppRoutes.attendance`.
- Broken navigation: none.
- Missing route registration: no.
- Missing screen: no.
- Recommended fix: none.

### `/payments`
- Reachable: ✅
- Source: `AppDrawer`, `BottomNav` More menu, and `SupervisorDashboard` quick action navigate to `AppRoutes.payments`.
- Broken navigation: none.
- Missing route registration: no.
- Missing screen: no.
- Recommended fix: none.

### `/advances`
- Reachable: ✅
- Source: `AppDrawer`, `BottomNav` More menu, and `SupervisorDashboard` quick action navigate to `AppRoutes.advances`.
- Broken navigation: none.
- Missing route registration: no.
- Missing screen: no.
- Recommended fix: none.

## Observations for navigation call sites

### AppDrawer
- All active routes used by `AppDrawer` are registered and reachable.
- `AppDrawer` includes placeholder menu items for `/invoices`, `/reports`, and `/settings`, but these are commented out and not active navigation calls.
- Recommended fix: if these menu items are later enabled, add corresponding routes to `AppRouter` and screen implementations.

### BottomNav
- All bottom navigation routes are registered and reachable.
- `More` menu includes placeholder items for invoices, reports, and settings with no active route calls.
- Recommended fix: when enabling these menu items, register routes and replace comments with real navigation.

### Dashboard (SupervisorDashboard)
- Quick actions navigate to active routes only: attendance, payments, advances.
- No broken navigation detected.
- Recommended fix: consider adding quick access to sites and labour if those are central workflows.

### QuickActionTile
- `QuickActionTile` itself does not implement routing; it simply executes the provided `onTap` callback.
- Reachability depends entirely on the caller. Current callers use valid routes.
- Recommended fix: none.

### DashboardCard
- `DashboardCard` is a generic UI widget and does not itself navigate.
- No issues found.
- Recommended fix: none.

## Summary
- All routes declared in `lib/app/router.dart` are reachable and registered.
- No broken navigation paths were found for active routes.
- Route arguments for detail/edit routes are provided correctly where used.
- Missing route registration is only relevant for placeholder menu entries in `AppDrawer` and `BottomNav` that are not yet active.
- No missing screens were identified for registered routes.
