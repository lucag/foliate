# Research: The Shell–Renderer contract today

Type: research
Status: resolved
Map: ../map.md

## Question

What does the GJS Shell provide to the Renderer today, so that any macOS Shell knows what it must reproduce? Inventory from `src/` (notably `webview.js`, `book-viewer.js`, `reader/`, `data.js`, `generate-gresource.js`): URL schemes and resource loading, JS↔Shell message types in both directions, injected scripts and styles (themes, fonts), the settings passed in, and the on-disk user-data format and location (progress, annotations, bookmarks, library). Which Shell features are pure JS that could run inside the web view, and which are GTK/GIO-bound?

## Context

Findings: branch `research/shell-renderer-contract`, file `.scratch/macos-port/research/shell-renderer-contract.md`.

## Answer

The contract is small and runs through one page, `foliate:///reader/reader.html`, where `src/reader/reader.js` (557 lines) wraps foliate-js's `<foliate-view>`.

- **Messaging:** JS→Shell goes through `webkit.messageHandlers.<name>.postMessage` with a JSON string. There are 14 `viewer` message types (`ready`, `book-ready`, `book-error`, `relocate`, `selection`, `show-image`, `history-index-change`, …) and one request/response call, `showSelection`. Shell→JS uses `evaluate_javascript` on about 40 global paths, wrapped in a token/promise RPC. Nearly all of them pass straight through to the foliate-js View API.
- **Settings:** UI strings go in via `init({uiText})`, and everything else via one `reader.setAppearance({layout, style, autohideCursor})` call. Fonts are the only WebKitGTK-specific part (`WebKit.Settings`), so a macOS Shell would inject them as CSS.
- **Book loading:** a hidden `<input type=file>`, answered by the `run-file-chooser` signal. foliate-js then serves the book's contents as `blob:` URLs. Three custom schemes (`foliate:`, `foliate-opds:`, `foliate-selection-tool:`) serve the app's own bundled files.
- **Already pure JS:** parsing, rendering, CFI, search, footnotes, themes, print, TTS SSML generation and media overlays. **Must be rebuilt natively:** the chrome, file I/O, GSettings, covers (GdkPixbuf), the clipboard, speech-dispatcher TTS, downloads, file dialogs and the Tracker lookup.
- **User data:** one JSON file per book at `$XDG_DATA_HOME/com.github.johnfactotum.Foliate/<encodeURIComponent(id)>.json`, with keys `metadata`, `progress`, `lastLocation`, `annotations`, `bookmarks`. The id is the book's own identifier, or `foliate:<md5 of first 10 MB>` if it has none. The library index is `library/uri-store.json`, catalogs are in `catalogs/catalogs.json`, covers are PNGs under `$XDG_CACHE_HOME`, and themes and the user stylesheet are under `$XDG_CONFIG_HOME`. Preferences live in GSettings (dconf), not in files.

The full findings are on branch `research/shell-renderer-contract`, commit `27ca1d5`.
