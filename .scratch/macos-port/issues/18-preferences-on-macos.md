# Grilling: Preferences on macOS

Type: grilling
Status: resolved
Map: ../map.md

## Question

Linux keeps preferences in GSettings (dconf), not in files (`03-shell-renderer-contract.md`), so they can't move between machines the way the data folder does. What replaces it on macOS? Settle:
- which GSettings keys the macOS app needs, and which it drops (read the schema under `data/`);
- where they live: `UserDefaults` (the stopgap in the reader-only milestone's slice 07), or a file, and whether any should follow the data folder between machines;
- the per-language voice choice from `15-tts-in-swift-shell.md`, and the appearance settings;
- the Settings window (Foliate › Settings…, greyed in `09-design-reader-window.md`): what it holds and when it ships;
- how this connects with the user stylesheet and themes under `$XDG_CONFIG_HOME` on Linux.

## Answer

- **Keys kept:** the macOS app keeps these GSettings keys with the same meanings as on Linux:
  - `color-scheme`;
  - `viewer.highlight-color`, which stays yellow in the reader milestone and is kept for when more colours come;
  - from `viewer.view`: `line-height`, `justify`, `hyphenate`, `gap` (margins), `max-inline-size`, `max-block-size`, `max-column-count` (which One/Two pages sets), `scrolled`, `invert`, `theme`, `brightness` and `override-font`;
  - all of `viewer.font`: `serif`, `sans-serif`, `monospace`, `default`, `default-size` and `minimum-size`. The font defaults become `ui-serif`, `ui-sans-serif` and `ui-monospace`, because WebKit on macOS doesn't resolve the fontconfig names `'Serif'` and `'Sans'`.
- **Keys dropped:**
  - `window.*`: macOS frame autosave and state restoration remember window size and full screen.
  - `library.*` (`view-mode`, `show-covers`, `cover-size`): the Library window is grid only (`17-design-library-window.md`).
  - `viewer.fold-sidebar`: the reader window has no sidebar.
  - `viewer.view.autohide-cursor`: the overlays already hide when the pointer is still.
  - `viewer.view.animated`: the system's Reduce Motion setting takes its place.
  - `viewer.translate-target-language` is left for the dictionary/lookup fog.
- **Storage:** `UserDefaults` under `io.github.lucag.Foliate`, with keys named after the GSettings paths (for example `viewer.view.line-height`). Preferences stay on the machine, as dconf does on Linux, and don't move with the data folder. A shared `settings.json` would have changed the Linux Shell and carried voice IDs and installed fonts that only make sense on one machine. The "one small type" from the reader milestone's appearance slice becomes the only way in to every preference.
- **Voice per language:** one dictionary maps a language tag to a voice identifier. Lookup uses the book's primary subtag (`en`), and the full tag (`en-GB`) wins when the book has one and it is stored. If no voice is stored, or the stored voice is no longer installed, the app uses System Voice and leaves the entry alone. Speed and pitch are global.
- **Text size, per book:**
  - **Default text size** (`viewer.font.default-size`) is global and is set in Settings.
  - **Book text size** is set with A−/A+ and ⌘+/⌘− (14–30 pt) and is remembered per book. It is a `UserDefaults` dictionary keyed by the book identifier that names its JSON in the data folder.
  - A book with no stored size opens at the Default text size. Actual Size ⌘0 clears the book's stored size.
  - Changing the Default text size moves every book that has no stored size of its own.
  - The per-book JSON format is unchanged.
  - The reason: EPUBs set default font sizes of their own that vary from book to book, so a single global size doesn't work. On Linux, A−/A+ change the WebView zoom without saving it (`src/book-viewer.js:352`) and `default-size` is global. A follow-up for Linux is noted under Out of scope on the map.
- **Everything else is global**, as on Linux. A book's JSON never holds appearance settings.
- **User stylesheet and custom themes:** the app reads `user-stylesheet.css` and `themes/*.json` in the Linux formats (`src/book-viewer.js:45`, `src/themes.js:54`):
  - They are read at launch, from `$XDG_CONFIG_HOME/foliate/` when that is set and from `~/Library/Application Support/io.github.lucag.Foliate/` otherwise, the same rule as the data folder.
  - Custom themes are listed after the nine built-in themes, in the Aa popover and in View › Theme ▸.
  - There is no editor in the app. A Linux config folder copied over works unchanged.
- **Settings window** (Foliate › Settings… ⌘,): a standard macOS Settings window with tabs in its toolbar, based on Linux's View Preferences (`src/ui/view-preferences-window.ui`):
  - **Text:** Default text size, Minimum text size, Default font (Serif/Sans-serif), Override Publisher Font, and Serif, Sans-Serif and Monospace font pickers (family only).
  - **Layout:** Line Height, Full Justification, Hyphenation, Margins, Maximum Number of Columns, Maximum Inline Size, Maximum Block Size, and Scrolled vs Paginated.
  - **Appearance:** Auto/Light/Dark, Theme, Invert in dark mode, Brightness, and Show Custom Themes Folder in Finder, which opens the folder that holds the user stylesheet too.
  - There is no Behavior tab. Voices stay in the Read Aloud popover (`15-tts-in-swift-shell.md`).
  - Changes apply live to open reader windows, as GSettings bindings do on Linux.
- **When it ships:** the reader milestone keeps Settings… greyed. The Settings window is a slice of the library milestone (`20-slice-library-milestone.md`). Book text size goes into the reader milestone's appearance slice (`../macos-reader-milestone/issues/07-appearance.md`), which already builds A−/A+.
