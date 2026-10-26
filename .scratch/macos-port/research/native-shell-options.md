# Research: Native Shell options for macOS

Ticket: `../issues/02-native-shell-options.md`. Researched 2026-10-25.

Question: for a new macOS **Shell** around the **Renderer** (foliate-js), compare Swift (AppKit/SwiftUI) + WKWebView against Tauri (Rust, WKWebView on macOS), and add a feasibility note on option (b), the GTK Shell driving WKWebView. Electron is excluded.

Note on sources: the `src/foliate-js` submodule is not checked out in this worktree. Renderer files were read from a sibling checkout (`/Users/lucag/src/foliate/src/foliate-js`, pdfjs-dist **5.5.207** vendored). Paths below are given relative to the repo.

## TL;DR

- **Both options work, and both run on the same engine.** Tauri on macOS *is* WKWebView: wry calls the same `setURLSchemeHandler` and `WKUIDelegate` APIs a Swift Shell would ([wry `src/wkwebview/mod.rs`][wry-mod], [tauri `Builder` docs][tauri-builder]). WebKit-level behaviour (pdf.js, workers, module loading) is the same in both, so the choice comes down to the host language, the IPC style, and how much control we keep over WKWebView.
- **Swift is the closer fit to today's Shell.** Its WKWebView API maps almost one-to-one onto what `src/webview.js` does with WebKitGTK: custom scheme handler, `webkit.messageHandlers`, evaluate JS, and the file-chooser trick that feeds book files to the Renderer. `src/reader/reader.js` can stay unchanged.
- **Tauri lets more of the Shell UI be web code**, so more existing JS can be reused. But wry owns the WKWebView delegates. The file-chooser trick doesn't carry over, so books have to be fetched over a custom protocol, and IPC needs a small shim.
- **Blocker for PDF, whichever Shell we pick:** the vendored pdf.js 5.5.207 *modern* build calls `Map.prototype.getOrInsertComputed` without a fallback. WebKit only gained that in **Safari 26.2** (Dec 2025). On macOS 14 the WKWebView engine updates with Safari, so PDFs break on any Mac whose Safari is older than 26.2. Fix: ship pdf.js's **legacy** build on macOS (it polyfills this), or add a polyfill, or require Safari ≥ 26.2. Details in [pdf.js](#pdfjs-inside-wkwebview-both-options).
- **Option (b) is technically possible but the worst trade-off.** It needs everything ticket 01 needs (GTK on macOS) plus a native ObjC shim, an NSView overlaid on a GTK window, and a rewrite of `webview.js`.

## How the Shell talks to the Renderer today (baseline to reproduce)

From `src/webview.js` and `src/book-viewer.js`:

- **Loading:** `WebKit.WebContext.register_uri_scheme` serves the `foliate:`, `foliate-opds:` and `foliate-selection-tool:` schemes from GResource/disk, with a per-scheme path allow-list and a MIME type guessed from the extension (`src/webview.js:6-29`). The reader loads `foliate:///reader/reader.html` (`src/book-viewer.js:346`). It imports ES modules from `../foliate-js/` (`src/reader/reader.js:1-3`) under a strict CSP (`script-src 'self'`, `src/reader/reader.html:4`).
- **Book delivery:** the Shell never sends book bytes over IPC. It calls `loadFile()` in the page, which clicks a hidden `<input type=file>` (`src/reader/reader.js:514`). The Shell then answers WebKit's `run-file-chooser` signal with the book's path (`src/book-viewer.js:182-183`, and again for import at `:459`). The Renderer ends up with a real, disk-backed `File`, which `makeBook` reads lazily with `slice()`. PDF uses `PDFDataRangeTransport` plus `file.slice` (`src/foliate-js/pdf.js:115-127`).
- **JS → Shell:** `globalThis.webkit.messageHandlers.viewer.postMessage(...)` (`src/reader/reader.js:8`). The OPDS page uses `.opds` (`src/opds/main.js:4`), and `translate.html` uses `.settings`.
- **Shell → JS:** `evaluate_javascript`, plus a token/promise round-trip layer (`exec`, `iter`, `provide`) built on a per-view message handler (`src/webview.js:31-170`).

