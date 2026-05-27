# Labour Module - CivilHelp Flutter App

Complete implementation of the Labour management module for the CivilHelp Flutter application. This module follows the same architecture patterns as the Sites module and provides comprehensive CRUD operations, Riverpod state management, and Material 3 UI.

## Files Created

### Core Files
- **lib/features/labour/labour_model.dart** - Data model with Firestore serialization
- **lib/features/labour/labour_repository.dart** - Repository for Firestore CRUD operations
- **lib/features/labour/labour_provider.dart** - Riverpod providers for state management
- **lib/features/labour/index.dart** - Main export file

### Widgets
- **lib/features/labour/labour_card.dart** - Reusable card widget displaying labour information
- **lib/features/labour/labour_status_chip.dart** - Status display chip with color coding
- **lib/features/labour/labour_form.dart** - Form widget for creating/editing labour records

### Screens
- **lib/features/labour/labour_list_screen.dart** - List view of all labour records
- **lib/features/labour/add_edit_labour_screen.dart** - Create and edit labour records
- **lib/features/labour/labour_details_screen.dart** - Detailed view of a labour record

## Features Implemented

### 1. Repository (labour_repository.dart)
CRUD operations with Firestore backend:
- ✅ `createLabour()` - Add new labour records
- ✅ `updateLabour()` - Update existing labour records
- ✅ `updateLabourStatus()` - Change labour status only
- ✅ `getLabourByCompanyStream()` - Stream all labour for company
- ✅ `getLabourBySiteStream()` - Stream labour assigned to specific site
- ✅ `getLabourByStatusStream()` - Stream labour filtered by status
- ✅ `searchLabourByName()` - Search labour by full name
- ✅ `getLabourById()` - Fetch single labour record
- ✅ `deleteLabour()` - Delete labour record

### 2. Providers (labour_provider.dart)
Riverpod state management with automatic invalidation:
- ✅ `labourRepositoryProvider` - Repository instance
- ✅ `labourStreamProvider` - Stream of all labour for user's company
- ✅ `labourBySiteStreamProvider` - Labour filtered by site
- ✅ `labourByStatusStreamProvider` - Labour filtered by status
- ✅ `labourByIdProvider` - Single labour details
- ✅ `searchLabourProvider` - Search results
- ✅ `createLabourProvider` - Create new labour
- ✅ `updateLabourProvider` - Update labour record
- ✅ `updateLabourStatusProvider` - Update status only
- ✅ `deleteLabourProvider` - Delete labour record

### 3. Widgets

#### LabourCard (labour_card.dart)
Displays labour summary information:
- Labour name (prominent title)
- Phone number with icon
- Assigned site location
- Daily wage in rupees
- Status chip (color-coded)
- Edit/Delete popup menu
- Tap to navigate to details

#### LabourStatusChip (labour_status_chip.dart)
Reusable status display with colors:
- Active → Green
- Inactive → Grey
- On Leave → Orange
- Configurable font size and padding

#### LabourForm (labour_form.dart)
Complete form for labour data entry:
- Full name (required, text validation)
- Phone number (required, min 10 digits)
- Aadhaar number (required, exactly 12 digits)
- Daily wage (required, decimal validation)
- Site assignment (dropdown from available sites)
- Joined date (date picker, defaults to today)
- Status (dropdown: active/inactive/onLeave)
- Form validation on all fields
- Save button with loading state
- Exposes state via getters for parent access

### 4. Screens

#### LabourListScreen (labour_list_screen.dart)
Main list view with:
- AppScaffold with FAB for adding new labour
- Stream-based live data
- Pull-to-refresh functionality
- Empty state with action button
- Error state with retry button
- Labour cards with tap navigation
- Edit/Delete actions on each card

#### AddEditLabourScreen (add_edit_labour_screen.dart)
Create/Edit functionality:
- Detects create vs edit mode based on labourId parameter
- Loads available sites for assignment dropdown
- Pre-populates form in edit mode
- Handles form submission
- Shows success/error messages
- Navigates back on success
- Loading state during submission

#### LabourDetailsScreen (labour_details_screen.dart)
Detailed view with:
- Header with labour name and status chip
- Organized information sections (Contact, Work, Additional)
- All labour details displayed clearly
- Edit button → navigates to edit screen
- Mark as On Leave button (if active)
- Mark as Inactive button (if active/on leave)
- Delete button with confirmation
- Status change confirmation dialogs
- Created by and timestamps

## Data Model

