# Spec: macOS library milestone

The second milestone of the native Swift **Shell** for macOS. It adds the **Library**: a Library window listing every per-book data file in the shared data folder, finding each book's file where it is, and adding and removing books. Books stay where they are; nothing is copied.

Decided in the wayfinder map `.scratch/macos-port/map.md`, mainly:
- `.scratch/macos-port/issues/13-library-and-file-access.md`: books stay in place, `uri-store.json` plus the bookmark side file, Not Found and Locate…, adding and removing;
- `.scratch/macos-port/issues/17-design-library-window.md`: the window, sidebar, Home, sections, sort, search, sheets, menus and icons (prototype `macos/prototype-library-window.html?variant=E` on branch `prototype/library-window`);
- `.scratch/macos-port/issues/20-slice-library-milestone.md`: this slicing, and the calls on covers, Date Added, live updates, importing, Undo and launch;
- `.scratch/macos-reader-milestone/spec.md`: the reader milestone this builds on;
- `.scratch/macos-port/issues/18-preferences-on-macos.md` and `21-slice-dark-mode-pages.md`: the Settings window (slice 10).

## Standing rules

All the reader milestone's standing rules apply (Linux-inert shared changes, XcodeGen project, bundle, the `xcodegen -s macos/project.yml && xcodebuild build test` gate, XCTest for logic that isn't UI plus a manual checklist per slice, no XCUITest, each slice wires its own menu items). In addition:

- **Prerequisites:** reader slices 04 (Bridge), 05 (User data) and 10 (Document types and opening). Slice 10 (Settings window) also needs reader 07 (Appearance). Reader slices 06, 08, 09 and 11 aren't needed.
- **Shared format untouched:** the library reads Linux's per-book JSON, `library/uri-store.json` and the cover cache as they are. Anything macOS-only lives in side files under `library/` that Linux ignores: `bookmarks-macos.json` (from reader 05) and `added-macos.json` (id → date added, this milestone).
- **Library store:** one in-process store, shared by the Library window and reader windows, is the only reader and writer of library state. JSON files and covers load off the main thread.
- **Dates:** Last Read is the per-book JSON's modified time, as on Linux. Date Added comes from `added-macos.json`, written on import and on first open. A book first seen from Linux gets the date the Mac first saw it, or failing that the JSON file's creation time.
- **Covers:** they stay in the cache folder (`~/Library/Caches/com.github.johnfactotum.Foliate/<id>.png`, as in reader 05) and aren't shared. A book without a cover shows a placeholder (title and author on a tinted tile) until one is made.
- **Importer:** a hidden `WKWebView` that loads the Reader page and drives its existing `initImport` → `loadFile` → `reader.getCover`, as Linux's `importFiles` does (`src/book-viewer.js:448`). It writes metadata, location, cover and date added with reader 05's code. Files are imported one at a time. No shared code changes.
- **One file opens, several import:** Open… or a Dock drop with one file opens it (and so adds it). Several files are imported without opening. A drop on the Library window always imports.

## Slices

| # | Slice | Blocked by | Status |
| --- | --- | --- | --- |
| 01 | Library tracer | reader 04, 05, 10 | ready-for-agent |
| 02 | Home, sections and sort | 01 | ready-for-agent |
| 03 | Search | 01 | ready-for-agent |
| 04 | Locations and Not Found | 02 | ready-for-agent |
| 05 | Remove | 01 | ready-for-agent |
| 06 | Adding books | 05 | ready-for-agent |
| 07 | Missing covers | 04, 06 | ready-for-agent |
| 08 | Live updates | 01 | ready-for-agent |
| 09 | Acceptance | all others | ready-for-human |
| 10 | Settings window | reader 07 | ready-for-agent |

After 01, slices 02, 03, 05 and 08 can run in parallel. 10 needs only reader 07 and can run at any point; 09 waits on it.

## Done criteria and their owners

1. Every per-book JSON in the data folder appears in the grid with its cover or a placeholder, and Home, the sections and counts, sort and search behave as in `17`: 01, 02, 03 and 07.
2. A book moved in Finder is found through its bookmark. A deleted book shows Not Found, and Locate… accepts the right file and rejects a different book: 04.
3. Books are added through multi-select Open…, window drops and Dock drops, with the "Imported %d books" toast and Undo (06). Remove deletes the data and cover but never the book file (05).
4. The window stays current when a reader window or an outside copy changes the data folder: 08.
5. **Linux round trip:** books added on either machine appear on both, and their locations resolve when the home folder layout matches. Removing a book on one machine leaves the other consistent, and Linux ignores the macOS side files: 09.
6. **Launch:** book windows are restored, otherwise the Library window shows, and Window › Library ⌘L and a Dock click with no windows both bring it up (01). With 1,000 books the window appears in under 1 s (01).

7. **Settings:** the Settings window's controls apply live to open reader windows: 10.

09 re-runs all seven on the user's Intel Mac.
