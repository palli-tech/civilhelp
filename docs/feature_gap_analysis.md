# Feature Gap Analysis

## End-User Workflows

### Completed workflows
- Authentication: splash and login flow are present.
- Dashboard access: role-specific dashboards exist for admin, supervisor, owner, and partner.
- Site management: list, add, edit, and details screens are implemented.
- Labour management: labour list, details, and add/edit workflows are implemented.
- Attendance tracking: attendance listing and marking via a dialog flow are available.
- Payments: payment listing and creation via dialog are available.
- Advances: advance listing and creation via dialog are available.

### Missing workflow coverage
- No explicit ticketed workflow exists for payment approval, reconciliation, or editing existing payments.
- Advances appear to support creation and listing only; there is no visible update/repayment or approval workflow.
- Attendance supports marking only; there is no edit or delete of attendance records visible from the screen.
- Labour workflows do not surface bulk operations or shift/site reassignment flows.
- Site workflows are in place, but there is no explicit site-level activity dashboard or assignment workflow for labour/attendance/payments.

## Missing CRUD

### Sites
- CRUD appears complete: create, read, update, delete are implied by repository/provider support and the available screens.

### Labour
- Core CRUD is available through listing, details, and add/edit screens, but deletion is not surfaced in the user-facing inventory.

### Attendance
- Create + read appear available.
- Update and delete are missing from the user-facing screen flow.

### Payments
- Create + read appear available.
- Update, delete, and status transition (pending → completed) are not surfaced as explicit user actions in the inventory.

### Advances
- Create + read appear available.
- Update, delete, and repayment tracking are not evident in the current app inventory.

## Navigation Gaps

- There is no visible user-facing navigation to `expenses`, `invoices`, `reports`, or `settings` because those modules are placeholders.
- The dashboard is a central entry point, but the inventory does not indicate whether quick actions are fully connected to feature screens.
- No dedicated navigation path is listed for module-level reporting or analytics beyond the dashboard.
- No explicit route is available for detailed record views in attendance, payments, or advances.

## Reporting Gaps

- The app has a dashboard but lacks dedicated reporting screens for:
  - payment history breakdowns
  - advance repayment reports
  - attendance summaries over time
  - expense tracking
  - invoices and billing summaries
- Placeholder modules for `reports`, `expenses`, `invoices`, and `settings` imply planned reporting and admin functionality is not yet implemented.
- There is no indication of export, filtering, or aggregated reporting tools for end users.

## Production Readiness

### Strengths
- Core feature modules are present and follow a consistent provider/repository pattern.
- Authentication, site, labour, attendance, payments, and advances modules provide an initial working scope.
- Shared layout widgets and a central routing layer support consistent navigation.

### Risks / readiness gaps
- Placeholder modules indicate incomplete product scope; key business areas such as expenses, invoices, and reporting are not production-ready.
- Missing CRUD operations for attendance, payments, and advances reduce operational flexibility.
- Lack of detailed record screens and approval/status flows weakens user control and auditability.
- No explicit feature documentation for user roles and access control beyond the dashboard screens.
- No evidence of error handling or validation workflows for failed network/data operations beyond basic loading/error UI states.

## Recommendations for closing gaps
- Implement detailed record views and edit/delete actions for attendance, payments, and advances.
- Add reporting screens for attendance trends, payment aging, advance balances, and invoices.
- Build the placeholder modules (`expenses`, `invoices`, `reports`, `settings`) with clearly scoped workflows before considering production release.
- Add navigation paths from the dashboard or app drawer to all active modules and reporting pages.
- Introduce user-facing status workflows for approvals, payments completion, and advance repayment.
