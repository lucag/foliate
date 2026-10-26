# Research: Native Shell options for macOS

Type: research
Status: resolved
Map: ../map.md

## Question

For a new macOS Shell around foliate-js, compare Swift (AppKit and/or SwiftUI) with WKWebView against Tauri (Rust, WKWebView on macOS). For each option: how the Renderer's ES modules and `reader.html` get loaded (custom URL scheme handlers such as `WKURLSchemeHandler`), how book files and blobs reach the Renderer, how JS↔native messaging works, whether pdf.js (workers, wasm, fonts, cmaps) works inside WKWebView, whether one app can target both chip types on macOS 14+, typical bundle size, and how much of the existing JS UI code could be reused. Option (b), the GTK Shell driving WKWebView, needs a feasibility note too. Electron is excluded.

## Context

Findings: branch `research/native-shell-options`, file `.scratch/macos-port/research/native-shell-options.md`.

## Answer

**Both options run the same WKWebView, so the choice comes down to host language and control.** On macOS, Tauri's webview layer (wry) creates a WKWebView and registers custom protocols through the same `WKURLSchemeHandler` API a Swift Shell would use. Module loading, workers and pdf.js behave the same in both.

- **Swift (AppKit/SwiftUI):** everything maps across directly: the scheme handler, `webkit.messageHandlers`, promise-based messaging both ways, and the file-chooser trick for loading books (the Renderer gets a disk-backed `File` it reads lazily). `src/reader/reader.js` and the OPDS and selection-tool pages can stay unchanged. The cost: the roughly 6,400 lines of GTK-bound Shell code and the `.ui` files get rewritten natively.
- **Tauri (Rust):** wry handles the file chooser itself and always shows a dialog, so book loading moves to Tauri's asset protocol. That supports range requests, but passing a URL to foliate-js loads the whole file into memory, so lazy reading needs a new wrapper. The reader page also needs a shim from `webkit.messageHandlers` to Tauri's `invoke`, plus CSP changes. The advantage: the Shell UI can be web code, building on foliate-js's own demo reader UI.
- **Both** can ship one universal app for macOS 14+, at an estimated 10–20 MB.
- **(b) GTK Shell driving WKWebView:** possible but not worth it. It carries all the GTK-on-macOS cost and adds a custom Objective-C library with GObject-Introspection bindings. GTK overlays such as the navbar can't draw above a WKWebView placed over the GTK window.
- **Blocker either way:** the vendored pdf.js 5.5.207 calls `Map.prototype.getOrInsertComputed`, which arrived in Safari 26.2 (Dec 2025). Macs with an older Safari can't open PDFs. Fixes: pdf.js's legacy build (it includes a polyfill), our own polyfill, or requiring Safari 26.2. Separately, foliate-js doesn't ship pdf.js's WASM decoders (JPEG 2000, ICC colour, JBIG2), on Linux too.
- **Unverified, needs a spike:** whether the pdf.js worker loads over a custom scheme (if not, pdf.js runs on the main thread, which is slower but works), and whether host-less `foliate:///…` URLs work with the page's security policy or need a host such as `foliate://app/…`.

The full findings are on branch `research/native-shell-options`, commit `438dd6c`.
