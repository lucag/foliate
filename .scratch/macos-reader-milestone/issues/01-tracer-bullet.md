# Tracer bullet: one EPUB and one PDF, end to end

Status: ready-for-human
Blocked by: (none)
Spec: ../spec.md

## What to build

The thinnest end-to-end path through the risky parts, with code that's kept:
- `macos/project.yml`, `macos/README.md`, the `.gitignore` entry for the generated project, the `Foliate` and `FoliateTests` targets, and a universal build;
- an app with one window holding a `WKWebView`;
- a `WKURLSchemeHandler` for `foliate:` that serves the bundled `src/reader/` and `src/foliate-js/` at `foliate://app/…`, with correct MIME types, loading `foliate://app/reader/reader.html` under the page's own CSP (no shared code changes);
- just enough of the `viewer` message handler to see `ready`, `book-ready` and `book-error`;
- File › Open… ⌘O: an `NSOpenPanel` picks a file, the Shell calls the Reader page's `loadFile()` (`src/reader/reader.js:514`), and `WKUIDelegate`'s `runOpenPanelWith…` callback answers the hidden file input with that file;
- a check that the pdf.js worker loads over `foliate:`; if it doesn't, run on the main thread and log it;
- the skeleton menu bar from `09-design-reader-window.md`, with every item except Open, Close Window, Quit, Hide and About greyed out;
- a hard-coded theme.

Excluded: the rest of the bridge, user data, overlays, popovers and states.

## Report

Append a `## Report` to this ticket:
1. Does a scripted `.click()` on the file input reach the open-panel callback without a user gesture? If not, **02** runs.
2. Does the pdf.js worker load?
3. Timings on the user's Intel Mac: first page and page turn, for a ~300-page text PDF and a scanned PDF. If they miss < 2 s and < 300 ms, **03** runs.

## Done when

- [ ] `xcodegen && xcodebuild build test` passes. XCTest covers the scheme handler: paths, MIME types, 404 for missing files, and no escape out of the resource folder.
- [ ] An EPUB and a PDF both open from File › Open and render.
- [ ] No CSP violations in the Web Inspector console (`isInspectable = true` in debug builds).
- [ ] `lipo -archs` on the binary reports `x86_64 arm64`.
- [ ] The report above is written. The timings need the user's Intel Mac.
