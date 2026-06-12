# TODO

## Tenant & Company Foundation Refactor — Repository Migration (Phase 1)

### Step 1: Preparation
- [x] Verify current implementations of TenantContext, TenantProvider, and FirestorePathService

### Step 2: LabourRepository migration
- [ ] Refactor `features/labour/data/repositories/labour_repository_impl.dart` to use `FirestorePathService.labour(companyId)`

- [ ] Remove hardcoded `collection('labour')` and root access
- [ ] Update stream/query/doc refs accordingly
- [ ] Ensure injected firestore/path usage stays intact
- [ ] Verify analyzer/compile (best-effort)

### Step 3: AttendanceRepository migration
- [ ] Refactor `features/attendance/repositories/attendance_repository.dart` to use `FirestorePathService.attendance(companyId)`
- [ ] Update all CRUD/query/bulk logic to nested company path
- [ ] Ensure behaviour preserved
- [ ] Verify analyzer/compile (best-effort)

### Step 4: AdvanceRepository migration
- [ ] Refactor `features/advances/repositories/advance_repository.dart` to use `FirestorePathService.advances(companyId)`
- [ ] Verify behaviour preserved
- [ ] Verify analyzer/compile (best-effort)

### Step 5: PaymentRepository migration
- [ ] Refactor `features/payments/repositories/payment_repository.dart` to use `FirestorePathService.payments(companyId)` and `FirestorePathService.advances(companyId)`
- [ ] Ensure transaction references use nested paths
- [ ] Preserve payment logic/query behaviour
- [ ] Verify analyzer/compile (best-effort)

### Step 6: SiteRepository migration
- [ ] Refactor `features/sites/repositories/site_repository.dart` to use `FirestorePathService.sites(companyId)`
- [ ] Ensure CRUD/query/doc refs use nested paths
- [ ] Verify analyzer/compile (best-effort)

### Step 7: ReportRepository migration
- [ ] Refactor `features/reports/repositories/report_repository.dart` to use nested company paths for all data access
- [ ] Ensure report queries remain identical in behaviour
- [ ] Performance: keep logic but reduce hardcoded root paths
- [ ] Verify analyzer/compile (best-effort)

### Step 8: Riverpod wiring
- [ ] Update providers to obtain companyId from TenantContext (remove passing companyId where possible)
- [ ] Ensure tenant resolution happens before tenant-dependent screens

### Step 9: Verification snapshot
- [ ] List changed/new/deleted files
- [ ] Remaining risks
- [ ] Firestore schema summary (no rules/index changes yet)

