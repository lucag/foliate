# Grilling: Slice the reader-only milestone into build tickets

Type: grilling
Status: resolved
Map: ../map.md

## Question

The destination needs work slices ready to build. Break the reader-only milestone (the Answer in `08-spec-reader-only-milestone.md`, with its interface replaced by the Answer in `09-design-reader-window.md`) into ordered, independently buildable vertical slices, each with its own definition of done. Settle:
- what the tracer bullet slice includes and excludes, and what happens if its fallback (`globalThis.openURL`) is needed;
- the order of the slices after it (bridge, user data and progress, overlays and popovers, highlights, menu bar, states, document types and Open Recent, universal build), and which of them can run in parallel;
- where the Xcode project and Swift sources live under `macos/` and how the Reader page and foliate-js get into the app bundle (copied at build time, or referenced in place);
- how each slice is checked (manual checklist, XCTest, a round trip with Linux), and which slice owns each of the milestone's six done criteria;
- the format of the build tickets: which tracker, and whether they are `ready-for-agent` or `ready-for-human`.

## Answer

**Eleven slices in a separate build effort, `.scratch/macos-reader-milestone/`** (its `spec.md` plus `issues/01-11`). The tracer bullet comes first, and two conditional slices run only if its report calls for them.

- **Order:** 01 Tracer bullet → (02 `openURL` fallback, only if a scripted `.click()` is blocked) → 04 Bridge. Then 05 User data, 06 Reader overlays, 09 States and 10 Document types run in parallel. 07 Appearance follows 06, 08 Highlights follows 05, and 11 Acceptance comes last. 03 PDF performance runs only if 01 misses the targets, and nothing waits on it.
- **Tracer bullet:** window, `foliate://app/` scheme and CSP, File › Open for one EPUB and one PDF through the open-panel trick, the worker check, the PDF timings, and a skeleton menu bar with unwired items greyed out. Its code is kept. It ends in a written report that decides 02 and 03. The fallback touches only `src/reader/`, so it doesn't wait on the foliate-js decision.
- **Menus:** each slice wires its own items and shortcuts. There's no menu slice.
- **Done criteria owners:**
  1. Formats: 01 (EPUB, PDF) and 10 (MOBI, FB2, CBZ).
  2. Progress: 05.
  3. Highlights: 08.
  4. Linux round trip: 05 and 08.
  5. PDF speed: 01, with 03 if needed.
  6. `lipo` and Intel: 11.

  11 re-runs all six. The build is universal from 01 on.
- **Project:**
  - XcodeGen, with `macos/project.yml` committed and the generated `macos/Foliate.xcodeproj` gitignored.
  - Sources in `macos/Foliate/`, tests in `macos/FoliateTests/`, build steps and the minimum XcodeGen version in `macos/README.md`.
  - `src/reader` and `src/foliate-js` are copied in as folder resources.
  - `Info.plist` is generated, including the document types.
- **Checks:**
  - XCTest for logic that isn't UI.
  - A manual checklist per slice.
  - `xcodegen && xcodebuild build test` as the gate.
  - No XCUITest in this milestone.
- **Labels:**
  - `ready-for-agent`: 04, 06, 07, 09 and 10.
  - `ready-for-human`, because they need the user's eyes, Intel Mac or Linux machine: 01 (timings), 05 and 08 (round trips) and 11.
  - `needs-info` until 01's report: 02 and 03.
- **Calls made while writing the slices (open to revision):**
  - 05 leaves `library/uri-store.json` alone, and Open Recent uses AppKit's recents, until `13-library-and-file-access.md` decides the library.
  - 07 keeps appearance settings in `UserDefaults` behind one small type, until preferences are decided.

## Comments

The first call above (05 leaves `library/uri-store.json` alone) is reversed by `13-library-and-file-access.md`: 05 now writes `uri-store.json` and the bookmark side file on every open.
