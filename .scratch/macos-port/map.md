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

- [Grilling: Slice dark-mode pages into build work](issues/21-slice-dark-mode-pages.md): six slices in [the dark-mode build effort](../macos-dark-mode/spec.md), after reader slices 07 and 10, in parallel with the library. A PDF tracer that creates the fork comes first, then per-book overrides and PDF Smart images, then scans and EPUB, then acceptance on the user's books. Three optional `setAppearance` fields keep Linux unchanged. The three settings are app-wide with a per-book override, as text size is. The missing Settings window is now library slice 10.
- [Grilling: Slice the library milestone into build tickets](issues/20-slice-library-milestone.md): nine slices in [the library build effort](../macos-library-milestone/spec.md), after reader slices 04, 05 and 10. A tracer first (store, window, grid, launch), then Home/sort, search, Remove and live updates in parallel, then Not Found, adding, missing covers and acceptance. A hidden web-view importer, covers stay in the cache, Date Added in a macOS side file, FSEvents for outside changes.
- [Grilling: Preferences on macOS](issues/18-preferences-on-macos.md): `UserDefaults` with key names mirroring GSettings, kept on the machine and never synced. Window, library, sidebar, cursor and animation keys are dropped. A remembered voice per language. A global Default text size plus a per-book Book text size. Linux's stylesheet and theme files are read from the config folder. The Settings window (Text, Layout, Appearance) is a library-milestone slice.
- [Prototype: How dark-mode pages look](issues/19-design-dark-mode-pages.md): Smart is the default. PDFs use operator-list boxes, trimmed so no halo is left, plus pixel detection where there is no box (scans). EPUBs use the per-image check. A setting, Images in Dark Mode: Original / Smart / Invert, sits in the Aa popover and the View menu, and Invert replaces the old toggle. Photo dimming (100/85/80%) and Recolour Charts are the reader's choice. Opt-in in shared code, so Linux is unchanged.
- [Prototype: Design the Library window](issues/17-design-library-window.md): a sidebar window with no toolbar. The sidebar holds Search Library, Home (Continue Reading, Recently Added, All Books), the Library sections with counts, and a greyed Catalogs place for OPDS. Grid only, with sort beside each section title. Not Found and Remove use sheets. Books are added only through multi-select Open… or drops. Variant E.
- [Research: What dark mode recolours and what it leaves alone](issues/16-dark-mode-images-vs-figures.md): recolour ink (text, vectors, stencils, scans), keep photos dimmed, and keep hue with a `color` blend pass. Photos come back from the private operator list or pixel detection (corrects `04`). For reflowable books, drop the opaque image background, dim photos, and recolour detected line art with an SVG filter.
- [Grilling: Read-aloud in the Swift Shell](issues/15-tts-in-swift-shell.md): `AVSpeechSynthesizer` behind the existing TTS contract. The `<emphasis level>` fix goes in foliate-js, speed and pitch in `<prosody>`, and pause is native. A macOS-only voice picker, a Read Aloud popover in the pill, and Edit › Speech menus. Narrated EPUBs are included. Third milestone, checked on macOS 14 in a VM.
- [Grilling: Library and file access on macOS](issues/13-library-and-file-access.md): books stay in place, and the library is every per-book JSON in the shared folder. The app writes Linux's `uri-store.json` plus a macOS-only bookmark side file to find moved books, falling back to Locate…. A separate Library window. The library is the second milestone.
- [Grilling: How Renderer changes reach foliate-js](issues/11-foliate-js-upstream-or-fork.md): a temporary fork `lucag/foliate-js` (branch `foliate-macos`, based on the current pin, upstream merged in, never rebased), with each change also sent upstream as a PR. One commit for both platforms. The fork is created by the first ticket that needs it; the reader-only milestone doesn't.
- [Grilling: Slice the reader-only milestone into build tickets](issues/10-slice-reader-milestone.md): eleven slices in [the reader-only build effort](../macos-reader-milestone/spec.md). First the tracer bullet, then the bridge, then user data, overlays, states and document types in parallel, ending with acceptance. A fallback slice and a PDF performance slice are conditional. XcodeGen project under `macos/`; XCTest plus manual checklists.
- [Research: macOS speech synthesis and the TTS path's SSML marks](issues/12-macos-speech-ssml.md): `AVSpeechSynthesizer` speaks foliate-js's SSML and reports its `<mark>`s, so the Renderer's TTS contract is kept. Three gaps: a bare `<emphasis>` is dropped, rate and pitch must go in `<prosody>`, and mark order needs guarding. Web Speech in WKWebView is ruled out.
- [Research: Using the `po/` translations from the Swift Shell](issues/14-translations-from-swift.md): keep `po/` as the only source. A converter we write turns it into a generated String Catalog at build time, with plurals mapped through CLDR, and Swift looks strings up through `Bundle`. libintl is ruled out. Strings new to macOS go into `po/` too.
- [Prototype: Design the reader window](issues/09-design-reader-window.md): an immersive window with no toolbar. A hover top overlay has a pill with Contents and Aa popovers (search and bookmark greyed for later), and the bottom overlay is a slider only. Yellow highlight and Copy, the nine Linux themes, Single/Two Page in the View menu.
- [Grilling: Spec the reader-only first milestone](issues/08-spec-reader-only-milestone.md): a tracer bullet first (scheme and CSP, file-input loading with an additive fallback, pdf.js worker, PDF speed targets), then the minimal reader. Data in Application Support or `$XDG_DATA_HOME`. Bundle ID `io.github.lucag.Foliate`. Done includes a round trip with Linux.
- [Grilling: How pdf.js copes with older Safari on macOS 14](issues/07-pdfjs-safari-compat.md): require Safari 26.2+, checked at startup by a Shell-injected script with a prompt to update. Fallback: ship pdf.js's legacy build on macOS.
- [Grilling: Choose the porting approach](issues/06-choose-approach.md): a new native macOS Shell in Swift (SwiftUI first, AppKit where needed) under `macos/`, built by an Xcode project. The shared Reader page stays unchanged. The first milestone is a reader-only app. ADR 0001 records the decision.
- [Research: Native Shell options for macOS](issues/02-native-shell-options.md): Swift and Tauri both run WKWebView. Swift keeps the reader page and lazy book loading unchanged but rewrites about 6,400 lines of Shell code. Tauri allows a web-based Shell UI but needs new book delivery and a messaging shim. The GTK Shell with WKWebView isn't worth it.
- [Research: Can GTK4, libadwaita, GJS and WebKitGTK 6.0 run on macOS?](issues/01-gtk-stack-on-macos.md): GTK4, libadwaita and GJS are packaged and recent enough. WebKitGTK 6.0 has no working macOS build anywhere, so porting the GTK Shell as-is means building it ourselves without GPU acceleration. A from-source build is worth only a time-boxed try.
- [Research: PDF dark mode in the Renderer](issues/04-pdf-dark-mode.md): recolour each page in foliate-js with canvas blend-mode fills after rendering. This works on both platforms. pdf.js `pageColors` is ruled out because WebKit has canvas filters off by default.
- [Research: The Shell–Renderer contract today](issues/03-shell-renderer-contract.md): a small contract through one page. It has 14 JS→Shell message types and about 40 Shell→JS calls, mostly passed straight to the foliate-js View API. Books load via a file input as `blob:` URLs. User data is one JSON file per book plus a few index files, so a new Shell could share it as-is.

## Not yet specified

- OPDS catalog and dictionary/lookup support in the Swift Shell.
- macOS conventions beyond the reader window (whose menus and shortcuts are decided): window tabs, multiple windows.
- Where annotations are listed and managed, now that the chosen reader window has no sidebar.
- Packaging: DMG layout, possibly a Homebrew cask; CI for macOS builds.


## Out of scope

- Mac App Store distribution (sandboxing would reshape file access and the library).
- Signing and notarization: this effort ships unsigned builds.
- Tracker integration and full Linux feature parity.
- Electron as the Shell technology (standing preference).
- [Task: Try a from-source build of the GTK app on Intel macOS](issues/05-from-source-build.md): no working WebKitGTK 6.0 build exists on macOS, so the user dropped the experiment. The porting decision rests on research.
- Possible PDF breakage on Linux with pre-2026 WebKitGTK (`Map.prototype.getOrInsertComputed`): a pre-existing Linux bug, not porting work. File it upstream with foliate-js once confirmed. See [Grilling: How pdf.js copes with older Safari on macOS 14](issues/07-pdfjs-safari-compat.md).
- Per-book text size on Linux: there, A−/A+ zoom the WebView without saving it, and `default-size` is global. macOS remembers a size per book ([Grilling: Preferences on macOS](issues/18-preferences-on-macos.md)). This is a Linux Shell change for later, which also decides whether both platforms move the size into the per-book JSON.
- Linux adopting dark-mode pages: the Linux Shell would send the new `setAppearance` fields. It first needs the WebKitGTK re-checks listed in [Prototype: How dark-mode pages look](issues/19-design-dark-mode-pages.md) (blend modes, the SVG filter, `getImageData` cost, `blob:` tainting, the first-draw race). See [Grilling: Slice dark-mode pages into build work](issues/21-slice-dark-mode-pages.md).
- pdf.js WASM decoders (JPEG 2000, ICC colour, JBIG2) missing from foliate-js: a Renderer feature gap on both platforms. **Next effort**: the user wants this tackled soon, as its own map.
