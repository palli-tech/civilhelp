# SiteCard Type Trace

## Trace path

1. `lib/features/sites/screens/sites_screen.dart`
   - `SitesScreen.build()` watches `sitesStreamProvider`.
   - In `sitesAsync.when(data: (sites) { ... })`, `sites` is the resolved list.
   - The `ListView.builder` creates a `SiteCard` for each element:
     ```dart
     final site = sites[index];
     return SiteCard(
       site: site,
       onTap: () { ... },
       onDelete: () { ... },
     );
     ```

2. `lib/features/sites/widgets/site_card.dart`
   - `SiteCard` constructor declares:
     ```dart
     final dynamic site;
     ```
   - The `site` parameter is received as `dynamic`.

3. `lib/features/sites/providers/site_provider.dart`
   - `sitesStreamProvider` is declared as:
     ```dart
     final sitesStreamProvider = StreamProvider<List<SiteModel>>((ref) { ... });
     ```
   - Therefore the stream yields `List<SiteModel>`.

4. `lib/features/sites/models/site_model.dart`
   - `SiteModel` is a concrete model class with a `SiteStatus status` field.
   - The `SiteCard` UI code expects properties such as `site.name`, `site.location`, `site.startDate`, and `site.status.name`.

## Identified answers

1. `SiteCard` parameter type
   - Declared as `dynamic site` in `SiteCard`.

2. Actual runtime object type
   - At runtime, the `site` passed from `SitesScreen` is an instance of `SiteModel`.
   - The provider chain confirms `sitesStreamProvider` returns `List<SiteModel>`, and `sites[index]` is therefore `SiteModel`.

3. Why `site` is declared as `dynamic`
   - The widget author chose a loose type for the constructor parameter, which bypasses static type checking.
   - This allows any runtime object with the expected fields to be passed, but also hides compile-time guarantees and can cause runtime errors if the actual object shape differs.

4. Whether `SiteCard` always receives `SiteModel`
   - In the current codebase, yes: `SiteCard` is only constructed from `SitesScreen`, and that screen passes elements from `List<SiteModel>`.
   - There are no other `SiteCard` usages in the workspace.

## Summary

- `SiteCard.site` is declared as `dynamic`, but the actual object is a `SiteModel` at runtime.
- The runtime type comes from `sitesStreamProvider`, which produces the `SiteModel` list.
- The dynamic declaration means `SiteCard` does not enforce this contract statically.
- The current code path always passes `SiteModel`, so the runtime error is likely due to a mismatch between the Dart enum API expected by `site.status.name` and the runtime environment, not because `site` is a different object type.
