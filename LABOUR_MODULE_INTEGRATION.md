# Labour Module Integration Guide

This guide explains how to integrate the Labour module into your CivilHelp app routing and navigation.

## Step 1: Update Router Configuration

In your `go_router` or routing configuration file, add these routes:

```dart
// Labour routes
GoRoute(
  path: '/labour',
  builder: (context, state) => const LabourListScreen(),
),
GoRoute(
  path: '/add-labour',
  builder: (context, state) => const AddEditLabourScreen(),
),
GoRoute(
  path: '/edit-labour',
  builder: (context, state) => AddEditLabourScreen(
    labourId: state.pathParameters['id'] as String?,
  ),
),
GoRoute(
  path: '/labour-details/:id',
  builder: (context, state) => LabourDetailsScreen(
    labourId: state.pathParameters['id']!,
  ),
),
```

OR if using Navigator 1.0 (named routes):

```dart
// In your route table
'/labour': (context) => const LabourListScreen(),
'/add-labour': (context) => const AddEditLabourScreen(),
'/edit-labour': (context) {
  final labourId = ModalRoute.of(context)?.settings.arguments as String?;
  return AddEditLabourScreen(labourId: labourId);
},
'/labour-details': (context) {
  final labourId = ModalRoute.of(context)?.settings.arguments as String;
  return LabourDetailsScreen(labourId: labourId);
},
```

## Step 2: Update Navigation Menu

Add Labour to your app drawer/bottom navigation:

```dart
// In app drawer
ListTile(
  leading: const Icon(Icons.people),
  title: const Text('Labour'),
  onTap: () {
    Navigator.pushNamed(context, '/labour');
  },
),
```

## Step 3: Update Dashboard

Add quick access to Labour management on your dashboard:

```dart
// Import
import 'package:civilhelp/features/labour/index.dart';

// In Dashboard
ElevatedButton(
  onPressed: () => Navigator.pushNamed(context, '/labour'),
  child: const Text('Manage Labour'),
),
```

## Step 4: Import in Main

Add to your main app imports:

```dart
import 'package:civilhelp/features/labour/index.dart';
```

## Integration Examples

### From Sites Screen (Navigate to Labour for a Site)

```dart
// Navigate to labour list and filter by site
// Option 1: Navigate and let user filter
Navigator.pushNamed(context, '/labour');

// Option 2: Pass site context if implementing filtered view
// You can extend labourBySiteStreamProvider in screens
```

### From Dashboard

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  return Column(
    children: [
      // ... other dashboard items
      DashboardCard(
        title: 'Labour Management',
        icon: Icons.people,
        onTap: () => Navigator.pushNamed(context, '/labour'),
      ),
    ],
  );
}
```

### From Sites Details (Show Labour for Site)

```dart
class SiteDetailsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Site details...
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/labour'),
          child: const Text('View Labour'),
        ),
      ],
    );
  }
}
```

## Firestore Setup Required

Before using the module, ensure your Firestore has:

1. **Collection: `labour`** - Already created
2. **Proper Security Rules** - Allow authenticated users to read/write

Example Firestore Security Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /labour/{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Optional: Restrict by company
    match /labour/{labour} {
      allow read, write: if request.auth != null && 
        get(/databases/$(database)/documents/labour/$(labour)).data.companyId == request.auth.uid;
    }
  }
}
```

## Testing

### Quick Test Flow

1. **Add Labour**
   - Navigate to `/labour`
   - Click FAB
   - Fill form with test data
   - Click Save

2. **View Labour**
   - Labour appears in list
   - Click card to see details

3. **Edit Labour**
   - Click Edit in details or card menu
   - Modify data
   - Click Save

4. **Change Status**
   - Click Mark as On Leave
   - Confirm dialog
   - Status updates in real-time

5. **Delete Labour**
   - Click Delete button
   - Confirm dialog
   - Labour removed from list

## API Endpoints (Firestore Collections Used)

All operations use the `labour` collection:

- **Add**: `collection('labour').add(data)`
- **Read**: `collection('labour').doc(id).get()`
- **Read All**: `collection('labour').where(...).snapshots()`
- **Update**: `collection('labour').doc(id).update(data)`
- **Delete**: `collection('labour').doc(id).delete()`

## Error Handling in Integration

The module handles errors gracefully, but ensure your router catches any exceptions:

```dart
// If using GoRouter, add error handler
GoRouter(
  errorBuilder: (context, state) => ErrorScreen(error: state.error),
  // ... other routes
);
```

## Provider Usage in Other Modules

Other modules can use labour data:

```dart
// In another module/screen
final labourAsync = ref.watch(labourStreamProvider);

// Or get labour for specific site
final siteLabourAsync = ref.watch(labourBySiteStreamProvider(siteId));

// Or search
final searchResults = ref.watch(searchLabourProvider(searchTerm));
```

## State Management Notes

- **Automatic Invalidation**: Creating/updating/deleting labour automatically refreshes the list
- **Real-time Updates**: StreamProviders provide real-time data changes
- **Lazy Loading**: Data only fetches when watched
- **Memory Efficient**: Providers cache data appropriately

## Firestore Indexes

The repository uses these queries, ensure indexes exist:

1. `collection: labour, fields: companyId (Asc), createdAt (Desc)`
2. `collection: labour, fields: assignedSiteId (Asc), createdAt (Desc)`
3. `collection: labour, fields: companyId (Asc), status (Asc), createdAt (Desc)`

Firestore will prompt to create indexes automatically when queries run.

## Troubleshooting

### Labour list shows empty
- Verify Firestore collection `labour` exists
- Check Firestore Security Rules allow reads
- Verify `companyId` matches current user's UID

### Can't add labour
- Check Firestore Security Rules allow writes
- Verify all form fields are validated
- Check Firebase quota/limits not exceeded

### Changes not reflecting in real-time
- Ensure StreamProvider is being watched
- Check Firestore connection is active
- Verify Riverpod is properly configured

### Images not showing in cards
- Module uses icons only, no images
- Customize labour_card.dart if needed

## Next Steps

1. Update router configuration
2. Add Labour to navigation menu
3. Test create/read/update/delete flows
4. Integrate into relevant screens
5. Set up Firestore indexes (auto-prompted)
6. Deploy and monitor

## Support

For issues or questions:
- Check LABOUR_MODULE_README.md for full documentation
- Review labour_provider.dart for available providers
- Check error messages in SnackBars during operations
- Review Firebase console for data/permission issues
