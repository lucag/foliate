# Settings window

Status: ready-for-agent
Blocked by: macos-reader-milestone 07
Spec: ../spec.md

## What to build

Foliate › Settings… ⌘, as decided in [Grilling: Preferences on macOS](../../macos-port/issues/18-preferences-on-macos.md): a standard macOS Settings window with tabs in its toolbar, based on Linux's View Preferences (`src/ui/view-preferences-window.ui`). Every control goes through the preferences type from reader 07, and changes apply live to open reader windows.
- **Text:** Default text size, Minimum text size, Default font (Serif/Sans-serif), Override Publisher Font, and Serif, Sans-Serif and Monospace font pickers (family only).
- **Layout:** Line Height, Full Justification, Hyphenation, Margins, Maximum Number of Columns, Maximum Inline Size, Maximum Block Size, and Scrolled vs Paginated.
- **Appearance:** Auto/Light/Dark, Theme (custom themes after the nine built-in ones), Brightness, the dark-mode image controls (see Comments), and Show Custom Themes Folder in Finder.

There is no Behavior tab. It doesn't depend on the library itself. It was missed when the library milestone was sliced and added by [Grilling: Slice dark-mode pages into build work](../../macos-port/issues/21-slice-dark-mode-pages.md).

## Done when

- [ ] XCTest: each control writes its GSettings-named key.
- [ ] Checklist: each control changes an open EPUB live; Show Custom Themes Folder opens the config folder.

## Comments

- From [the dark-mode build effort](../../macos-dark-mode/spec.md): `viewer.view.invert` is dropped on macOS. If dark-mode slice 01 has landed, the Appearance tab shows the three app-wide **Dark-mode image settings** (Images in Dark Mode: Original / Smart / Invert; photo dimming 100/85/80%; Recolour Charts) instead of "Invert in dark mode". If not, it shows the old toggle, and dark-mode slice 06 swaps it.
