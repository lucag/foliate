# States: loading, Safari too old, book error

Status: ready-for-agent
Blocked by: 04
Spec: ../spec.md

## What to build

From `.scratch/macos-port/issues/09-design-reader-window.md`:
- **Loading:** a spinner with "Opening “<title>”…" until `book-ready`.
- **Safari too old (PDF):** when the 26.2+ check (04) fails and the book is a PDF, show "This PDF needs a newer Safari", the explanation from `07-pdfjs-safari-compat.md`, and Open Software Update / Close.
- **Book error:** on `book-error`, "Foliate can’t open “<file>”" with the supported formats, and Show in Finder / Close.

## Done when

- [ ] XCTest: the window's state machine (loading → reading / error / Safari too old).
- [ ] Manual: a truncated EPUB shows the error; the Safari screen shows when the check is forced to fail in a debug build.