## Option (c1): Swift (AppKit and/or SwiftUI) + WKWebView

**SwiftUI caveat for macOS 14.** SwiftUI's native `WebView`/`WebPage` and the Swift `URLSchemeHandler` protocol only exist on **macOS 26+** ([WebPage][apple-webpage], [WebView][apple-webview], [URLSchemeHandler][apple-urlschemehandler-swift]). With a macOS 14 target, the reader view has to be a `WKWebView` (AppKit) wrapped in `NSViewRepresentable` if the rest of the app is SwiftUI. That works fine; it is just AppKit underneath.

**Loading reader.html and ES modules.** `WKURLSchemeHandler` exists since macOS 10.13 and is registered with `WKWebViewConfiguration.setURLSchemeHandler(_:forURLScheme:)` ([WKURLSchemeHandler][apple-wkurlschemehandler], [setURLSchemeHandler][apple-seturlschemehandler]). Rules from Apple's docs: you cannot register schemes WebKit already handles (e.g. `https`; check with `WKWebView.handlesURLScheme(_:)`), you can register each scheme only once, and you should prefix the scheme name with the app's name. `foliate:` already follows that rule. WebKit's own API tests confirm the details the Renderer needs:
- `import()` and `modulepreload` from a custom scheme load through the handler and send an `Origin` header (`TEST(URLSchemeHandler, ModulePreload)`)
- custom-scheme pages are `isSecureContext == true`
- sync and async XHR work
- `Range` requests are passed to the handler, which must answer them itself (`TEST(URLSchemeHandler, Ranges)`)

All of these are in [WebKit `WKURLSchemeHandler-1.mm`][wk-tests]. A Swift handler is the direct counterpart of `registerPaths` in `src/webview.js`: read from `Bundle.main.resourceURL`, set the MIME type (JS must be `application/javascript` for modules), and keep the path allow-list.
- *Recommendation:* use a URL with a host, e.g. `foliate://app/reader/reader.html`, not `foliate:///…`. WebKit derives the origin from scheme + host; every WebKit test uses a host, and Tauri always uses `<scheme>://localhost`. `'self'` in the CSP depends on the origin. This is unverified for the empty-host form, so check it in the first spike.
- `loadFileURL(_:allowingReadAccessTo:)` is the other option ([docs][apple-loadfileurl]), but `file:` origins make module imports and the CSP harder. The scheme handler is the better choice.

**Book files and blobs.** The current trick ports directly, and this is the decisive point:
- `WKUIDelegate.webView(_:runOpenPanelWith:initiatedByFrame:completionHandler:)` (macOS 10.12+) lets the Shell answer a file-input request with any `[URL]`. If the delegate doesn't implement it, file uploads are **disabled** on macOS ([docs][apple-runopenpanel]).
- Public `evaluateJavaScript` and `callAsyncJavaScript` run with `forceUserGesture:YES` ([WKWebView.mm lines 1303-1315][wk-wkwebview-mm]). So the Shell-initiated `input.click()` in `loadFile()` counts as user-activated, as it does in WebKitGTK.
- Result: `reader.js` keeps getting a lazy, disk-backed `File`, with no copy over IPC.

Fallbacks:
- serve the book over the scheme handler and pass `makeBook` a URL string. This works today, but `fetchFile` buffers the whole file into memory (`src/foliate-js/view.js:72-80`).
- a ranged custom-scheme response.

