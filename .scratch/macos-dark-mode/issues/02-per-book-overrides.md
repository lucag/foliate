# Per-book overrides

Status: ready-for-agent
Blocked by: 01
Spec: ../spec.md

## What to build

Swift only. The **Dark-mode image settings** follow the **Book text size** model (`.scratch/macos-port/issues/18-preferences-on-macos.md`):
- Changing Images in Dark Mode, photo dimming or Recolour Charts from the Aa popover or the View menu stores an override for that book only, in a `UserDefaults` dictionary keyed by the book identifier that names its JSON in the data folder. Each setting is overridden separately.
- A book without an override follows the app-wide value, and changing the app-wide value (Settings, library slice 10) moves every such book, live in open windows.
- **View › Images in Dark Mode ▸ Use Default** clears the book's overrides. It is greyed out when the book has none.
- The per-book JSON is unchanged.

## Done when

- [ ] XCTest: an override survives a relaunch; the other settings still follow the app-wide values; changing an app-wide value moves only books without an override; Use Default falls back.
- [ ] Checklist: two open books with different settings; Use Default from the menu.
