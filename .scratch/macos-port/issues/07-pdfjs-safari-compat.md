# Grilling: How pdf.js copes with older Safari on macOS 14

Type: grilling
Status: open
Map: ../map.md

## Question

The vendored pdf.js 5.5.207 calls `Map.prototype.getOrInsertComputed`, which WebKit gained only in Safari 26.2 (Dec 2025). Safari 26.2 installs on macOS 14, but a Mac on an older Safari will fail to open PDFs. Which fix does the port take: (a) ship pdf.js's legacy build on macOS, which includes the polyfill; (b) add our own polyfill in the Renderer page; or (c) require Safari 26.2+ and check for it at launch? Is the answer the same for Linux, whose WebKitGTK version decides this too? Should the missing WASM decoders (JPEG 2000, ICC colour, JBIG2) be handled at the same time?

## Context

See the Answer in `02-native-shell-options.md` and branch `research/native-shell-options`.
