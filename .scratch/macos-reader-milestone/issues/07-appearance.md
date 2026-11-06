# Appearance

Status: ready-for-agent
Blocked by: 06
Spec: ../spec.md

## What to build

The Aa popover and View menu from `09-design-reader-window.md`:
- Auto/Light/Dark (Auto follows the system appearance live);
- text size A−/A+ in steps 14, 16, 18, 20, 22, 26, 30 pt, with View › Bigger ⌘+, Smaller ⌘−, Actual Size ⌘0;
- One/Two pages, with View › Single Page ⌥⌘1 / Two Pages ⌥⌘2;
- the nine Linux themes (Default, Gray, Sepia, Grass, Cherry, Sky, Solarized, Gruvbox, Nord) in light and dark, with colours taken from `src/themes.js`, and View › Theme ▸;
- View › Appearance… ⌘T opens the popover.

Everything goes through `reader.setAppearance`. The settings are kept for the next launch in `UserDefaults` for now; how preferences are stored is still undecided on the map, so keep this behind one small type.

## Done when

- [ ] XCTest: theme table matches `src/themes.js`; size stepping stops at the ends.
- [ ] Manual checklist: each control in an EPUB; PDFs keep their page colours (recolouring isn't in this milestone).

## Comments

- From [Grilling: Preferences on macOS](../../macos-port/issues/18-preferences-on-macos.md): preferences stay in `UserDefaults`, now decided rather than a stopgap, with keys named after the GSettings paths (`viewer.view.theme`). A−/A+ and ⌘+/⌘− set the **Book text size**, remembered per book in a `UserDefaults` dictionary keyed by book identifier. A book without one opens at the **Default text size** (`viewer.font.default-size`, default 16), and ⌘0 clears it. Font defaults are `ui-serif`, `ui-sans-serif` and `ui-monospace`. Add to Done: XCTest that a book's size survives a relaunch and that ⌘0 falls back to the default.
