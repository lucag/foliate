# `openURL` fallback for book loading

Status: needs-info
Blocked by: 01
Condition: run only if 01's report says a scripted `.click()` on the file input doesn't reach the open panel. Otherwise close it as `wontfix`.
Spec: ../spec.md

## What to build

- An additive `globalThis.openURL(url)` in `src/reader/reader.js` that fetches the book through a lazy, range-reading Blob-like object instead of the file input. Linux never calls it.
- A `foliate://book/<token>` route in the scheme handler. The Shell maps a random token to the opened file and serves byte ranges (`Range` requests, `206`), so large books are never read whole.
- `loadFile()` replaced by `openURL` on macOS only.

## Done when

- [ ] XCTest: tokens resolve only to files the Shell opened; range responses are correct, including the end of the file and bad ranges.
- [ ] The same EPUB and PDF as 01 open through the new path, and a 300 MB PDF opens without memory spiking to its size.
- [ ] Linux opens books exactly as before (manual check).
