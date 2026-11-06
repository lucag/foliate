# Grilling: Slice the library milestone into build tickets

Type: grilling
Status: open
Map: ../map.md

## Question

The library is the second milestone (`13-library-and-file-access.md`). Break it into ordered, independently buildable vertical slices with their own definition of done, in a build effort of its own like `../macos-reader-milestone/spec.md` (see `10-slice-reader-milestone.md`). The window is the Answer in `17-design-library-window.md`. Settle:
- what the library depends on from the reader-only milestone (slice 05 already writes `uri-store.json` and the bookmark side file) and which of its slices must land first;
- the order and parallelism of the slices: reading every per-book JSON and cover into the grid, Home's sections, sidebar sections and counts, sort and search, resolving locations (bookmark, then `uri-store`, then Not Found with Locate…), Remove, adding books through multi-select Open… and drops on the window or the Dock icon, the import toast with Undo, and the launch behaviour (Library at launch when no book is restored, Window › Library ⌘L, bringing an open book's window forward);
- how covers are read and cached from the shared data folder, and how the window stays current when another window or Linux changes the folder;
- the definition of done, including a round trip with Linux where books added on either machine appear on both.
