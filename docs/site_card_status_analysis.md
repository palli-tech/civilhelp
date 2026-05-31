# SiteCard Status Analysis

## Files inspected
- `lib/features/sites/widgets/site_card.dart`

## Every usage in `site_card.dart`

### 1. `site.status.name.toLowerCase()`
- location: `_getStatusColor()`
- actual expression: `site.status.name.toLowerCase()`
- expected runtime type: `SiteStatus` enum with `name` property available
- actual runtime receiver: `Instance of 'SiteStatus'`

### 2. `site.status.name`
- location: `Chip(label: Text(site.status.name, ...))`
- actual expression: `site.status.name`
- expected runtime type: `SiteStatus` enum with `name` property available
- actual runtime receiver: `Instance of 'SiteStatus'`

## Other relevant usage
- `site.status` appears only in the two expressions above in this file.
- `site` is typed as `dynamic`, so compile-time checking does not enforce its shape.

## Why `.name` throws at runtime

The runtime error indicates that the receiver is indeed a `SiteStatus` enum instance, but the enum instance does not have a `name` getter available in the current runtime environment.

This is consistent with Dart SDK versions prior to the enum `name` property being introduced.

### Key point
- `SiteModel` uses `SiteStatus` as its `status` field.
- However, `site_card.dart` is assuming an enum API that may not exist on the active Dart runtime.
- Thus the failure is not because `site.status` is a string; it is because `SiteStatus.name` is unavailable.

## Likely root cause

- `site_card.dart` declares `final dynamic site;`
- At runtime, `site.status` is a `SiteStatus` enum instance
- The code then calls `.name` on that enum
- If the app is running on a Dart SDK where enum `.name` is not supported, this raises `NoSuchMethodError`

## Notes

- The `site_model.dart` serialization already writes `'status': status.name`, so the stored Firestore value is a string.
- `SiteModel.fromMap()` reads that string and maps it back to `SiteStatus` using `SiteStatus.values.firstWhere((e) => e.name == map['status'])`.
- The `site_card.dart` assumption that enum values support `.name` should be validated against the SDK version in use.

## Recommended check

- Confirm the Dart/Flutter SDK version being used.
- If it is older than the version that supports `Enum.name`, use explicit enum-to-string conversion.
