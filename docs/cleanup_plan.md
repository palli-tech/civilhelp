# Cleanup Plan

## Summary
This cleanup plan is based on the current inventory and duplicate analysis instructions. No application code has been changed.

## Duplicate / Similar Findings

### Duplicate models
- No exact duplicate model classes were identified.
- `LabourEntity` and `LabourModel` are separate domain/data artifacts and should remain distinct.

### Duplicate providers
- No duplicate provider files were identified.
- Each module currently has one provider where applicable.

### Duplicate widgets
- No exact duplicate widgets were identified.
- Similar widget patterns exist in different modules, but they are not true duplicates:
  - `DashboardCard` and `QuickActionTile` are both dashboard-related but serve different UI roles.
  - `SiteCard` and `LabourCard` are module-specific list/card widgets.

### Potential unused / placeholder files
- `lib/features/expenses/index.dart`
- `lib/features/invoices/index.dart`
- `lib/features/reports/index.dart`
- `lib/features/settings/index.dart`

These files appear to be placeholders without concrete feature implementation. They are not active duplicates but may represent dormant modules.

## Classification

### SAFE TO REMOVE
- None identified at this time.

### SAFE TO MERGE
- None identified; existing artifact separation appears intentional.

### NEEDS REVIEW
- Placeholder feature modules:
  - `expenses`
  - `invoices`
  - `reports`
  - `settings`

These directories currently contain only `index.dart`. Review the roadmap before removing or extending them.

### DO NOT TOUCH
- Existing feature modules and their current providers, repositories, and models.
- Cross-module widget similarities that are not exact duplicates.
- `LabourEntity` / `LabourModel` relationship.

## Recommended cleanup actions

1. Do not remove or refactor current feature files without a roadmap decision.
2. Review placeholder modules before converting them into implemented features or deleting them.
3. Preserve current module boundaries and widget ownership; avoid merging module-specific widgets unless the feature design requires it.
4. Keep the current repository/provider/model patterns intact during any future cleanup.

## Notes
- The current project inventory is stable and does not show duplicate artifacts that are clearly safe to remove.
- Any cleanup that touches feature modules should be done with explicit business context, not purely based on file similarity.
