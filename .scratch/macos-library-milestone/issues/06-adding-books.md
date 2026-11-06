# Adding books

Status: ready-for-agent
Blocked by: 05
Spec: ../spec.md

## What to build

- The **importer** (see the spec): a hidden `WKWebView` that loads the Reader page and drives `initImport` → `loadFile` → `reader.getCover`, as `importFiles` does (`src/book-viewer.js:448-490`). It writes metadata, location (`uri-store` plus bookmark), cover and date added with reader 05's code. Files are imported one at a time. No shared code changes.
- Entry points:
  - **File › Open…** with several files selected imports them; one file opens it.
  - Dropping several files on the Dock icon imports them; one file opens it (reader 10 unchanged).
  - Dropping files on the Library window always imports them, and the whole content area highlights as a drop target.
- The toast: "Imported %d books", or "Failed to import %d books", with **Undo** (plural forms as in `po/`). It stays about 5 s. Undo runs 05's deletion on the books this import **newly** added. Books that were already in the library are counted but left alone.

## Done when

- [ ] XCTest: an import of sample EPUB, PDF and CBZ files writes the expected JSON, cover, `uri-store` and bookmark entries, and date added. Undo removes only the new books.
- [ ] Checklist: multi-select Open…, one-file Open…, window drop with highlight, Dock drop with one and with several files, the toast, Undo, a failing file.
