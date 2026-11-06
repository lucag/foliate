# Reader overlays and navigation

Status: ready-for-agent
Blocked by: 04
Spec: ../spec.md

## What to build

From `.scratch/macos-port/issues/09-design-reader-window.md`:
- The immersive window: no toolbar, content under the title bar.
- The top overlay, fading in on hover: window buttons, book title, and the pill with ☰ Contents (popover with the book's table of contents, jumping on click), Aa (a placeholder until 07), and Search and Bookmark greyed out.
- The bottom overlay: progress slider and page count (from `relocate`), dragging to seek.
- Overlays stay visible while a popover is open. Esc or a click on the page closes the popover.
- Page turns with ←/→/Space, the trackpad and clicks on the page edges.
- Menus: **Go** (Next/Previous Page, Next/Previous Chapter ⌥→/⌥←, Back ⌘[, Forward ⌘], using `history-index-change`), View › Table of Contents ⌃⌘T, Enter Full Screen ⌃⌘F.

## Done when

- [ ] XCTest for the view models: TOC tree from the Renderer's data, slider ↔ fraction mapping, Back/Forward availability.
- [ ] Manual checklist: every item above, in an EPUB and a PDF, including full screen.
