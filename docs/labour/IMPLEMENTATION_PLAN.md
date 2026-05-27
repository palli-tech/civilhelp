# Labour Module Implementation Plan

## Architecture Overview
- Repository pattern (Firestore-based CRUD)
- Riverpod state management with async providers
- Three main screens (List, AddEdit, Details)
- Reusable form and card widgets
- Material 3 design
- Hive local persistence (available in project)

## File Structure
```
lib/features/labour/
├── models/
│   └── labour_model.dart (already created)
├── repositories/
│   └── labour_repository.dart
├── providers/
│   └── labour_provider.dart
├── screens/
│   ├── labour_list_screen.dart
│   ├── add_edit_labour_screen.dart
│   └── labour_details_screen.dart
├── widgets/
│   ├── labour_card.dart
│   ├── labour_form.dart
│   ├── status_chip.dart
│   └── index.dart
└── index.dart
```

## Implementation Strategy
1. Repository with CRUD + search/filter
2. Riverpod providers (list, details, actions)
3. List screen with search, empty/loading/error states
4. AddEdit screen with form validation
5. Details screen with edit/delete/status actions
6. Reusable widgets (LabourCard, Form, StatusChip)

## Key Features
- Firestore persistence
- Search by name/phone
- Active/inactive status filtering
- Loading and error states
- FAB for adding labour
- Popup menus for edit/delete
- Date/time formatting with intl
