# Site Status Type Mismatch

## Runtime error

Error observed when saving a Site:

```
type '(String, String, String, DateTime, SiteStatus)'
is not a subtype of type
'(String, String, String, DateTime, String)'
```

## Trace of the flow

### 1. add_site_screen.dart
- `SiteFormState.status` returns a `SiteStatus` enum value.
- `_handleSubmit()` reads `formState.status` and includes it in the tuple passed to `createSiteProvider`.
- The code applies a runtime cast:
  - `as (String, String, String, DateTime, String)`
- This is the exact location where the mismatch is triggered, because the tuple actually contains `SiteStatus` in the last position.

### 2. site_provider.dart
- `createSiteProvider` is declared with a parameter tuple ending in `String status`.
- It passes that `status` value into `repository.createSite(... status: params.$5 ...)`.
- `updateSiteProvider` is also declared to expect `String status`.

### 3. site_repository.dart
- `SiteRepository.createSite()` and `updateSite()` both expect `String status`.
- The repository stores the `status` field directly as a Firestore string.
- This layer is therefore aligned with a string-based status representation.

### 4. site_model.dart
- `SiteModel.status` is typed as `SiteStatus`.
- `SiteModel.fromMap()` reads the Firestore `status` string and converts it to `SiteStatus` using `SiteStatus.values.firstWhere(... e.name == map['status'] ...)`.
- `SiteModel.toMap()` writes `status.name` back as a string.
- This layer expects the domain model to own a `SiteStatus` enum, while persistence remains string-based.

## Where `SiteStatus` is introduced
- `SiteStatus` enum is defined in `lib/core/enums/site_status.dart`.
- It is used by:
  - `lib/features/sites/widgets/site_form.dart`
  - `lib/features/sites/models/site_model.dart`
  - `lib/features/sites/screens/site_details_screen.dart`

## Which layer expects `String`
- `lib/features/sites/providers/site_provider.dart`
  - `createSiteProvider` expects `String status`
  - `updateSiteProvider` expects `String status`
- `lib/features/sites/repositories/site_repository.dart`
  - `createSite()` expects `String status`
  - `updateSite()` expects `String status`
- Firestore persistence uses a string field for `status`.

## Which layer expects `SiteStatus`
- `lib/features/sites/widgets/site_form.dart`
  - `DropdownButtonFormField<SiteStatus>` returns `SiteStatus`
  - `SiteFormState.status` is `SiteStatus`
- `lib/features/sites/models/site_model.dart`
  - `final SiteStatus status;`
  - `SiteModel` constructors and `copyWith` use `SiteStatus`

## Recommended minimal fix

### Option A: Convert enum to string before provider call
- In `add_site_screen.dart`, pass `formState.status.name` instead of `formState.status`.
- Remove the incorrect runtime tuple cast.

This is the smallest fix because the repository already persists status as a string.

### Option B: Change provider and repository types to accept `SiteStatus`
- Update `createSiteProvider` / `updateSiteProvider` to use `SiteStatus` instead of `String`.
- Keep repository methods accepting `String`, or update repository to call `status.name` when writing.
- This preserves the domain model type through the provider layer.

## Best recommendation

The most direct minimal fix is to make the submit path convert the enum to its string name before calling the provider.

Example:
- `status: formState.status.name`

This preserves current repository expectations and avoids the invalid cast.

## Root cause

The Bug arises because `SiteForm` produces a typed enum value (`SiteStatus`), while the site creation layer is declared to accept a raw `String` status. The runtime cast in `add_site_screen.dart` hides the real type mismatch until execution.
