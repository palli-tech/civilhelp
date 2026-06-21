# Error Handling Audit

This audit reviews provider and repository error handling, loading/empty-state behavior, Firestore permission risk, and null safety patterns in the codebase.

## Scope
- Providers in `lib/features/*/providers` and `lib/core/providers`
- Repositories in `lib/features/*/repositories` and `lib/features/labour/data/repositories`
- Auth service in `lib/features/auth/services/auth_service.dart`

## Key findings

### 1. Unhandled exceptions
- Several repository write methods do not catch exceptions at all and therefore propagate raw Firebase and network errors directly to callers.
  - `PaymentRepository.createPayment`
  - `PaymentRepository.calculatePaymentSummaryForPeriod`
  - `AdvanceRepository.createAdvance`
  - `AttendanceRepository.createAttendance`
  - `PaymentRepository.createPayment`/`AdvanceRepository.createAdvance`/`AttendanceRepository.createAttendance` all lack any `try/catch`.
- Repositories that do catch exceptions typically only use generic `catch (e) { rethrow; }`.
  - This preserves the error but provides no domain-specific or user-facing translation.
  - It also means the app cannot distinguish permission failures from invalid input or network errors.
- Some repository stream methods catch only synchronous errors in the method body.
  - Firestore snapshot stream errors still flow through without structured handling.

### 2. Missing loading states and loading-state masking
- Many providers convert loading into empty/default values instead of preserving a distinct loading state.
  - `sitesStreamProvider`, `paymentsStreamProvider`, `advancesStreamProvider`, `attendanceStreamProvider`, `activeSitesCountProvider`, `activeLabourCountProvider`, `labourPresentTodayCountProvider`, `pendingPaymentsCountProvider`, `outstandingAdvanceTotalProvider` all return `Stream.value([])`, `Stream.value(0)`, or `Stream.value(0.0)` while `userCompanyIdProvider` is loading.
- This pattern hides the difference between:
  - no data available,
  - data still loading,
  - and `userCompanyIdProvider` not yet resolved.
- In turn, UI consumers cannot reliably show loading spinners versus genuine empty-state content.

### 3. Missing empty-state semantics
- Empty lists or zero counts are returned as loading fallbacks.
  - This makes it impossible to distinguish empty data sets from actual loading or permission-denied failures.
- Providers generally do not define an explicit error-to-empty mapping other than `Stream.error(error)`.
  - In places where the provider returns a default empty collection on loading, no fallback for real empty data is defined at provider level.

### 4. Firestore permission failure risk
- There is no explicit handling for Firestore permission failures anywhere in repositories.
  - No code checks for `FirebaseException`, `permission-denied`, or `unauthenticated`.
- Generic rethrows and stream errors can surface a raw Firestore exception to the UI.
- `AuthService._createUserIfNotExists` writes to Firestore without permission-specific recovery or fallback.
- This means permission errors are likely to be treated as generic failures rather than actionable auth/permissions issues.

### 5. Null safety and auth fallback risks
- `userCompanyIdProvider` returns `user?.uid ?? 'default-company'`.
  - If the authenticated user is null, the app silently falls back to a fake tenant ID rather than reporting an auth or loading issue.
- `labour_provider.dart` uses `currentUser?.uid ?? 'default-company'` in status filtering and create operations.
  - This can cause writes and queries to use an invalid `companyId` and hide auth failure.
- `site_provider.dart` uses `ref.watch(userCompanyIdProvider).value ?? 'default-company'`.
  - Accessing `.value` can silently select `'default-company'` before the provider resolves.
- `createSiteProvider`, `createLabourProvider`, `createPaymentProvider`, `createAdvanceProvider`, and `createAttendanceProvider` all substitute fallback values when current user data is missing.
  - These fallbacks risk invalid data being written rather than raising a recoverable loading/auth error.

## Specific provider-level issues

### `lib/features/sites/providers/site_provider.dart`
- The stream provider returns `Stream.value([])` while company ID is loading.
- `createSiteProvider` uses `userCompanyIdProvider.value ?? 'default-company'` and `currentUser?.uid ?? 'unknown'`, hiding missing user data.
- `updateSiteProvider` and `deleteSiteProvider` do not validate or expose current auth state.