**JS ↔ native messaging.**
- *JS → native:* `WKUserContentController.add(_:name:)` exposes `window.webkit.messageHandlers.<name>.postMessage`. That is the same API WebKitGTK exposes, so `emit` in `reader.js` and `opds/main.js` works unchanged.
- *Request/response from JS:* `WKScriptMessageHandlerWithReply` (macOS 11+) makes `postMessage` return a Promise answered by a `replyHandler` ([docs][apple-reply]). That replaces the token dance in `provide()`.
- *Native → JS:* `callAsyncJavaScript(_:arguments:in:in:)` (macOS 11+) takes typed arguments and **awaits a returned thenable** ([docs][apple-callasync]). That replaces `exec()`'s token/PromiseStore round-trip, and `iter()` becomes a loop of `callAsyncJavaScript("return await it.next()")`.
- *Debugging:* `isInspectable` (macOS 13.3+) enables Safari Web Inspector ([docs][apple-inspectable]).

**Both chip types, macOS 14+.** Yes. Xcode builds one universal (`arm64` + `x86_64`) binary; it needs Xcode 12.2+ and every compiled component must be universal ([Apple: Building a universal macOS binary][apple-universal]). Set the deployment target to 14.0.

**Bundle size.** There is no first-party figure. By construction: the Swift runtime and WebKit ship with the OS, so the app is the Swift binary (typically a few MB universal) plus resources. The Renderer is the bulk: `src/foliate-js` is 13 MB on disk, 7.3 MB of which is pdf.js source maps that need not ship, leaving about 5.5 MB. So expect roughly **10–20 MB** uncompressed. This is an estimate, not a measurement.

**JS reuse.** Unchanged: `src/foliate-js` (all of it), `src/reader/*`, `src/opds/*`, `src/selection-tools/*`, `src/common/*`. They already talk to the Shell only through `webkit.messageHandlers` and JS globals.

Must be rewritten in Swift: everything in the GJS Shell, because every top-level `src/*.js` imports `gi://Gtk`/`Adw`/`Gio`. That covers the library, sidebar/TOC, annotations, bookmarks, navbar, search UI, TTS, themes, `data.js` storage and `format.js`, about 6,400 lines of GJS plus about 2,800 lines of `.ui` XML. The user-data JSON format must be re-implemented exactly, to keep the cross-machine compatibility the map requires.

## Option (c2): Tauri (Rust, WKWebView on macOS)

**Engine.** Tauri renders through wry, which on macOS creates a `WKWebView` subclass (`WryWebView`). wry installs its own navigation and UI delegates and its own `ipc` message handler ([wry `src/wkwebview/mod.rs`][wry-mod]). Tauri apps don't bundle a browser engine; "a minimal Tauri app can be less than 600KB" ([Tauri: What is Tauri][tauri-start]).

**Loading reader.html and ES modules.**
- Option 1: put the Renderer in `frontendDist`, which embeds all files in the binary ([config reference][tauri-config]).
- Option 2: register a protocol with `Builder::register_uri_scheme_protocol` or `register_asynchronous_uri_scheme_protocol`. On macOS these call `setURLSchemeHandler`, and URLs take the form `<scheme>://localhost/<path>` on macOS and Linux. On Windows and Android they become `http://<scheme>.localhost/<path>` ([tauri `Builder`][tauri-builder]).

Either way the same WebKit behaviour as in Swift applies. Option 2 maps best onto the current `foliate:`, `foliate-opds:` and `foliate-selection-tool:` split.

**Book files and blobs.** Here Tauri is clearly weaker:
- wry implements `runOpenPanelWithParameters` itself, and it always runs a modal `NSOpenPanel` ([wry `wry_web_view_ui_delegate.rs`][wry-ui]). There is no hook to answer with a path chosen by the Shell, so the `run-file-chooser` trick is lost.
- `with_webview` gives `unsafe` access to the raw WKWebView ([tauri `Webview`][tauri-webview]). Swapping its `uiDelegate` would fight wry, and it's fragile across wry versions.

