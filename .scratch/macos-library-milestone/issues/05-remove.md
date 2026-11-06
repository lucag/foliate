# Remove

Status: ready-for-agent
Blocked by: 01
Spec: ../spec.md

## What to build

- The shared **deletion** code in the store: for a set of ids, delete the per-book JSON and the cached cover, and remove the entries in `uri-store.json`, `bookmarks-macos.json` and `added-macos.json` (Linux's `delete`, `src/library.js:175-181`, plus the side files). Never the book file. If the book is open, its reader window closes first.
- **Edit › Remove from Library… ⌘⌫** and the context-menu item, for one or more selected books. The sheet: "Remove “<title>” from the Library?", which says that reading progress, highlights and bookmarks will be permanently deleted and that the book file stays where it is. Buttons: **Remove** (destructive) / Cancel. The sheet shows the app icon.

## Done when

- [ ] XCTest: deletion removes exactly those files and entries and leaves the book file and other books alone.
- [ ] Checklist: the sheet from the menu, the shortcut and the context menu; removing an open book; multiple selection.