### `lib/features/labour/presentation/providers/labour_provider.dart`
- `labourStreamProvider` returns `Stream.value([])` when `currentUserProvider` is null.
  - This conflates unauthenticated state with an empty labour list.
- `labourByStatusStreamProvider` and `searchLabourProvider` use `'default-company'` when user data is missing.
- `createLabourProvider` and update/delete providers rely on fallback IDs and do not handle missing auth explicitly.

### `lib/features/payments/providers/payment_provider.dart`
- `paymentsStreamProvider` and `pendingPaymentsCountProvider` mask loading with empty values.
- `calculatePaymentProvider` and `createPaymentProvider` have no local error handling beyond repository propagation.
- `createPaymentProvider` uses `companyId` from `userCompanyIdProvider.future` but does not guard against missing/invalid company IDs.

### `lib/features/advances/providers/advance_provider.dart`
- `advancesStreamProvider`, `outstandingAdvancesStreamProvider`, and `outstandingAdvanceTotalProvider` mask loading as empty data.
- `createAdvanceProvider` has no local exception handling and relies on company ID resolution.

### `lib/features/attendance/providers/attendance_provider.dart`
- `attendanceStreamProvider` and platform variants use `Stream.value([])` as a loading placeholder.
- `createAttendanceProvider` does not guard against missing current user or company ID except via fallback values.

### `lib/core/providers/company_provider.dart`
- This provider uses current user ID to infer the company.
- It returns a fallback `default-company` when `currentUserProvider` is null, which can hide auth issues.

### `lib/features/auth/providers/auth_provider.dart`
- `signInWithGoogleProvider` and `signOutProvider` simply rethrow generic exceptions.
- There is no dedicated provider or mapping for sign-in failures such as user-cancelled sign-in, revoked consent, or permission-denied.

## Specific repository-level issues

### `lib/features/sites/repositories/site_repository.dart`
- Repository methods catch and rethrow, but do not convert Firestore errors into domain-specific exceptions.
- Stream query errors are wrapped by `Stream.error(e)` only for synchronous failures.
- `getSiteById` returns `null` for missing documents, which is safe, but consumers must explicitly handle null.

### `lib/features/labour/data/repositories/labour_repository_impl.dart`
- No explicit error handling or translation for create/update/delete operations beyond generic rethrow.
- Search and get-by-ID methods also rethrow without domain context.
- `getLabourBySiteStream`, `getLabourByStatusStream`, and other streams use catch/rethrow only at the builder level.

### `lib/features/payments/repositories/payment_repository.dart`
- `createPayment` is unguarded and can fail with raw Firestore errors.
- `calculatePaymentSummaryForPeriod` performs two Firestore reads and domain calculations without any exception handling.
- Query methods use generic catch blocks only for immediate method errors.

### `lib/features/advances/repositories/advance_repository.dart`
- `createAdvance` has no exception handling.
- Stream methods catch generic errors and return `Stream.error(e)`.

### `lib/features/attendance/repositories/attendance_repository.dart`
- `createAttendance` has no exception handling.
- Stream methods return `Stream.error(e)` only on synchronous failures.
- `getAttendanceForTodayStream` wraps a stream call redundantly in `try/catch`.

## Recommendations
- Avoid using `Stream.value([])` or `Stream.value(0)` as a loading fallback.
  - Instead propagate loading states and let UI render loading indicators explicitly.
- Replace silent fallbacks like `default-company` with an explicit auth/error state.
- Add permission-aware handling for Firestore `FirebaseException`.
  - Catch specific Firestore error codes such as `permission-denied` and map them to user-facing failures.
- Add domain-level error translation in repositories.
  - Convert raw exceptions into typed exceptions or service errors before they reach UI.
- Centralize auth/company state handling so providers do not independently default to invalid IDs.
- Ensure `FutureProvider` and `StreamProvider` consumers have clear loading/error/empty states.

## Risk summary
- High: Firestore permission failures are not handled distinctly.
- High: Auth fallback values can hide missing user state and create invalid queries/writes.
- Medium: Loading indicators are masked by default empty data.
- Medium: Generic `rethrow` propagation means UI may receive raw exceptions without meaning.
- Low: Null-safe `doc.exists` handling is okay, but invalid fallbacks remain a risk.