Realistic paths:
- **Asset protocol.** `convertFileSrc(path)` with `app.security.assetProtocol.enable` and a `scope`; it is off by default with an empty scope ([JS core API][tauri-core], [config][tauri-config]). Tauri's asset handler supports HTTP `Range`/206 ([tauri `protocol/asset.rs`][tauri-asset]). A URL string passed to `makeBook` is fully buffered by `fetchFile`, though, so lazy reading needs a small Shell-side `Blob`-like wrapper that fetches ranges. That would be new Renderer-side code; zip.js's `BlobReader` and `pdf.js`'s `file.slice` expect Blob semantics, so it needs a spike.
- **IPC bytes.** A command returning `tauri::ipc::Response` (raw bytes) or a `Channel<ArrayBuffer>` stream ([Calling Rust][tauri-calling-rust], [JS core API][tauri-core]). This always copies the whole file into the page.

**JS ↔ native messaging.**
- *JS → Rust:* `invoke(cmd, args)` returns a Promise, with JSON-serialised arguments and results ([Calling Rust][tauri-calling-rust], [IPC concept][tauri-ipc]). On macOS, Tauri's IPC script sends each call as `fetch` POST to the `ipc:` custom protocol, falling back to `postMessage` ([tauri `scripts/ipc-protocol.js`][tauri-ipc-js]).
- *Rust → JS:* events (JSON, fire-and-forget), channels (ordered, fast, binary-capable), and `Webview::eval` (returns `Result<()>`, no value) ([Calling the frontend][tauri-calling-frontend], [tauri `Webview`][tauri-webview]). Async results need a token round-trip like today's `exec()`.

Consequences for the existing JS:
- `reader.js`'s `webkit.messageHandlers.viewer` needs a shim mapping it onto `invoke`/events. `window.webkit` does exist in wry's WKWebView, but registering extra handler names requires `with_webview`.
- `reader.html`'s CSP (`connect-src 'self' blob: data:`) would block `ipc://localhost` and `asset://localhost` until we add them.

**Both chip types, macOS 14+.** Yes. `tauri build --target universal-apple-darwin` needs both the `aarch64-apple-darwin` and `x86_64-apple-darwin` Rust targets ([CLI reference][tauri-cli]). `bundle.macOS.minimumSystemVersion` defaults to 10.13 and can be set to 14.0 ([config][tauri-config], [macOS bundle][tauri-bundle]).

**Bundle size.** Tauri's own figure is under 600 KB for a minimal app ([Tauri: What is Tauri][tauri-start]). A real Foliate would be a universal Rust binary (likely a few MB) plus the same ~5.5 MB of Renderer assets, so the same order of magnitude as Swift (estimate).

**JS reuse.** Same Renderer reuse as Swift. The difference is that the Shell UI itself can also be HTML/JS: library grid, TOC, annotations list, search and settings. That opens up reuse of:
- foliate-js's own demo reader UI (`src/foliate-js/reader.html`, `reader.js`, `ui/tree.js`, `ui/menu.js`)
- the pure-logic parts of the GJS Shell after removing GIO, e.g. progress/annotation JSON handling in `data.js`, and `format.js`, which mostly wraps `Intl`

GTK widgets and `.ui` files are not reusable in either option. Native macOS menus and file dialogs remain available through Tauri APIs, but a web UI will look less native than AppKit.

## pdf.js inside WKWebView (both options)

The same WebKit runs both options, so this section applies to both.

