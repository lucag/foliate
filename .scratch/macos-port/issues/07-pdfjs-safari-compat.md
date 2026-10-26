# Grilling: How pdf.js copes with older Safari on macOS 14

Type: grilling
Status: resolved
Map: ../map.md

## Question

The vendored pdf.js 5.5.207 calls `Map.prototype.getOrInsertComputed`, which WebKit gained only in Safari 26.2 (Dec 2025). Safari 26.2 installs on macOS 14, but a Mac on an older Safari will fail to open PDFs. Which fix does the port take: (a) ship pdf.js's legacy build on macOS, which includes the polyfill; (b) add our own polyfill in the Renderer page; or (c) require Safari 26.2+ and check for it at launch? Is the answer the same for Linux, whose WebKitGTK version decides this too? Should the missing WASM decoders (JPEG 2000, ICC colour, JBIG2) be handled at the same time?

## Context

See the Answer in `02-native-shell-options.md` and branch `research/native-shell-options`.

## Answer

**The macOS app requires Safari 26.2 or later.** A script injected by the Shell checks for `Map.prototype.getOrInsertComputed` when the Reader page starts. If it's missing, it tells the user that PDFs need Safari 26.2+ and to update through Software Update (Safari 26 is a free update on macOS 14 and 15). No pdf.js patching, and Linux is untouched.

- **Why not a polyfill injected as a user script:** the vendored pdf.js 5.5.207 uses the method in both `pdf.mjs` (9 places) and `pdf.worker.mjs` (6 places), and `WKUserScript`s don't reach workers.
- **Fallback if this proves too strict:** ship pdf.js's `legacy/` build on macOS, copied into the bundle's `vendor/pdfjs/` by the Xcode build phase at the same pinned version.
- **Linux:** probably affected on WebKitGTK releases from before 2026. JSC gained the method behind a flag in Nov 2024 ([WebKit bug 282014](https://bugs.webkit.org/show_bug.cgi?id=282014)), and the flag was removed in Jan 2026 ([WebKit bug 306233](https://bugs.webkit.org/show_bug.cgi?id=306233)). Unverified; ruled out of scope (see the map).
- **WASM decoders** (JPEG 2000, ICC colour, JBIG2): ruled out of scope, flagged as the next effort.