```dart
class LabourModel {
  String id;                    // Document ID from Firestore
  String fullName;              // Labour's full name
  String phoneNumber;           // Contact phone number
  String aadhaarNumber;         // 12-digit Aadhaar ID
  double dailyWage;             // Daily wage in rupees
  String assignedSiteId;        // Reference to site document
  String assignedSiteName;      // Cached site name for display
  LabourStatus status;          // Active/Inactive/OnLeave
  DateTime joinedDate;          // When labour joined
  String companyId;             // Company this labour belongs to
  DateTime createdAt;           // Record creation timestamp
  String createdBy;             // User ID who created record
}
```

## Firestore Collection Structure

Collection: `labour`
Document Fields:
```
fullName: string
phoneNumber: string
aadhaarNumber: string
dailyWage: number
assignedSiteId: string (reference)
assignedSiteName: string
joinedDate: timestamp
status: string (enum name)
companyId: string
createdAt: timestamp
createdBy: string
```

Indexes:
- `(companyId, createdAt)` - For listing all labour
- `(assignedSiteId, createdAt)` - For labour by site
- `(companyId, status, createdAt)` - For labour by status
- `(fullName)` - For name search (with orderBy)

## Status Enum

From `core/enums/labour_status.dart`:
```dart
enum LabourStatus {
  active,    // Currently working
  inactive,  // No longer active
  onLeave,   // Temporarily away
}
```

## Usage

### Import the module
```dart
import 'package:civilhelp/features/labour/index.dart';
```

### Use in routing
```dart
// In your routing configuration
'/labour' → LabourListScreen()
'/add-labour' → AddEditLabourScreen()
'/edit-labour' → AddEditLabourScreen(labourId: id)
'/labour-details' → LabourDetailsScreen(labourId: id)
```

### Use in widgets
```dart
// Access labour stream
final labourAsync = ref.watch(labourStreamProvider);

// Create new labour
await ref.read(createLabourProvider((
  'John Doe',
  '9876543210',
  '123456789012',
  500.0,
  'siteId123',
  'Site Name',
  DateTime.now(),
  'active',
)).future);

// Update labour
await ref.read(updateLabourProvider((
  labourId,
  'Jane Doe',
  // ... other fields
)).future);

// Delete labour
await ref.read(deleteLabourProvider(labourId).future);
```

## Architecture Patterns

Following CivilHelp's established patterns:

1. **Repository Pattern** - All Firestore operations isolated in repository
2. **Riverpod State Management** - Functional, type-safe state management
3. **Async/Await** - Non-blocking operations with proper error handling
4. **Stream Providers** - Real-time data synchronization
5. **Family Providers** - Parameterized providers for specific records
6. **Provider Invalidation** - Automatic cache invalidation on mutations
7. **Material 3 UI** - Modern Flutter Material Design 3
8. **AppScaffold** - Responsive layout with drawer/nav support
9. **Null Safety** - 100% null-safe code
10. **Error Handling** - Try-catch with user feedback

## Validation

All form fields include validation:
- **Full Name** - Required, non-empty
- **Phone** - Required, minimum 10 digits
- **Aadhaar** - Required, exactly 12 digits
- **Wage** - Required, valid decimal number
- **Site** - Required field selection
- **Status** - Always has a default value

## Error Handling

- Repository methods use try-catch with rethrow
- Providers handle loading/error/data states
- UI shows error messages in SnackBars
- Retry buttons on error states
- Loading indicators during operations

## Material 3 Compliance

- Uses AppBar with proper elevation
- Color-coded status indicators
- Consistent padding and spacing (16px grid)
- Rounded corners (8px border radius)
- Icons for visual cues
- Proper typography hierarchy
- Responsive layouts
- Proper button styling

## Production Ready

✅ Full null safety
✅ Error handling on all operations
✅ Form validation on all fields
✅ Loading states during operations
✅ Proper state management
✅ Memory leak prevention (proper disposal)
✅ Real-time data with streams
✅ Offline-friendly design
✅ Proper date handling with intl
✅ Comprehensive UI/UX feedback

## Dependencies

Required packages (already in pubspec.yaml):
- flutter_riverpod: ^2.6.1
- cloud_firestore: ^5.6.11
- intl: ^0.20.2
- Material 3 from Flutter

## Future Enhancements

Potential additions:
- Bulk operations (import/export)
- Attendance tracking integration
- Wage calculation and salary slips
- Performance ratings
- Document upload (photo/ID)
- Communication templates
- Leave tracking
- Performance analytics
- Bulk status updates
