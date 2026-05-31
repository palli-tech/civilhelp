Project Rules

Tech Stack
- Flutter
- Riverpod
- Repository pattern
- Material 3

Before creating anything

1. Search existing code.
2. Search docs/project_inventory.md.
3. Reuse existing widgets.
4. Reuse existing models.
5. Reuse existing providers.
6. Reuse existing repositories.

When implementing features

- Follow the existing architecture of the target module.
- Do not refactor completed modules unless explicitly requested.
- Extend existing implementations whenever possible.
- Prefer modification over creation.
- Keep route names stable.
- Reuse shared layouts and widgets.

Never

- Create duplicate screens
- Create duplicate models
- Create duplicate repositories
- Create duplicate providers
- Create duplicate routes
- Refactor completed modules
- Rename files without explicit request
- Modify unrelated modules

Output

- Return only changed files
- Explain why each file changed
- List searched files before creating new files