# Labour Module - Usage Examples

## Quick Start Examples

### Example 1: Display Labour List in Your App

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:civilhelp/features/labour/index.dart';

class LabourOverviewScreen extends ConsumerWidget {
  const LabourOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labourAsync = ref.watch(labourStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Labour Overview')),
      body: labourAsync.when(
        data: (labourList) => ListView.builder(
          itemCount: labourList.length,
          itemBuilder: (context, index) {
            final labour = labourList[index];
            return ListTile(
              title: Text(labour.fullName),
              subtitle: Text('₹${labour.dailyWage}/day'),
              trailing: LabourStatusChip(status: labour.status),
            );
          },
        ),
        loading: () => const CircularProgressIndicator(),
        error: (err, stack) => Text('Error: $err'),
      ),
    );
  }
}
```

### Example 2: Create New Labour

```dart
Future<void> addNewLabour(WidgetRef ref, BuildContext context) async {
  try {
    await ref.read(
      createLabourProvider((
        'Raj Kumar',
        '9876543210',
        '123456789012',
        500.0,
        'site_123',
        'Main Site',
        DateTime.now(),
        'active',
      )).future,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Labour added successfully!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

### Example 3: Get Labour for Specific Site

```dart
class SiteLabourWidget extends ConsumerWidget {
  final String siteId;

  const SiteLabourWidget({required this.siteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labourAsync = ref.watch(labourBySiteStreamProvider(siteId));

    return labourAsync.when(
      data: (labourList) => Text('${labourList.length} workers on this site'),
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text('Error loading labour'),
    );
  }
}
```

### Example 4: Search Labour by Name

```dart
class LabourSearchWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchTerm = useState('');
    final searchResults = ref.watch(searchLabourProvider(searchTerm.value));

    return Column(
      children: [
        TextField(
          onChanged: (value) => searchTerm.value = value,
          decoration: const InputDecoration(hintText: 'Search labour...'),
        ),
        searchResults.when(
          data: (results) => ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(results[index].fullName),
            ),
          ),
          loading: () => const CircularProgressIndicator(),
          error: (err, stack) => const Text('Search error'),
        ),
      ],
    );
  }
}
```

### Example 5: Get Labour with Active Status

```dart
class ActiveLabourWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labourAsync = ref.watch(
      labourByStatusStreamProvider('active'),
    );

    return labourAsync.when(
      data: (activeLabour) => Text(
        'Active Workers: ${activeLabour.length}',
      ),
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

### Example 6: Update Labour Status

```dart
Future<void> markLabourOnLeave(WidgetRef ref, String labourId) async {
  await ref.read(
    updateLabourStatusProvider((labourId, 'onLeave')).future,
  );
}

Future<void> markLabourInactive(WidgetRef ref, String labourId) async {
  await ref.read(
    updateLabourStatusProvider((labourId, 'inactive')).future,
  );
}
```

### Example 7: Get Labour Details

```dart
class LabourProfileWidget extends ConsumerWidget {
  final String labourId;

  const LabourProfileWidget({required this.labourId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labourAsync = ref.watch(labourByIdProvider(labourId));

    return labourAsync.when(
      data: (labour) {
        if (labour == null) {
          return const Text('Labour not found');
        }

        return Column(
          children: [
            Text('Name: ${labour.fullName}'),
            Text('Phone: ${labour.phoneNumber}'),
            Text('Aadhaar: ${labour.aadhaarNumber}'),
            Text('Daily Wage: ₹${labour.dailyWage}'),
            Text('Site: ${labour.assignedSiteName}'),
            LabourStatusChip(status: labour.status),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

### Example 8: Delete Labour

```dart
void deleteLabourWithConfirmation(
  BuildContext context,
  WidgetRef ref,
  String labourId,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Labour?'),
      content: const Text('This action cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await ref.read(deleteLabourProvider(labourId).future);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Labour deleted')),
            );
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}
```

### Example 9: Form Integration

```dart
class CustomLabourForm extends ConsumerWidget {
  final String? labourId;

  const CustomLabourForm({this.key, this.labourId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<LabourFormState>();

    return SingleChildScrollView(
      child: Column(
        children: [
          LabourForm(
            key: formKey,
            onSubmit: () async {
              final form = formKey.currentState;
              if (form != null) {
                await ref.read(
                  createLabourProvider((
                    form.fullName,
                    form.phoneNumber,
                    form.aadhaarNumber,
                    form.dailyWage,
                    form.assignedSiteId,
                    form.assignedSiteName,
                    form.joinedDate,
                    form.status.name,
                  )).future,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
```

### Example 10: Card Widget Usage

```dart
class LabourGridWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labourAsync = ref.watch(labourStreamProvider);

    return labourAsync.when(
      data: (labourList) => GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
        itemCount: labourList.length,
        itemBuilder: (context, index) {
          final labour = labourList[index];
          return LabourCard(
            labour: labour,
            onTap: () => Navigator.pushNamed(
              context,
              '/labour-details',
              arguments: labour.id,
            ),
            onEdit: () => Navigator.pushNamed(
              context,
              '/edit-labour',
              arguments: labour.id,
            ),
            onDelete: () => deleteLabourWithConfirmation(
              context,
              ref,
              labour.id,
            ),
          );
        },
      ),
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

### Example 11: Integration with Statistics Widget

```dart
class LabourStatisticsWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labourAsync = ref.watch(labourStreamProvider);
    final activeAsync = ref.watch(labourByStatusStreamProvider('active'));
    final onLeaveAsync = ref.watch(labourByStatusStreamProvider('onLeave'));

    return labourAsync.when(
      data: (allLabour) => activeAsync.when(
        data: (active) => onLeaveAsync.when(
          data: (onLeave) => Row(
            children: [
              StatCard(
                title: 'Total',
                value: allLabour.length.toString(),
              ),
              StatCard(
                title: 'Active',
                value: active.length.toString(),
              ),
              StatCard(
                title: 'On Leave',
                value: onLeave.length.toString(),
              ),
            ],
          ),
          loading: () => const CircularProgressIndicator(),
          error: (err, st) => const Text('Error'),
        ),
        loading: () => const CircularProgressIndicator(),
        error: (err, st) => const Text('Error'),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (err, st) => Text('Error: $err'),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;

  const StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(title),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Example 12: Filter Labour by Multiple Criteria

```dart
class FilteredLabourWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labourAsync = ref.watch(labourStreamProvider);
    final filterStatus = useState('all');
    final filterSite = useState('all');

    return labourAsync.when(
      data: (labourList) {
        var filtered = labourList;

        if (filterStatus.value != 'all') {
          filtered = filtered.where(
            (l) => l.status.name == filterStatus.value,
          ).toList();
        }

        if (filterSite.value != 'all') {
          filtered = filtered.where(
            (l) => l.assignedSiteId == filterSite.value,
          ).toList();
        }

        return Column(
          children: [
            DropdownButton<String>(
              value: filterStatus.value,
              items: ['all', 'active', 'inactive', 'onLeave']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => filterStatus.value = v!,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(filtered[index].fullName),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

## Common Patterns

### Pattern 1: Reactive Form Validation

```dart
// Form automatically validates as user types
// Use the LabourForm widget which handles all validation
```

### Pattern 2: Real-time Data Sync

```dart
// Stream providers automatically update UI when Firestore changes
final labourAsync = ref.watch(labourStreamProvider);
// No manual refresh needed!
```

### Pattern 3: Automatic Cache Invalidation

```dart
// When creating labour, list automatically refreshes
await ref.read(createLabourProvider(...).future);
// labourStreamProvider is automatically invalidated
```

### Pattern 4: Error Handling

```dart
// All providers have .when() for error handling
result.when(
  data: (data) => ...,
  loading: () => ...,
  error: (err, stack) => ...,
);
```

## Performance Tips

1. **Use .family providers for specific items** instead of filtering
2. **Watch only what you need** - don't watch all labour if you only need one
3. **Use StreamProvider for real-time data** - automatically syncs
4. **Avoid unnecessary rebuilds** - use Consumer widget correctly
5. **Cache site list** - load once and reuse for dropdowns

## Debugging Tips

1. **Check Firestore console** for data structure
2. **Enable Riverpod logging** for provider debugging
3. **Use DevTools** to inspect provider state
4. **Check Firebase rules** if get permission denied
5. **Verify companyId** matches current user UID
