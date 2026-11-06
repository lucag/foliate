# Highlights

Status: ready-for-human
Blocked by: 05
Spec: ../spec.md

## What to build

- The selection popover on the `selection` message: **Highlight** (yellow only) and **Copy** (to `NSPasteboard`).
- Edit › Copy ⌘C and Highlight Selection ⇧⌘H.
- A highlight is saved to the book's `annotations` in Linux's format (CFI, colour, text, created/modified dates; see `src/annotations.js`) and drawn again on reopen.
- No other colours, no styles, no list of highlights.

## Done when

- [ ] XCTest: an annotation written by the Shell matches one written by Linux for the same selection, field for field.
- [ ] Highlight in an EPUB and a PDF, close, reopen: the highlights are there.
- [ ] **Round trip (user):** a highlight made on Linux shows on the Mac, and one made on the Mac shows on Linux, after copying the data folder each way.
