# SiteStatus Usage Audit

## Scope
- feature: `lib/features/sites`
- inspected files:
  - models
  - providers
  - repositories
  - screens
  - widgets

## Findings

### 1. `lib/features/sites/screens/edit_site_screen.dart`
- location: `_handleSubmit()` (line 130)
- actual expression: `formState.status`
- actual type: `SiteStatus`
- expected type by `updateSiteProvider`: `String`
- issue: `SiteStatus` enum is passed directly into a provider tuple declared as ending with `String status`
- required fix: pass `formState.status.name` instead of `formState.status`

### 2. `lib/features/sites/widgets/site_card.dart`
- location: `_getStatusColor()` (line 17)
- actual expression: `site.status.toLowerCase()`
- actual type: `SiteStatus` (when `site` is a `SiteModel`)
- expected type: `String`
- issue: widget logic assumes `status` is a lower-case string
- required fix: use `site.status.name.toLowerCase()` or refactor to enum-aware matching

### 3. `lib/features/sites/widgets/site_card.dart`
- location: `build()` label text (line 124)
- actual expression: `Text(site.status, ...)`
- actual type: `SiteStatus`
- expected type: `String`
- issue: `Text` widget expects a `String`, but `site.status` is an enum property on `SiteModel`
- required fix: use `site.status.name`

## Related type boundaries

### `lib/features/sites/providers/site_provider.dart`
- `createSiteProvider` expects `(String name, String location, String client, DateTime startDate, String status)`
- `updateSiteProvider` expects `(String siteId, String name, String location, String client, DateTime startDate, String status)`
- these provider signatures are string-based because the repository persists `status` as a Firestore string
- any caller that supplies `SiteStatus` directly is a mismatch

### `lib/features/sites/repositories/site_repository.dart`
- `createSite()` and `updateSite()` both accept `String status`
- this is the persistence boundary and is correct for the current Firestore schema

### `lib/features/sites/models/site_model.dart`
- `SiteModel.status` is typed as `SiteStatus`
- `SiteModel.toMap()` serializes with `status.name`
- `SiteModel.fromMap()` converts the persisted string back into `SiteStatus`
- this means the domain model expects enum values, while persistence expects strings

### `lib/features/sites/widgets/site_form.dart`
- `SiteFormState.status` returns `SiteStatus`
- this is the source of the enum value that must be converted before calling provider/repository methods

## Summary
The main mismatches are in widget and screen layers:
- `edit_site_screen.dart` still passes a `SiteStatus` enum into a provider expecting `String`
- `site_card.dart` treats `site.status` as a string rather than using `site.status.name`

If the app uses `SiteModel` objects throughout Sites, the provider/repository boundary is valid, but callers must convert enum values to `String` before passing them into `createSiteProvider`/`updateSiteProvider`.
