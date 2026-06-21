# Enum Usage Audit

## Search target
- `.status.name`

## Results
Found 3 occurrences in the project:

1. `lib/features/sites/screens/add_site_screen.dart`
   - Expression: `formState.status.name`
   - `formState.status` is sourced from `SiteFormState.status`, which is a `SiteStatus` enum.

2. `lib/features/sites/screens/edit_site_screen.dart`
   - Expression: `formState.status.name`
   - `formState.status` is also a `SiteStatus` enum in the site edit form.

3. `lib/features/sites/screens/site_details_screen.dart`
   - Expression: `site.status.name`
   - `site.status` comes from `SiteModel.status`, which is typed as `SiteStatus`.

## Enum verification
- `SiteStatus` is defined in `lib/core/enums/site_status.dart` as a plain Dart enum:
  ```dart
  enum SiteStatus {
    active,
    inactive,
    completed,
    onHold,
  }
  ```
- This is a standard Dart enum, so the enum value type itself is valid for `.name` access when running on a Dart SDK that supports enum name reflection.

## Compatibility note
- Dart enum `.name` is available in Dart 2.15 and later.
- If the app is running on an older Dart SDK, the `.name` accessor will throw `NoSuchMethodError` even though the enum type is correct.

## Summary
- All `.status.name` usages across the project refer to `SiteStatus`.
- The enums are defined correctly as Dart enums.
- The issue is therefore not an invalid enum type per se, but a compatibility risk if the runtime SDK does not support enum `.name`.
