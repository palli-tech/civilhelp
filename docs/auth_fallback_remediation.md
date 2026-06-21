# Auth Fallback Remediation

This document analyzes every usage of `default-company` and `unknown` in source code and recommends safer auth/error handling.

## Reviewed sources
- `.ai/windsurfrules.md`
- `docs/error_handling_audit.md`

## Occurrences

### 1. `lib/core/providers/company_provider.dart`
- Current behavior
  - `userCompanyIdProvider` returns `user?.uid ?? 'default-company'`.
- Risk
  - Auth failure or unauthenticated state is masked as a valid company ID.
  - Queries and downstream providers may execute against a phantom tenant, causing silent data isolation or invalid reads.
- Recommended implementation
  - Do not return a fake company ID.
  - Instead propagate an auth-specific error or a distinct unauthenticated/loading state.
  - Example: return `Future.error(AuthException.notAuthenticated)` or make the provider `AsyncValue<String?>` and require the UI to handle null/auth state explicitly.

### 2. `lib/features/sites/providers/site_provider.dart`
- Current behavior
  - `createSiteProvider` uses `ref.watch(userCompanyIdProvider).value ?? 'default-company'`.
  - It also sets `createdBy: currentUser?.uid ?? 'unknown'`.
- Risk
  - `default-company` can create a site under an invalid company namespace.
  - `unknown` hides the real author/user ID, breaking audit trails and making post-mortem debugging harder.
- Recommended implementation
  - Resolve `userCompanyIdProvider` through `await ref.watch(userCompanyIdProvider.future)` and fail if no company ID is available.
  - Require `currentUser` and throw a clear auth exception if absent, instead of using `unknown`.
  - Ensure site creation stops until valid auth/user context exists.

### 3. `lib/features/labour/presentation/providers/labour_provider.dart`
- Current behavior
  - `labourStreamProvider` uses `user?.uid ?? 'default-company'`.
  - `labourByStatusStreamProvider` and `searchLabourProvider` use `currentUser?.uid ?? 'default-company'`.
  - `createLabourProvider` also uses `currentUser?.uid ?? 'default-company'` and `createdBy: currentUser?.uid ?? 'unknown'`.
- Risk
  - Queries for labour data can accidentally target the fake `default-company` tenant, producing empty or misleading results.
  - Creating labour records under `default-company` creates invalid or orphaned data.
  - `unknown` hides the origin of created records and weakens auditing.
- Recommended implementation
  - Require a valid signed-in user before starting any labour query or mutation.
  - Avoid fallback values; return error/loading states when `currentUser` is unavailable.
  - For create flows, use the authenticated user UID for `createdBy` and block the operation if no user is present.

### 4. `lib/features/attendance/providers/attendance_provider.dart`
- Current behavior
  - `createAttendanceProvider` sets `createdBy: currentUser?.uid ?? 'unknown'`.
- Risk
  - Missing user identity is concealed as `unknown`.
  - Attendance records lose a clear author field and may not be traceable.
- Recommended implementation
  - Require a valid `currentUser` before creating attendance.
  - Throw or propagate a dedicated auth error when the user is absent.
  - Use the real UID for `createdBy` and avoid writing records with `unknown`.

### 5. `lib/features/attendance/models/attendance_model.dart`
- Current behavior
  - `AttendanceModel.fromMap` uses `status: map['status'] ?? 'unknown'`.
- Risk
  - Missing or malformed `status` values are silently converted to `unknown`.
  - This can hide data quality issues, invalidate reports, and make business logic harder to trust.
- Recommended implementation
  - Prefer explicit validation for `status` when parsing Firestore data.
  - If `status` is absent, throw a parse exception or map to a well-defined fallback such as `AttendanceStatus.unknown` in a typed enum.
  - Log or surface invalid documents so the issue can be corrected instead of silently accepting bad data.

## Summary
- `default-company` is a high-risk auth fallback because it hides missing authentication and can cause invalid tenant queries/writes.
- `unknown` is a low-fidelity audit fallback that conceals the true user identity and should be replaced with explicit auth failure handling.
- The safest implementation pattern is to fail fast on missing auth context, propagate clear errors, and let the UI render an auth/loading state instead of writing defaults.
