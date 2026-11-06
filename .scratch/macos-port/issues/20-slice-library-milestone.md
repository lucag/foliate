# Grilling: Slice the library milestone into build tickets

Type: grilling
Status: resolved
Map: ../map.md

## Question

The library is the second milestone (`13-library-and-file-access.md`). Break it into ordered, independently buildable vertical slices with their own definition of done, in a build effort of its own like `../macos-reader-milestone/spec.md` (see `10-slice-reader-milestone.md`). The window is the Answer in `17-design-library-window.md`. Settle:
- what the library depends on from the reader-only milestone (slice 05 already writes `uri-store.json` and the bookmark side file) and which of its slices must land first;
- the order and parallelism of the slices: reading every per-book JSON and cover into the grid, Home's sections, sidebar sections and counts, sort and search, resolving locations (bookmark, then `uri-store`, then Not Found with Locate…), Remove, adding books through multi-select Open… and drops on the window or the Dock icon, the import toast with Undo, and the launch behaviour (Library at launch when no book is restored, Window › Library ⌘L, bringing an open book's window forward);
- how covers are read and cached from the shared data folder, and how the window stays current when another window or Linux changes the folder;
- the definition of done, including a round trip with Linux where books added on either machine appear on both.

## Comments

- From [Grilling: Preferences on macOS](18-preferences-on-macos.md): the Settings window (tabs Text, Layout, Appearance; changes apply live) is a slice of this milestone. Its contents and the config-folder rule for `user-stylesheet.css` and `themes/*.json` are in that ticket's Answer.

## Answer

**Nine slices in a separate build effort, [`.scratch/macos-library-milestone/`](../../macos-library-milestone/spec.md)** (its `spec.md` plus `issues/01-09`), in the format of the reader milestone.

- **Prerequisites:** reader slices 04 (Bridge), 05 (User data) and 10 (Document types) only. The library can be built while reader 06–09 and 11 are still in progress.
- **Order:** 01 Library tracer (store, window, All Books grid, ⌘L, launch and restoration) first. Then 02 Home, sections and sort; 03 Search; 05 Remove; and 08 Live updates in parallel. 04 Locations and Not Found follows 02, 06 Adding books follows 05, 07 Missing covers follows 04 and 06, and 09 Acceptance comes last.
- **Calls made:**
  - **Importer:** a hidden `WKWebView` drives the Reader page's existing `initImport` → `loadFile` → `reader.getCover`, as Linux does. No shared code changes and no native metadata parser.
  - **Covers** stay in the cache folder and aren't shared. A book without one gets a placeholder tile, and a background pass makes covers for books that are found.
  - **Dates:** Last Read is the JSON file's modified time, as on Linux. Date Added lives in a new macOS-only side file `library/added-macos.json`, written on import and first open. A book first seen from Linux gets the date the Mac first saw it.
  - **Live updates:** one in-process library store shared by all windows, plus FSEvents on the data folder, coalesced at about 0.5 s, ignoring its own writes.
  - **One file opens, several import,** from Open… or the Dock. A drop on the Library window always imports. This clarifies `13`'s Dock line, and reader 10 is unchanged.
  - **Undo** on the import toast removes only the books this import newly added, through Remove's deletion code.
  - **Launch:** the library effort owns window restoration. The Library window shows when nothing was restored and on a Dock click with no windows. Closing the last window doesn't quit.
  - **Size target:** with 1,000 books the window appears in under 1 s.
- **Done criteria:** listing and browsing (01–03, 07), finding moved and missing books (04), adding and removing (05, 06), live updates (08), the Linux round trip (09), and launch plus the size target (01). 09 re-runs all six on the Intel Mac.
- **Labels:** `ready-for-agent` for 01–08. `ready-for-human` for 09 (Linux machine and Intel Mac).
- **Glossary:** **Library** added: every book with a per-book data file in the data folder, found or not.
