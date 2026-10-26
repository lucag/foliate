# Map: Port Foliate to macOS

Label: wayfinder:map
Status: open

## Destination

A decided, step-by-step plan for shipping an unsigned, directly downloaded `Foliate.app` for macOS 14+ on Apple Silicon and Intel. The plan names the chosen approach, its known blockers, and work slices ready to build. A from-source developer build is an optional first milestone.

## Notes

- Vocabulary: see `GLOSSARY.md` (**Renderer** = foliate-js; **Shell** = the native app hosting it).
- Approach is open: (a) port the GJS/GTK4/libadwaita/WebKitGTK Shell as-is, (b) keep the GTK Shell but swap in WKWebView, or (c) a new macOS Shell around the same Renderer. The user leans towards (c).
- Standing preferences: Swift, Rust and Tauri are all acceptable; **avoid Electron**.
- A new Shell lives in this repo under `macos/` and shares `src/foliate-js` directly.
- Linux behaviour must not regress; macOS changes stay behind platform boundaries.
- macOS uses the same user-data format as Linux (progress, annotations, bookmarks), so data can move between machines.
- Required features: core reading (all Renderer formats, PDF included) and the library. Linux-only integrations may be dropped or stubbed.
- Skills: `grilling` + `domain-modeling` for grilling tickets; `research` for research tickets.

## Decisions so far

- [Research: Native Shell options for macOS](issues/02-native-shell-options.md): Swift and Tauri both run WKWebView. Swift keeps the reader page and lazy book loading unchanged but rewrites about 6,400 lines of Shell code. Tauri allows a web-based Shell UI but needs new book delivery and a messaging shim. The GTK Shell with WKWebView isn't worth it.
- [Research: Can GTK4, libadwaita, GJS and WebKitGTK 6.0 run on macOS?](issues/01-gtk-stack-on-macos.md): GTK4, libadwaita and GJS are packaged and recent enough. WebKitGTK 6.0 has no working macOS build anywhere, so porting the GTK Shell as-is means building it ourselves without GPU acceleration. A from-source build is worth only a time-boxed try.
- [Research: PDF dark mode in the Renderer](issues/04-pdf-dark-mode.md): recolour each page in foliate-js with canvas blend-mode fills after rendering. This works on both platforms. pdf.js `pageColors` is ruled out because WebKit has canvas filters off by default.
- [Research: The Shell–Renderer contract today](issues/03-shell-renderer-contract.md): a small contract through one page. It has 14 JS→Shell message types and about 40 Shell→JS calls, mostly passed straight to the foliate-js View API. Books load via a file input as `blob:` URLs. User data is one JSON file per book plus a few index files, so a new Shell could share it as-is.

## Not yet specified

- Library and file access on macOS: how books are found, imported and remembered across launches.
- Native TTS replacement (e.g. AVSpeechSynthesizer) for the speech-dispatcher path. Likely the hardest native piece, because macOS speech handles SSML marks differently from speech-dispatcher.
- Where shared user data lives on macOS (XDG paths vs `~/Library/Application Support`), and what replaces GSettings for preferences.
- OPDS catalog and dictionary/lookup support in the new Shell.
- macOS conventions: menu bar, keyboard shortcuts, window and tab behaviour, settings.
- Translations: reusing `po/` gettext catalogs in the macOS Shell.
- Building one app for both chip types (universal binary vs separate builds).
- Packaging: DMG layout, possibly a Homebrew cask; CI for macOS builds.
- WKWebView spike, once the approach is chosen: does the pdf.js worker load over a custom scheme, do host-less `foliate:///` URLs work with the page's security policy, how does PDF performance hold up, and does the PDF recolouring work.
- How Renderer changes (e.g. PDF recolouring) reach foliate-js: an upstream PR to johnfactotum/foliate-js vs carrying a fork in the submodule.

## Out of scope

- Mac App Store distribution (sandboxing would reshape file access and the library).
- Signing and notarization: this effort ships unsigned builds.
- Tracker integration and full Linux feature parity.
- Electron as the Shell technology (standing preference).
- [Task: Try a from-source build of the GTK app on Intel macOS](issues/05-from-source-build.md): no working WebKitGTK 6.0 build exists on macOS, so the user dropped the experiment. The porting decision rests on research.
