# Grilling: Library and file access on macOS

Type: grilling
Status: resolved
Map: ../map.md

## Question

How does the macOS app find, add and remember books after the reader-only milestone? Settle:
- how the Linux library (`src/library.js`, `src/data.js`) finds books today and what it stores about a book's location, since the data folder is shared with Linux (`08-spec-reader-only-milestone.md`);
- whether books stay where they are or are copied into the library, and how a moved or renamed file is found again (plain paths, or bookmark data; the app is unsigned and not sandboxed);
- how a book's location is shared with Linux when the data folder moves between machines;
- what the library window shows and how it fits with one window per book (`09-design-reader-window.md`); this may need a prototype ticket.

## Answer

**Same library as Linux, with bookmark data added to find moved files.** Books stay where they are, and the library is every per-book JSON in the shared data folder, so books read on either machine show up on both.

- **How Linux does it** (for reference):
  - The library lists every per-book JSON in the data folder, newest first (`src/library.js:143-146`).
  - `saveURI` (`src/data.js:95-100`) records each opened book in `library/uri-store.json`, as `~/…` under home or a `file://` URI otherwise.
  - Tracker search by identifier finds moved files (`src/library.js:116-131`).
  - Multi-select in Open imports without opening (`src/app.js:185-191`).
- **Locations:** the app writes `library/uri-store.json` in Linux's exact format, so `~/Books/x.epub` resolves on both machines when the layout matches. A macOS-only side file, `library/bookmarks-macos.json`, maps each book id to `NSURL` bookmark data and takes Tracker's place. Linux ignores it.
- **Finding a book:**
  1. Resolve the bookmark. If it's stale, refresh it and rewrite `uri-store`.
  2. Try the `uri-store` path.
  3. Show "Not found" with **Locate…**: the picked file is checked against the entry's identifier or md5 id, then both stores are updated.

  No Spotlight search.
- **Contents and removal:** as on Linux. Entries from Linux that can't be found show as "Not found". Remove deletes the JSON and cover, never the book file, after a confirmation that says progress and highlights go with it.
- **Adding books:** multi-select in Open… imports without opening, and so does dropping files on the Library window or the Dock icon. No watched folders.
- **Window:** a separate **Library window**, shown at launch when no book is being restored, and from Window › Library ⌘L. Book windows stay one per book, and opening a book that's already open brings its window forward. The look is left to `17-design-library-window.md`.
- **Milestone:** the library is the second milestone, with its own build effort once the prototype is done.
- **Change to the reader-only milestone:** slice 05 (User data) now writes `uri-store.json` and the bookmark side file on every open. This reverses the call recorded in `10-slice-reader-milestone.md`.

## Comments

"Dropping files on the Dock icon imports" is clarified by `20-slice-library-milestone.md`: one file dropped on the Dock (or picked in Open…) opens the book, several are imported, and a drop on the Library window always imports.
