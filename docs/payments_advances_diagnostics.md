# Payments and Advances Diagnostics

## Search and Analysis Scope
- Files read:
  - `lib/features/payments/providers/payment_provider.dart`
  - `lib/features/payments/repositories/payment_repository.dart`
  - `lib/features/advances/providers/advance_provider.dart`
  - `lib/features/advances/repositories/advance_repository.dart`
  - `lib/core/providers/company_provider.dart`
  - `lib/features/auth/providers/auth_provider.dart`
  - `docs/error_handling_audit.md`
  - `.ai/windsurfrules.md`

## Firestore queries

### Payments
- `payments` collection queries:
  - `where('companyId', isEqualTo: companyId).orderBy('createdAt', descending: true)`
  - `where('companyId', isEqualTo: companyId).where('status', isEqualTo: status).orderBy('createdAt', descending: true)`
  - `where('companyId', isEqualTo: companyId).where('labourId', isEqualTo: labourId).orderBy('createdAt', descending: true)`
- `calculatePaymentSummaryForPeriod` reads:
  - `attendance` collection with `where('companyId', isEqualTo: companyId)`
  - `where('labourId', isEqualTo: labourId)`
  - `where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(periodStart))`
  - `where('date', isLessThan: Timestamp.fromDate(periodEnd))`
  - `advances` collection with `where('companyId', isEqualTo: companyId)`
  - `where('labourId', isEqualTo: labourId)`
  - `where('paidBack', isEqualTo: false)`

### Advances
- `advances` collection queries:
  - `where('companyId', isEqualTo: companyId).orderBy('date', descending: true)`
  - `where('companyId', isEqualTo: companyId).where('paidBack', isEqualTo: false).orderBy('date', descending: true)`
  - `where('companyId', isEqualTo: companyId).where('labourId', isEqualTo: labourId).orderBy('date', descending: true)`

## Required indexes

### Likely Firestore composite indexes
- `payments` collection:
  1. `companyId ASC`, `createdAt DESC`
  2. `companyId ASC`, `status ASC`, `createdAt DESC`
  3. `companyId ASC`, `labourId ASC`, `createdAt DESC`
- `attendance` collection:
  1. `companyId ASC`, `labourId ASC`, `date ASC`
    - Required for a query that filters on `companyId`, `labourId`, and a date range.
- `advances` collection:
  1. `companyId ASC`, `date DESC`
  2. `companyId ASC`, `paidBack ASC`, `date DESC`
  3. `companyId ASC`, `labourId ASC`, `date DESC`

## Loading state issues

### Provider fallbacks mask loading
- `paymentsStreamProvider` returns `Stream.value([])` while `userCompanyIdProvider` is loading.
- `pendingPaymentsCountProvider` returns `Stream.value(0)` while company ID is unresolved.
- `advancesStreamProvider` returns `Stream.value([])` during auth/company resolution.
- `outstandingAdvancesStreamProvider` and `outstandingAdvanceTotalProvider` use `Stream.value([])` and `Stream.value(0.0)` in the same way.

### Resulting UI impact
- UI cannot distinguish:
  - genuine empty data,
  - still-loading queries,
  - auth or company lookup in progress.
- Empty list/zero fallbacks can cause blank screens instead of loading spinners.

## Auth fallback usage

### `userCompanyIdProvider`
- Defined in `lib/core/providers/company_provider.dart`:
  - `return user?.uid ?? 'default-company';`
- This is a silent fallback when `currentUserProvider` is null.

### Downstream effects
- `StreamProvider` consumers load against `'default-company'` if auth is missing or delayed.
- `createPaymentProvider` and `createAdvanceProvider` await `userCompanyIdProvider.future` without validating that the resolved ID came from an authenticated user.
- If auth is unavailable, writes and queries may use an invalid company context and create hard-to-debug blank state behavior.

## Potential causes of blank/loading screens

### 1. Loading fallback values
- `Stream.value([])` and `Stream.value(0)` cause providers to emit immediate "data" values during provider initialization.
- UI may render empty payment/advance lists before real data arrives.

### 2. Auth/company ID fallback
- `default-company` can produce queries that legitimately return no documents.
- A blank screen can appear even when auth has failed or been delayed.

### 3. Exception propagation without handling
- Repository methods like `createPayment`, `calculatePaymentSummaryForPeriod`, and `createAdvance` do not catch Firestore exceptions.
- Providers do not translate errors into explicit loading/auth states.
- If Firestore fails due to permission, network, or auth issues, the UI may still receive no data and show a blank screen instead of an error view.

### 4. `FutureProvider` dependency on `userCompanyIdProvider.future`
- `calculatePaymentProvider` and `createAdvanceProvider` depend on the future company ID.
- If that future is delayed or fails, the provider remains unresolved and the UI may hang.

## Summary of risk areas
- `paymentsStreamProvider` and `advancesStreamProvider`: loading-state masking via empty fallback streams.
- `pendingPaymentsCountProvider` and `outstandingAdvanceTotalProvider`: count/total computations also mask loading.
- `userCompanyIdProvider`: silent auth fallback to `'default-company'` hides auth failure.
- Repository-level writes and reads: no explicit Firestore error typing, no permission-aware handling.

## Recommended attention
- Remove or replace `Stream.value([])` / `Stream.value(0)` loading fallbacks with explicit loading/error handling.
- Avoid defaulting to `'default-company'` when auth is missing; surface auth state instead.
- Add Firestore composite indexes for the identified queries.
- Ensure UI can render distinct loading, empty, and error states for payment/advance flows.
