# Grilling: Choose the porting approach

Type: grilling
Status: resolved
Blocked by: 01, 02, 03
Map: ../map.md

## Question

Given the research on the GTK stack, the native Shell options and the Shell–Renderer contract, which approach does the port take: (a) port the GTK Shell, (b) GTK Shell with WKWebView, or (c) a new macOS Shell, and if (c), Swift or Tauri? What are the decisive reasons, and what is the first milestone?

## Answer

**(c): a new native macOS Shell in Swift**, under `macos/`. It's SwiftUI first (`NavigationSplitView` library, a `Settings` scene, `commands` menus), with AppKit where needed: the WKWebView wrapper, possibly selection popovers and window/tab behaviour. Recorded as ADR `docs/adr/0001-native-swift-shell-for-macos.md`.

- **Ruled out:**
  - (a) Porting the GTK Shell: WebKitGTK 6.0 has no macOS build, and we'd have to maintain it ourselves without GPU acceleration. Homebrew is also dropping Intel.
  - (b) GTK Shell with WKWebView: all of (a)'s GTK costs plus custom bindings, and GTK overlays can't draw above the web view.
  - Tauri: the user wants a native Mac feel, not a web-based Shell UI.
- **Deciding factors:** native feel; the Reader page and lazy book loading carry over unchanged; the user's own maintenance. Upstream acceptance is only a nice-to-have.
- **Reader page:** `src/reader/` stays shared and unchanged. macOS differences, such as fonts set as CSS, come in through injected `WKUserScript`s or a small bridge file.
- **Build:** an Xcode project checked in under `macos/`, with a build phase that copies `src/foliate-js` and `src/reader` into the bundle. It produces one universal (arm64 + x86_64) app, ad-hoc signed. Meson and Linux are untouched.
- **First milestone: a reader-only app.** It opens an EPUB or PDF through File › Open or from Finder, renders it through the Reader page over a `foliate:` scheme handler, has JS↔Swift messaging working, and saves progress and annotations in the Linux JSON format. No library, TTS or OPDS. It also settles the open WKWebView questions.
