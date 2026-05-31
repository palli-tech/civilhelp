# Recommendations

## Focus areas for next feature implementation

1. Dashboard navigation consolidation
   - The app router already exposes `attendance`, `payments`, and `advances` routes.
   - A natural next feature is to wire the dashboard or drawer actions to these modules with a consistent task flow.

2. Stabilize placeholder modules before adding new screens
   - `expenses`, `invoices`, `reports`, and `settings` currently contain placeholder `index.dart` files only.
   - If these modules are intended to be part of the product roadmap, define minimal feature contracts first to avoid dead code.

3. Reuse shared layout components across newly added screens
   - `AppScaffold`, `AppDrawer`, and `BottomNav` are already available for consistent page structure.
   - New screens should leverage these shared components instead of creating independent page shells.

4. Maintain module boundaries and avoid duplicate implementations
   - Each feature module currently has one provider and one repository class, which is a good pattern.
   - Keep next work scoped to the existing provider/repository structure rather than adding parallel versions.

5. Audit cross-module data models before extending integrations
   - The existing models are concise and feature-scoped.
   - If integrating attendance, payments, and advances further, prefer extending the current model classes instead of creating duplicate DTOs.

## Suggested cleanup observations

- `expenses`, `invoices`, `reports`, and `settings` may be candidates for future removal or eventual implementation.
- Any further feature addition should avoid introducing new top-level `index.dart` placeholders unless they provide exports or feature wiring.

## Safe next steps

- Implement the next actual user workflow in one of the existing feature areas: attendance, payments, or advances.
- Use existing shared widgets and layouts for the new screen UI.
- Keep route names stable and add only the required screens/providers/repositories for the chosen flow.
