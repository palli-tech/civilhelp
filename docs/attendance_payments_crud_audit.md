# Attendance and Payments CRUD Audit

## Attendance Module

### Files inspected
- `lib/features/attendance/screens/attendance_screen.dart`
- `lib/features/attendance/providers/attendance_provider.dart`
- `lib/features/attendance/repositories/attendance_repository.dart`
- `lib/features/attendance/models/attendance_model.dart`
- `lib/app/router.dart`
- `lib/shared/layouts/bottom_nav.dart`
- `lib/shared/layouts/app_drawer.dart`

### CRUD and feature status
1. Create implemented? Yes
   - `AttendanceScreen` includes a FAB and an "Mark Attendance" dialog.
   - It calls `createAttendanceProvider` to persist records through `AttendanceRepository.createAttendance()`.

2. Read implemented? Yes
   - `attendanceStreamProvider` streams all company attendance records.
   - `AttendanceScreen` displays a list of attendance records when data is available.

3. Update implemented? No
   - There is no update or edit flow for attendance records in the module.
   - `AttendanceRepository` exposes no update method.

4. Delete implemented? No
   - No delete flow is present in the screen or provider.
   - The repository has no delete method for attendance.

5. Detail screen implemented? No
   - Attendance is shown only as a list within `AttendanceScreen`.
   - There is no dedicated attendance detail screen.

6. Edit screen implemented? No
   - There is no separate edit screen for attendance.
   - The module only supports create via modal dialog.

7. Navigation wired? Yes
   - `AppRoutes.attendance` is declared in `lib/app/router.dart`.
   - The route is linked to `AttendanceScreen`.
   - Users can navigate via `BottomNav` and `AppDrawer`.

8. Permission checks present? Partial
   - No explicit role-based permission gating is present in the attendance module.
   - Data access is scoped by authenticated user/company via `userCompanyIdProvider` in `attendance_provider.dart`.

## Payments Module

### Files inspected
- `lib/features/payments/screens/payments_screen.dart`
- `lib/features/payments/providers/payment_provider.dart`
- `lib/features/payments/repositories/payment_repository.dart`
- `lib/features/payments/models/payment_model.dart`
- `lib/app/router.dart`
- `lib/shared/layouts/bottom_nav.dart`
- `lib/shared/layouts/app_drawer.dart`

### CRUD and feature status
1. Create implemented? Yes
   - `PaymentsScreen` includes a FAB and a "Create Payment" dialog.
   - It uses `calculatePaymentProvider` to compute payment summary and `createPaymentProvider` to persist records.

2. Read implemented? Yes
   - `paymentsStreamProvider` streams all company payment records.
   - `PaymentsScreen` displays payments in a list with status and amount.

3. Update implemented? No
   - There is no update/edit workflow in the payments module.
   - `PaymentRepository` does not expose an update method.

4. Delete implemented? No
   - There is no delete option in the payments UI.
   - The repository has no delete method for payments.

5. Detail screen implemented? No
   - Payments are displayed in a list only.
   - No dedicated payment detail screen exists.

6. Edit screen implemented? No
   - The module does not include an edit screen for payments.
   - Payment creation is done through a dialog inside `PaymentsScreen`.

7. Navigation wired? Yes
   - `AppRoutes.payments` is declared in `lib/app/router.dart`.
   - The route is connected to `PaymentsScreen`.
   - Navigation is available through `BottomNav` and `AppDrawer`.

8. Permission checks present? Partial
   - There is no explicit role-based permission logic in the payments module.
   - Data is scoped by authenticated user/company via `userCompanyIdProvider` in `payment_provider.dart`.

## Notes
- Both modules are implemented as self-contained list screens with create dialogs, not as full CRUD feature sets.
- The routes and navigation are wired correctly for both modules.
- The security model is limited to company scoping rather than explicit permission checks.
