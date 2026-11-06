# User data and progress

Status: ready-for-human
Blocked by: 04
Spec: ../spec.md

## What to build

- The data folder: `$XDG_DATA_HOME/com.github.johnfactotum.Foliate/` when `XDG_DATA_HOME` is set, otherwise `~/Library/Application Support/com.github.johnfactotum.Foliate/`. Covers go in `~/Library/Caches/com.github.johnfactotum.Foliate/`.
- Reading and writing the per-book file `<encodeURIComponent(id)>.json` with Linux's keys (`metadata`, `progress`, `lastLocation`, `annotations`, `bookmarks`). The id is the book's identifier, or `foliate:<md5 of the first 10,000,000 bytes>` when it has none, exactly as `makeIdentifier` computes it (`src/book-viewer.js:434-445`). Keys the Shell doesn't know are kept on write.
- Saving `progress` and `lastLocation` on every `relocate` (`src/book-viewer.js:855-866`; coalesce the writes), and passing `lastLocation` to `view.init` on reopen (`src/data.js:28-29`).
- The cover image saved on first open.
- On every open, record the book's location as the library decision says (`.scratch/macos-port/issues/13-library-and-file-access.md`): in `library/uri-store.json` in Linux's format (`~/…` under home, otherwise a `file://` URI, as `saveURI` does at `src/data.js:95-100`), and as `NSURL` bookmark data in the macOS-only `library/bookmarks-macos.json`. Open Recent (10) uses AppKit's own recents.

## Done when

- [ ] XCTest: `uri-store.json` entries match Linux's format for paths inside and outside home; the bookmark side file round-trips.
- [ ] XCTest: path selection with and without `XDG_DATA_HOME`; id and file-name encoding matching Linux for sample books (compare with the Linux code's output); round-trip read/write keeping unknown keys; atomic writes.
- [ ] Close and reopen a book: it returns to the same place.
- [ ] **Round trip (user):** read a book on Linux, copy the data folder to the Mac, and progress is restored; read further on the Mac, copy back, and Linux restores the new place.
