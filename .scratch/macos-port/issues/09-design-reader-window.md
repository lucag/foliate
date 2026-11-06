# Prototype: Design the reader window

Type: prototype
Status: resolved
Map: ../map.md

## Question

What exactly does the reader-only app's window look like and do? Make a rough mock-up of the minimal interface decided in `08-spec-reader-only-milestone.md` for the user to react to: the toolbar (back/next, table-of-contents popover), the appearance menu (which themes, font size steps), the selection popover (Highlight with which colours, Copy), the menu bar items and keyboard shortcuts for these, and how the window looks while loading a book or showing an error such as the Safari 26.2 prompt. Settle what is in and out of the first milestone.

## Answer

**An immersive window with no toolbar, and its controls in hover overlays** (prototype variant D, building on C).

- **Top overlay:** fades in when the pointer is over the page. It has the window buttons, the book title in the middle, and a right-aligned **pill**: ☰ Table of Contents (popover) | Aa Appearance (popover) | Search and Bookmark, both greyed out until a later milestone.
- **Bottom overlay:** the progress slider and page count only, with no ‹ › buttons. Pages turn with ←/→/Space, the trackpad, or clicks on the page edges.
- Both overlays stay visible while a popover is open. Esc or a click on the page closes it.
- **Appearance popover:** Auto/Light/Dark; text size A−/A+ in steps 14, 16, 18, 20, 22, 26, 30 pt; One/Two pages; the nine Linux themes (Default, Gray, Sepia, Grass, Cherry, Sky, Solarized, Gruvbox, Nord), each in light and dark.
- **Selection popover:** Highlight (**yellow only**) and Copy.
- **Menu bar:**
  - **Foliate:** About, Settings… (greyed), Hide, Quit ⌘Q.
  - **File:** Open… ⌘O, Open Recent, Close Window ⌘W, Book Info (greyed).
  - **Edit:** Copy ⌘C, Highlight Selection ⇧⌘H, Find… (greyed).
  - **View:** Table of Contents ⌃⌘T, Appearance… ⌘T, Bigger ⌘+, Smaller ⌘−, Actual Size ⌘0, Theme ▸, **Single Page ⌥⌘1 / Two Pages ⌥⌘2**, Enter Full Screen ⌃⌘F.
  - **Go:** Next/Previous Page →/←, Next/Previous Chapter ⌥→/⌥←, Back ⌘[, Forward ⌘].
  - **Window:** Minimize ⌘M, Zoom, Bring All to Front.
  - **Help:** Foliate Help.
- **States:**
  - **Loading:** a spinner with "Opening “<title>”…".
  - **Safari too old (PDF):** "This PDF needs a newer Safari", an explanation, and Open Software Update / Close.
  - **Book error:** "Foliate can’t open “<file>”" with the supported formats, and Show in Finder / Close.
- **Rejected:** a toolbar (A); a sidebar with an inspector (B); a pinnable sidebar (an earlier D); ‹ › in the bottom bar.
- **Not in the first milestone:** other highlight colours and styles (underline, squiggly, strikethrough), search, bookmarks, and any list of highlights.

Prototype: branch `prototype/reader-window`, commit `fa7ef86`, file `macos/prototype-reader-window.html` (`?variant=D`).