- **BLOCKER: JS built-ins.** The vendored `vendor/pdfjs/pdf.mjs` / `pdf.worker.mjs` are pdfjs-dist **5.5.207 modern** builds (`rollup.config.js` copies `build/`, not `legacy/build/`). They call `Map.prototype.getOrInsertComputed` unguarded (e.g. `pdf.mjs` lines 7103, 13976, 14877; `pdf.worker.mjs` 1714). They also call `Uint8Array.prototype.toHex` (document fingerprints, `pdf.worker.mjs` 59575), `Uint8Array.fromBase64` and `URL.parse`. Only `Math.sumPrecise` is polyfilled. Browser support:
  - `getOrInsert`/`getOrInsertComputed`: Safari **26.2** ([MDN browser-compat-data][bcd-map]; [Safari 26.2 release notes][safari-262]: "Added support for `Map.prototype.getOrInsert` … and related methods").
  - `toHex`/`fromBase64`: Safari 18.2 ([BCD][bcd-u8]).
  - `URL.parse`: Safari 18 ([BCD][bcd-url]).

  Safari 26.2 *is* available for macOS Sonoma and Sequoia ([release notes][safari-262]), and WKWebView uses that system WebKit. So a macOS 14 Mac whose Safari is older than 26.2 will fail to open PDFs. pdf.js's own FAQ lists only Firefox and Chrome for the modern build, and says "Safari 18+: Mostly" for the legacy build ([pdf.js FAQ][pdfjs-faq]). The pdfjs-dist 5.5.207 `legacy/build/pdf.worker.mjs` does polyfill `Map.prototype.getOrInsertComputed` (checked via unpkg). **Mitigation:** on macOS, vendor the legacy build, or polyfill before importing `pdf.mjs`, or set a hard runtime minimum of Safari 26.2. This also applies to WebKitGTK on Linux, depending on the distro's WebKitGTK version.
- **Worker.** `GlobalWorkerOptions.workerSrc` points at `vendor/pdfjs/pdf.worker.mjs` on the custom scheme (`src/foliate-js/pdf.js:5`), so the page and the worker are same-origin. pdf.js creates a module worker. If that fails, it falls back to a "fake worker" in the main thread (`pdf.mjs` 15291-15359). WebKit tests show module scripts load through `WKURLSchemeHandler`, but no first-party test of a *Worker* script over a custom scheme turned up. Treat this as a spike checkpoint; the fake-worker fallback means it is a performance risk, not a blocker.
- **cmaps and standard fonts.** `cMapUrl` and `standardFontDataUrl` point at the custom scheme (`src/foliate-js/pdf.js:124-125`). pdf.js only lets the *worker* fetch these for `http(s):` URLs (`isValidFetchUrl`, `pdf.mjs` 1459). For custom schemes it sets `useWorkerFetch = false` and fetches them on the main thread with `XMLHttpRequest`, accepting status 0 (`pdf.mjs` 1175-1200, 14462). Custom-scheme XHR is supported (WebKit `SyncXHR`/`XHRPost` tests), so this works the same way as on WebKitGTK.
- **WASM.** pdf.js 5.x loads `openjpeg.wasm` (JPEG 2000), `qcms_bg.wasm` (ICC colour) and `jbig2.wasm` from `wasmUrl` (`pdf.worker.mjs` 2803, 6456). foliate-js neither vendors pdfjs-dist's `wasm/` directory nor passes `wasmUrl`, so these decoders are already unavailable on Linux; pdf.js warns and falls back where it can. This is a Renderer gap, not a macOS one. If fixed, check that the CSP permits WebAssembly compilation (`'wasm-unsafe-eval'`).

## Option (b): keep the GTK Shell, drive WKWebView — feasibility note

Technically possible, poor trade-off:

1. **It still needs all of ticket 01.** GTK4, libadwaita and GJS have to be built and shipped on macOS; only WebKitGTK is dropped.
2. **Embedding.** GTK4 has no widget for hosting a foreign native view; GtkSocket/GtkPlug are gone. The macOS backend's only public hook is `gdk_macos_surface_get_native_window()` (GTK 4.8+), which returns the `NSWindow` ([gtk `gdk/macos/gdkmacossurface.h`][gtk-macos-surface]). A WKWebView would have to be added as an NSView subview of that window and kept in sync with a placeholder widget's allocation. GTK draws the whole window into one layer, so in-window GTK overlays such as Foliate's auto-hiding navbar and in-window popovers can't be drawn above the native view. Keyboard focus and input routing between GTK and AppKit would need manual work.
3. **Bindings.** GJS can't call Objective-C. It would need a custom C/ObjC library with GObject-Introspection typelibs wrapping `WKWebView`, the scheme handler, script message handlers, `evaluateJavaScript` and `runOpenPanel`, plus a rewrite of `src/webview.js` and the WebKit parts of `book-viewer.js`, `library.js`, `selection-tools.js` and `app.js` against it.

