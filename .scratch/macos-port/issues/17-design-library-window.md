# Prototype: Design the Library window

Type: prototype
Status: resolved
Map: ../map.md

## Question

What does the Library window (`13-library-and-file-access.md`) look like and how does it behave? Settle, by reacting to rough variants in the style of `09-design-reader-window.md`:
- cover grid, list, or both with a switch, and what each item shows (cover, title, author, progress);
- sorting, search and filtering;
- the "Not found" state with Locate…, and the empty library;
- the Remove confirmation, and import feedback (the Linux "Imported %d books" toast);
- the toolbar and the menu items it adds (Window › Library ⌘L, File › Import…?);
- whether OPDS catalogs get a place in this window later (a sidebar like Linux's), without designing them now.

## Answer

**A sidebar window with no toolbar, Home on top, and search in the sidebar** (prototype variant E, which builds on A).

- **Layout:** the sidebar runs the full height and holds the window buttons. The content area also runs to the top of the window, with no toolbar or title bar. View › Show/Hide Sidebar ⌃⌘S.
- **Sidebar, top to bottom:**
  - a **Search Library** field;
  - **Home**;
  - **Library**: All Books, Reading, Unread, Finished, and Not Found (shown only when something is missing), each with a count;
  - **Catalogs**: a greyed "Add Catalog…" that reserves the place for OPDS, which is a later milestone and isn't designed here.
- **Home:** a large title, then **Continue Reading** (up to four books in progress, newest first, each with cover, progress bar, percentage, last-read date, where you are, and **Resume**), then **Recently Added**, then **All Books**. Home has no keyboard shortcut.
- **Library sections:** a large title with a count and a "Sorted by …" pop-up beside it: Last Read (default), Title, Author, Date Added, Progress. The same choices are in View › Sort By.
- **Grid only, no list view.** Each item shows the cover, title, author and a progress bar. Unread books show "New" and a NEW badge, finished books show "Finished" and a ✓ badge, and missing books show a red NOT FOUND badge, a greyed cover and "Not found — Locate…".
- **Search:** typing in the sidebar field shows a **Results** grid (by title and author) on the right, whichever section is selected. ⌘F focuses the field, and Esc clears it.
- **Not Found:** clicking a missing book opens a sheet: "“<title>” can’t be found", the last known path, and **Locate…** / Remove from Library… / Cancel. Locate checks the picked file against the book, as decided in `13-library-and-file-access.md`.
- **Remove:** context menu or ⌘⌫ opens the sheet "Remove “<title>” from the Library?", which says that reading progress, highlights and bookmarks will be permanently deleted and that the book file stays where it is. Buttons: **Remove** (destructive) / Cancel.
- **Adding books:** no separate Import command. Picking several files in **Open…** adds them, and so does dropping files on the window (the whole content area highlights as a drop target). A toast says "Imported %d books" with **Undo**.
- **Empty library:** "No Books Yet", the supported formats, the note that books stay where they are, and an **Open…** button. A search or section with no matches gets its own short empty state.
- **Opening a book:** a double-click or Enter opens it in its own reader window, or brings that window forward if it's already open. The Library window stays open.
- **Context menu:** Open, Show in Finder, Book Info (greyed), Remove from Library…. For a missing book: Locate…, Remove from Library….
- **Menu additions:**
  - File: Show in Finder ⇧⌘R and Locate….
  - Edit: Remove from Library… ⌘⌫ and Find… ⌘F.
  - View: Sort By ▸ and Show/Hide Sidebar ⌃⌘S.
  - Window: Library ⌘L.
- **Rejected:** a toolbar (A–D); no sidebar with a scope bar of filters (B); a table or list view (C, and the grid/list switch in every variant); D's Home as a separate layout, which instead becomes the Home section; search in a hover pill (F) or on a Search page of its own (G); File › Import Books….

Prototype: branch `prototype/library-window`, commit `ec77e75`, file `macos/prototype-library-window.html` (`?variant=E`). Home in the prototype shows only Continue Reading and Recently Added; the All Books part below them was decided afterwards.
