# Spec: macOS reader-only milestone

The first build of the native Swift **Shell** for macOS (ADR `docs/adr/0001-native-swift-shell-for-macos.md`). It opens a book in its own window, renders it with the shared **Reader page** and **Renderer**, and saves progress and yellow highlights in the same files Linux uses. There's no library, TTS, OPDS, search, bookmarks or translations yet.

Decided in the wayfinder map `.scratch/macos-port/map.md`, mainly:
- `.scratch/macos-port/issues/08-spec-reader-only-milestone.md`: scope, data locations, app identity, done criteria;
- `.scratch/macos-port/issues/09-design-reader-window.md`: the window, overlays, popovers, menus and states (it replaces 08's "Interface" bullet);
- `.scratch/macos-port/issues/10-slice-reader-milestone.md`: this slicing;
- `.scratch/macos-port/issues/07-pdfjs-safari-compat.md`: the Safari 26.2+ check;
- `.scratch/macos-port/issues/03-shell-renderer-contract.md`: the contract the Shell reproduces.

## Standing rules

- **Linux-inert:** changes to `src/reader/` or `src/foliate-js/` are additive only, and Linux behaviour doesn't change. Run the Linux app after any shared change.
- **Project:** XcodeGen. `macos/project.yml` is committed and the generated `macos/Foliate.xcodeproj` is gitignored. Sources go in `macos/Foliate/` (SwiftUI first, AppKit where needed), unit tests in `macos/FoliateTests/`, and build steps plus the minimum XcodeGen version in `macos/README.md`.
- **Bundle:** `src/reader` and `src/foliate-js` are folder resources (`type: folder`) copied into `Contents/Resources/`. Nothing is duplicated in git. macOS 14.0, bundle ID `io.github.lucag.Foliate`, universal `arm64 x86_64` from the first slice on, and `Info.plist` generated from `project.yml`.
- **Gate:** every slice ends with `xcodegen -s macos/project.yml && xcodebuild build test` passing.
- **Checks:** XCTest for logic that isn't UI, and a manual checklist in each ticket for what is visual. No XCUITest in this milestone.
- **Menus:** each slice wires its own menu items and shortcuts from `09`. Unwired items stay greyed out.

## Slices

| # | Slice | Blocked by | Status |
| --- | --- | --- | --- |
| 01 | Tracer bullet | (none) | ready-for-human |
| 02 | `openURL` fallback *(only if 01's report needs it)* | 01 | needs-info |
| 03 | PDF performance *(only if 01 misses the targets)* | 01 | needs-info |
| 04 | Bridge | 01 (and 02 if it runs) | ready-for-agent |
| 05 | User data and progress | 04 | ready-for-human |
| 06 | Reader overlays and navigation | 04 | ready-for-agent |
| 07 | Appearance | 06 | ready-for-agent |
| 08 | Highlights | 05 | ready-for-human |
| 09 | States | 04 | ready-for-agent |
| 10 | Document types and opening | 04 | ready-for-agent |
| 11 | Acceptance | all others | ready-for-human |

05, 06, 09 and 10 can run in parallel once 04 is done. 03 doesn't block anything.

## Done criteria and their owners

1. All five formats open and render: EPUB and PDF in 01, MOBI/AZW, FB2 and CBZ in 10.
2. Progress is restored on reopen: 05.
3. Highlights are created and saved: 08.
4. A round trip with Linux keeps progress (05) and highlights (08) intact in both directions.
5. PDF speed targets are met (page turn < 300 ms once loaded, first page < 2 s, on the user's Intel Mac with a ~300-page text PDF and a scanned PDF): measured in 01, fixed in 03 if needed.
6. The universal build is verified with `lipo` and runs on Intel: 11.

11 re-runs all six.