Net: more native glue than option (c) and a non-native UI, while keeping the full GTK-on-macOS build burden. Not recommended unless ticket 01 shows GTK on macOS is already cheap *and* WebKitGTK is the only thing that fails.

## Comparison

| | Swift + WKWebView | Tauri (wry/WKWebView) |
|---|---|---|
| Load reader.html + ES modules | `WKURLSchemeHandler`, full control (MIME, allow-list, ranges) | `register_*_uri_scheme_protocol` → same `WKURLSchemeHandler`; `scheme://localhost/...` |
| Book file → Renderer | Same trick as GTK: `runOpenPanel` delegate returns the path → lazy disk-backed `File`; zero copy | wry owns `runOpenPanel` (always shows dialog). Use asset/custom protocol with Range + new Blob-like wrapper, or copy bytes via IPC |
| JS → native | `webkit.messageHandlers` (unchanged `emit`), `WithReply` promises | `invoke`/events; shim needed for `webkit.messageHandlers.viewer`; CSP additions |
| native → JS | `callAsyncJavaScript` awaits promises with typed args | `eval` returns nothing; token round-trip or channels |
| pdf.js | Same WebKit; **needs legacy build/polyfill or Safari ≥ 26.2** | Same |
| Universal macOS 14+ | Xcode universal build, deployment target 14.0 | `--target universal-apple-darwin`, `minimumSystemVersion` 14.0 |
| Size (est.) | ~10–20 MB | ~10–20 MB (min. app <600 KB per Tauri) |
| JS reuse | Renderer + `src/reader`, `opds`, `selection-tools` as-is; Shell UI rewritten in Swift | Same + Shell UI can be web (reuse foliate-js demo UI and pure-logic bits); less native look |
| Native feel / OS APIs (TTS, menus) | Direct (AVSpeechSynthesizer, NSMenu) | Via Rust crates/plugins or `objc2` |

## Open items for a spike

- Module `Worker` over a custom scheme in WKWebView (pdf.js real worker vs. fake-worker fallback).
- Origin and CSP `'self'` behaviour of `foliate:///…` (empty host) vs. `foliate://app/…`.
- Which pdf.js build to ship on macOS: legacy, or modern plus polyfill.
- Tauri only: whether a lazy range-fetch Blob wrapper satisfies zip.js `BlobReader` and pdf.js's range transport.

## Sources

