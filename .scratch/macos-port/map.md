# Map: Port Foliate to macOS

Label: wayfinder:map
Status: open

## Destination

A decided, step-by-step plan for shipping an unsigned, directly downloaded `Foliate.app` for macOS 14+ on Apple Silicon and Intel. The plan names the chosen approach, its known blockers, and work slices ready to build. A from-source developer build is an optional first milestone.

## Notes

- Vocabulary: see `GLOSSARY.md` (**Renderer** = foliate-js; **Shell** = the native app hosting it; **Reader page** = the shared page through which a Shell drives the Renderer).
- Approach decided: a native Swift Shell under `macos/` (ADR `docs/adr/0001-native-swift-shell-for-macos.md`). It shares `src/foliate-js` and the Reader page (`src/reader/`). Shared changes must be Linux-inert: additive only, with Linux behaviour unchanged.
- Linux behaviour must not regress; macOS changes stay behind platform boundaries.
- macOS uses the same user-data format as Linux (progress, annotations, bookmarks), so data can move between machines.
- Required features: core reading (all Renderer formats, PDF included) and the library. Linux-only integrations may be dropped or stubbed.
- Skills: `grilling` + `domain-modeling` for grilling tickets; `research` for research tickets.

## Decisions so far

- [Grilling: Spec the reader-only first milestone](issues/08-spec-reader-only-milestone.md): a tracer bullet first (scheme and CSP, file-input loading with an additive fallback, pdf.js worker, PDF speed targets), then the minimal reader. Data in Application Support or `$XDG_DATA_HOME`. Bundle ID `io.github.lucag.Foliate`. Done includes a round trip with Linux.
- [Grilling: How pdf.js copes with older Safari on macOS 14](issues/07-pdfjs-safari-compat.md): require Safari 26.2+, checked at startup by a Shell-injected script with a prompt to update. Fallback: ship pdf.js's legacy build on macOS.
- [Grilling: Choose the porting approach](issues/06-choose-approach.md): a new native macOS Shell in Swift (SwiftUI first, AppKit where needed) under `macos/`, built by an Xcode project. The shared Reader page stays unchanged. The first milestone is a reader-only app. ADR 0001 records the decision.
- [Research: Native Shell options for macOS](issues/02-native-shell-options.md): Swift and Tauri both run WKWebView. Swift keeps the reader page and lazy book loading unchanged but rewrites about 6,400 lines of Shell code. Tauri allows a web-based Shell UI but needs new book delivery and a messaging shim. The GTK Shell with WKWebView isn't worth it.
- [Research: Can GTK4, libadwaita, GJS and WebKitGTK 6.0 run on macOS?](issues/01-gtk-stack-on-macos.md): GTK4, libadwaita and GJS are packaged and recent enough. WebKitGTK 6.0 has no working macOS build anywhere, so porting the GTK Shell as-is means building it ourselves without GPU acceleration. A from-source build is worth only a time-boxed try.
- [Research: PDF dark mode in the Renderer](issues/04-pdf-dark-mode.md): recolour each page in foliate-js with canvas blend-mode fills after rendering. This works on both platforms. pdf.js `pageColors` is ruled out because WebKit has canvas filters off by default.
- [Research: The Shell–Renderer contract today](issues/03-shell-renderer-contract.md): a small contract through one page. It has 14 JS→Shell message types and about 40 Shell→JS calls, mostly passed straight to the foliate-js View API. Books load via a file input as `blob:` URLs. User data is one JSON file per book plus a few index files, so a new Shell could share it as-is.

## Not yet specified

- Library and file access on macOS: how books are found, imported and remembered across launches.
- Native TTS replacement (e.g. AVSpeechSynthesizer) for the speech-dispatcher path. Likely the hardest native piece, because macOS speech handles SSML marks differently from speech-dispatcher.
- What replaces GSettings for preferences on macOS.
- OPDS catalog and dictionary/lookup support in the Swift Shell.
- macOS conventions: menu bar, keyboard shortcuts, window and tab behaviour, settings.
- Translations: reusing `po/` gettext catalogs from Swift (and the Reader page's `uiText`).
- Packaging: DMG layout, possibly a Homebrew cask; CI for macOS builds.
- How Renderer changes (e.g. PDF recolouring) reach foliate-js: an upstream PR to johnfactotum/foliate-js vs carrying a fork in the submodule.

## Out of scope

- Mac App Store distribution (sandboxing would reshape file access and the library).
- Signing and notarization: this effort ships unsigned builds.
- Tracker integration and full Linux feature parity.
- Electron as the Shell technology (standing preference).
- [Task: Try a from-source build of the GTK app on Intel macOS](issues/05-from-source-build.md): no working WebKitGTK 6.0 build exists on macOS, so the user dropped the experiment. The porting decision rests on research.
- Possible PDF breakage on Linux with pre-2026 WebKitGTK (`Map.prototype.getOrInsertComputed`): a pre-existing Linux bug, not porting work. File it upstream with foliate-js once confirmed. See [Grilling: How pdf.js copes with older Safari on macOS 14](issues/07-pdfjs-safari-compat.md).
- pdf.js WASM decoders (JPEG 2000, ICC colour, JBIG2) missing from foliate-js: a Renderer feature gap on both platforms. **Next effort**: the user wants this tackled soon, as its own map.
