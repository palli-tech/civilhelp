# TODO - Worker Ledger PDF export (Flutter Web + Unicode)

## Plan steps
- [x] Step 1: Update `PdfService` to generate PDF bytes once.

- [x] Step 2: Add `previewWorkerLedgerPdf(...)` and platform-aware behavior using `kIsWeb`.

- [ ] Step 3: On Flutter Web, remove `Printing.layoutPdf` usage and implement bytes-based browser preview + download.

- [ ] Step 4: On mobile/desktop, keep `Printing.layoutPdf` preview/print flow.
- [ ] Step 5: Add Unicode-capable fonts (Noto Sans regular + bold) and apply globally in PDF widgets.
- [x] Step 6: Refactor `WorkerLedgerScreen` to call `previewWorkerLedgerPdf`.

- [ ] Step 7: Add user-friendly error handling (generation/preview/download/font loading).
- [ ] Step 8: Validate currency and negative rendering.
- [ ] Step 9: Manual testing checklist for web/android/iOS/desktop.