[apple-wkurlschemehandler]: https://developer.apple.com/documentation/webkit/wkurlschemehandler
[apple-seturlschemehandler]: https://developer.apple.com/documentation/webkit/wkwebviewconfiguration/seturlschemehandler(_:forurlscheme:)
[apple-runopenpanel]: https://developer.apple.com/documentation/webkit/wkuidelegate/webview(_:runopenpanelwith:initiatedbyframe:completionhandler:)
[apple-reply]: https://developer.apple.com/documentation/webkit/wkscriptmessagehandlerwithreply/usercontentcontroller(_:didreceive:replyhandler:)
[apple-callasync]: https://developer.apple.com/documentation/webkit/wkwebview/callasyncjavascript(_:arguments:in:in:completionhandler:)
[apple-loadfileurl]: https://developer.apple.com/documentation/webkit/wkwebview/loadfileurl(_:allowingreadaccessto:)
[apple-inspectable]: https://developer.apple.com/documentation/webkit/wkwebview/isinspectable
[apple-webpage]: https://developer.apple.com/documentation/webkit/webpage
[apple-webview]: https://developer.apple.com/documentation/webkit/webview-swift.struct
[apple-urlschemehandler-swift]: https://developer.apple.com/documentation/webkit/urlschemehandler
[apple-universal]: https://developer.apple.com/documentation/apple-silicon/building-a-universal-macos-binary
[safari-262]: https://developer.apple.com/documentation/safari-release-notes/safari-26_2-release-notes
[wk-tests]: https://github.com/WebKit/WebKit/blob/main/Tools/TestWebKitAPI/Tests/WebKit/WKWebView/WKURLSchemeHandler-1.mm
[wk-wkwebview-mm]: https://github.com/WebKit/WebKit/blob/main/Source/WebKit/UIProcess/API/Cocoa/WKWebView.mm
[tauri-start]: https://v2.tauri.app/start/
[tauri-builder]: https://docs.rs/tauri/latest/tauri/struct.Builder.html
[tauri-webview]: https://docs.rs/tauri/latest/tauri/webview/struct.Webview.html
[tauri-calling-rust]: https://v2.tauri.app/develop/calling-rust/
[tauri-calling-frontend]: https://v2.tauri.app/develop/calling-frontend/
[tauri-ipc]: https://v2.tauri.app/concept/inter-process-communication/
[tauri-core]: https://v2.tauri.app/reference/javascript/api/namespacecore/
[tauri-config]: https://v2.tauri.app/reference/config/
[tauri-cli]: https://v2.tauri.app/reference/cli/
[tauri-bundle]: https://v2.tauri.app/distribute/macos-application-bundle/
[tauri-asset]: https://github.com/tauri-apps/tauri/blob/dev/crates/tauri/src/protocol/asset.rs
[tauri-ipc-js]: https://github.com/tauri-apps/tauri/blob/dev/crates/tauri/scripts/ipc-protocol.js
[wry-mod]: https://github.com/tauri-apps/wry/blob/dev/src/wkwebview/mod.rs
[wry-ui]: https://github.com/tauri-apps/wry/blob/dev/src/wkwebview/class/wry_web_view_ui_delegate.rs
[pdfjs-faq]: https://github.com/mozilla/pdf.js/wiki/Frequently-Asked-Questions
[bcd-map]: https://github.com/mdn/browser-compat-data/blob/main/javascript/builtins/Map.json
[bcd-u8]: https://github.com/mdn/browser-compat-data/blob/main/javascript/builtins/Uint8Array.json
[bcd-url]: https://github.com/mdn/browser-compat-data/blob/main/api/URL.json
[gtk-macos-surface]: https://gitlab.gnome.org/GNOME/gtk/-/blob/main/gdk/macos/gdkmacossurface.h

- Apple: [WKURLSchemeHandler][apple-wkurlschemehandler], [setURLSchemeHandler][apple-seturlschemehandler], [runOpenPanel][apple-runopenpanel], [WKScriptMessageHandlerWithReply][apple-reply], [callAsyncJavaScript][apple-callasync], [loadFileURL][apple-loadfileurl], [isInspectable][apple-inspectable], [WebPage][apple-webpage], [WebView][apple-webview], [URLSchemeHandler][apple-urlschemehandler-swift], [Universal binary][apple-universal], [Safari 26.2 notes][safari-262]
- WebKit: [WKURLSchemeHandler API tests][wk-tests], [WKWebView.mm][wk-wkwebview-mm]
- Tauri/wry: [What is Tauri][tauri-start], [Builder][tauri-builder], [Webview][tauri-webview], [Calling Rust][tauri-calling-rust], [Calling the frontend][tauri-calling-frontend], [IPC][tauri-ipc], [JS core][tauri-core], [Config][tauri-config], [CLI][tauri-cli], [macOS bundle][tauri-bundle], [asset.rs][tauri-asset], [ipc-protocol.js][tauri-ipc-js], [wry mod.rs][wry-mod], [wry UI delegate][wry-ui]
- pdf.js / MDN: [pdf.js FAQ][pdfjs-faq], [BCD Map][bcd-map], [BCD Uint8Array][bcd-u8], [BCD URL][bcd-url]
- GTK: [gdkmacossurface.h][gtk-macos-surface]
- Repo: `src/webview.js`, `src/book-viewer.js`, `src/reader/reader.js`, `src/reader/reader.html`, `src/opds/main.js`, `src/foliate-js/{view.js,pdf.js,rollup.config.js,vendor/pdfjs/*}`
