# Navigation Shell Fix

## Searched files
- `lib/features/sites/screens/sites_screen.dart`
- `lib/features/labour/presentation/screens/labour_list_screen.dart`
- `lib/features/attendance/screens/attendance_screen.dart`
- `lib/features/payments/screens/payments_screen.dart`
- `lib/features/advances/screens/advances_screen.dart`
- `lib/shared/layouts/app_scaffold.dart`
- `lib/shared/layouts/app_drawer.dart`
- `lib/shared/layouts/responsive_layout.dart`
- `lib/shared/layouts/bottom_nav.dart`

## Summary
`AttendanceScreen`, `PaymentsScreen`, and `AdvancesScreen` do not render the application shell because they return a raw `Scaffold` instead of the shared `AppScaffold` wrapper.

### What works correctly
- `SitesScreen` uses `AppScaffold`
- `LabourListScreen` uses `AppScaffold`

These screens therefore get the shared shell, including:
- `AppDrawer`
- `BottomNav`
- `ResponsiveLayout`
- drawer/sidebar integration for tablet/desktop
- consistent navigation style across app modules

## Missing shell usage in Attendance/Payments/Advances

### 1. Missing `AppScaffold` usage
- `AttendanceScreen` returns `Scaffold(...)`
- `PaymentsScreen` returns `Scaffold(...)`
- `AdvancesScreen` returns `Scaffold(...)`

### 2. Missing `AppDrawer` usage
- `AppDrawer` is only provided by `AppScaffold`.
- These screens do not include `drawer` or any shared drawer widget, so the app menu is absent.

### 3. Missing `ResponsiveLayout` usage
- `AppScaffold` wraps `ResponsiveLayout`.
- By bypassing `AppScaffold`, these screens do not use the responsive shell that renders the drawer as a sidebar on tablet/desktop.

### 4. Missing sidebar integration
- The shared navigation sidebar is implemented through `ResponsiveLayout` + `AppDrawer`.
- Raw `Scaffold` prevents tablet/desktop sidebar behavior entirely, so these screens are isolated from the shell.

### 5. Missing shared navigation components
- `BottomNav` is wired into `AppScaffold` via `AppScaffold -> ResponsiveLayout`.
- `AttendanceScreen`, `PaymentsScreen`, and `AdvancesScreen` therefore miss the shared bottom navigation and the bottom "More" menu links.
- Shared menu routing definitions in `AppDrawer` and `BottomNav` are not available.

## Why these screens do not render the app shell

`AppScaffold` is the single shared entry point for the app shell. It composes:
- `ResponsiveLayout`
- `Application AppBar`
- `AppDrawer`
- `BottomNav`
- optional `FloatingActionButton`

If a screen returns `Scaffold` directly, it bypasses all of that shell composition and renders only its own app bar and body.

## Recommended minimal code changes

For each screen, replace the raw `Scaffold` with `AppScaffold`.

### Example fix
```dart
return AppScaffold(
  appBar: AppBar(
    title: const Text('Attendance'),
    elevation: 0,
  ),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      ...
    ),
  ),
);
```

Apply the same pattern to:
- `AttendanceScreen`
- `PaymentsScreen`
- `AdvancesScreen`

### Additional notes
- No change to the internal body content is required.
- If any screen needs a floating action button later, pass it as `fab:` to `AppScaffold`.
- Keep the existing `AppBar` definitions.

## Result
After this change, the three screens will:
- render the shared application shell
- show the common drawer menu on mobile
- show responsive sidebar layout on tablet/desktop
- include the shared bottom navigation component
- align navigation behavior with `SitesScreen` and `LabourListScreen`
