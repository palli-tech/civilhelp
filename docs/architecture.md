# Architecture

Pattern:
UI -> Provider -> Repository -> Data Source

State:
Riverpod

Navigation:
Go Router

Folder Structure:
feature/
 ├── screens/
 ├── widgets/
 ├── providers/
 ├── repositories/
 └── models/

Repositories return domain models.

Providers expose:
- loading
- error
- data