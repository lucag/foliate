# Bridge: messages, RPC and injected scripts

Status: ready-for-agent
Blocked by: 01, 02 (if it runs)
Spec: ../spec.md

## What to build

Reproduce the Linux contract (`.scratch/macos-port/issues/03-shell-renderer-contract.md`; the Linux side is in `src/webview.js` and `src/book-viewer.js`):
- the `viewer` message handler, decoding all 14 message types into a typed Swift enum (unhandled ones are logged);
- the token/promise RPC for Shell→JS calls (`evaluateJavaScript` on the global paths, results returned by token), as a Swift `async` API;
- `showSelection` as a request/response call;
- injected `WKUserScript`s: `init({uiText})` with English strings keyed as `src/book-viewer.js:26-43` builds them; `reader.setAppearance({layout, style, autohideCursor})` with defaults; fonts as CSS; and the Safari 26.2+ check from `07-pdfjs-safari-compat.md` (reporting only; its screen is in 09).

## Done when

- [ ] XCTest: message decoding for every type, including malformed JSON; RPC token bookkeeping (resolve, reject, a late reply after the window closes).
- [ ] Opening a book logs `relocate` as pages turn, and calling `next()`/`prev()` through the RPC turns pages.
