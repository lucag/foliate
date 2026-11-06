# Library tracer: the store, the window and All Books

Status: ready-for-agent
Blocked by: macos-reader-milestone 04, macos-reader-milestone 05, macos-reader-milestone 10
Spec: ../spec.md

## What to build

- The **library store**: lists every `*.json` in the data folder (as `listBooks` does, `src/library.js:105-114`). It reads each file's `metadata` and `progress` off the main thread and keeps the modified time (Last Read). It reads and writes `library/added-macos.json`. Reader windows report opens and progress to it. The first open of a book with no entry writes its date added.
- The **Library window** from `17` with no toolbar: a full-height sidebar holding the window buttons, with the Search field, Home and Catalogs present but inert (greyed) and only **All Books** live (`books.vertical`, with a count).
- The **cover grid**: cover (lazily loaded from the cache folder), title, author and progress bar, newest Last Read first. A book with no cover gets the placeholder tile.
- Double-click or Enter opens the book in its reader window, or brings that window forward (reader 10). Context menu: Open, Show in Finder (greyed until 04), Book Info (greyed), Remove from Library… (greyed until 05).
- The empty state: "No Books Yet", the supported formats, the note that books stay where they are, and an **Open…** button.
- **Window › Library ⌘L.** At launch, AppKit window restoration reopens book windows by id, resolving locations as reader 05 records them. The Library window shows when nothing was restored, and on a Dock click with no windows open. Closing the last window doesn't quit.

## Done when

- [ ] XCTest: the store lists sample JSONs (Linux-written ones included) with the right title, author, progress and Last Read order. It ignores files that aren't JSON and survives malformed ones. `added-macos.json` round-trips and fills in a missing date as the spec says.
- [ ] XCTest or a timed run: with 1,000 generated JSON files, the window appears in under 1 s.
- [ ] Checklist: grid, placeholder covers, empty state, ⌘L, opening and bringing forward, restoration at launch, Dock reopen, closing the last window.
