# Locations and Not Found

Status: ready-for-agent
Blocked by: 02
Spec: ../spec.md

## What to build

- The **resolver**, as decided in `13`:
  1. Resolve the bookmark in `bookmarks-macos.json`. If it's stale, refresh it and rewrite the `uri-store.json` entry.
  2. Otherwise try the `uri-store.json` path (`~/…` expanded against the Mac's home, or a `file://` URI).
  3. Otherwise the book is **not found**.

  It's used when opening, restoring and building the grid (resolved off the main thread). No Spotlight search.
- **Not Found** in the sidebar (`exclamationmark.triangle`, with a count, shown only when something is missing). In the grid: a red NOT FOUND badge, a greyed cover, and "Not found — Locate…".
- Clicking a missing book opens the sheet "“<title>” can’t be found", with the last known path and **Locate…** / Remove from Library… / Cancel. The context menu for a missing book has Locate… and Remove from Library….
- **Locate…** (also **File › Locate…**): an open panel. The picked file is accepted only if its identifier, or its `foliate:<md5>` id, matches the book. Then both stores are updated. A different book is refused with an explanation.
- **File › Show in Finder ⇧⌘R** and the context-menu item, for books that are found.

## Done when

- [ ] XCTest: resolver order, the stale-bookmark refresh rewriting `uri-store`, `~/` expansion, and Locate's identity check (right file, different book, a book without an identifier).
- [ ] Checklist: move a book in Finder and it still opens. Delete it and it shows Not Found. Locate it again. Show in Finder.
