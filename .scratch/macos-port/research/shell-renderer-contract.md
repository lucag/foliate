# Research: The Shell–Renderer contract today

Answers `.scratch/macos-port/issues/03-shell-renderer-contract.md`.

Sources: this repo at `4aa0fe3` (branch `gtk4`). foliate-js is the submodule at `399248a6`. It is not checked out in this worktree, so foliate-js citations (`src/foliate-js/...`) were read from the main checkout at that same commit. All line numbers refer to those files.

## TL;DR

- **The contract is small, and it runs over one page.** The Shell loads `foliate:///reader/reader.html`. That page is a thin glue module (`src/reader/reader.js`, 557 lines) wrapped around foliate-js's `<foliate-view>`. All traffic goes through two primitives:
  - **JS → Shell:** `webkit.messageHandlers.<name>.postMessage(JSON string)`.
  - **Shell → JS:** `evaluate_javascript` on a global expression path such as `reader.view.goTo`, wrapped in a token/promise RPC.
- **Renderer → Shell:** 14 event types on the `viewer` handler, plus one request/response call (`showSelection`). See the list below.
- **Shell → Renderer:** about 40 RPC targets. Nearly all of them call foliate-js `View` methods directly. Two pass data: `init` (UI strings) and `reader.setAppearance` (layout, style and theme).
- **Book bytes do not go through a custom URL scheme.** The page clicks a hidden `<input type=file>`. The Shell answers WebKit's `run-file-chooser` signal with the book's path, and foliate-js reads the resulting `File` and serves everything inside the book as `blob:` URLs.
- **User data is plain JSON on disk, with one file per book**, at `$XDG_DATA_HOME/com.github.johnfactotum.Foliate/<encodeURIComponent(identifier)>.json`. It holds the keys `metadata`, `progress`, `lastLocation`, `annotations` and `bookmarks`. The library is a directory listing of those files plus `library/uri-store.json`. Covers are PNGs under `$XDG_CACHE_HOME/com.github.johnfactotum.Foliate/`. Settings are in GSettings (dconf), not in files.
- **Pure JS already:** rendering, pagination, CFI handling, search, the TTS SSML/mark walker, media overlays, footnotes, CSS theming, print, and cover extraction.
- **GTK/GIO-bound:** every piece of chrome, file I/O and the JSON store, GSettings, covers (GdkPixbuf), the clipboard, speech-dispatcher TTS, the Tracker URI lookup, downloads, file dialogs, and the gettext strings.

## 1. URL schemes and resource loading

### Custom schemes

All of them are registered on the default `WebKit.WebContext`, in `src/webview.js:6-30`.

| Scheme | Allowed path prefixes | Used by |
|---|---|---|
| `foliate:` | `/reader/`, `/foliate-js/` | Reader page (`book-viewer.js:346`, `:498`) |
| `foliate-opds:` | `/opds/`, `/foliate-js/`, `/icons/`, `/common/` | OPDS catalog browser (`library.js:589`) |
| `foliate-selection-tool:` | `/selection-tools/`, `/icons/`, `/common/` | Dictionary, Wikipedia and Translate popovers (`selection-tools.js:34,47,60`) |

How a request is handled (`webview.js:17-26`):
- The URI path is mapped onto `pkg.moduleuri(path)`. That is a `resource:///com/github/johnfactotum/Foliate/...` GResource URI under Meson, or a `file://` URI next to `main.js` when run from source (`main.js:41-54`).
- A path outside the allowed prefixes throws, and the request finishes with `NOT_FOUND` (`webview.js:8-14`).
- There are only three MIME types: `.js`/`.mjs` → `application/javascript`, `.svg` → `image/svg+xml`, and everything else → `text/html`.
- Under Meson, icon paths drop `/hicolor` (`webview.js:18-20`) to match the GResource aliases (`generate-gresource.js:16-21`).

### What is bundled

`src/generate-gresource.js:28-53` bundles:
- all Shell `.js` files except `main.js`
- `ui/` and the action icons
- the `.js` files of foliate-js (excluding `reader.js` and the config files)
- `foliate-js/vendor/` and pdf.js, with its `cmaps/` and `standard_fonts/` compressed
- `opds/`, `selection-tools/`, `common/` and `reader/`

A macOS Shell has to serve the same tree under one origin. With WKWebView that means a `WKURLSchemeHandler` or `loadFileURL(allowingReadAccessTo:)`. The MIME rules above are the minimum needed: ES modules need `application/javascript`.

### The reader page

`src/reader/reader.html`:
- Sets a CSP (`:4`): `default-src 'self' blob:`, `script-src 'self'`, `img-src 'self' blob: data:`, `frame-src blob: data:`. Section documents therefore render in `blob:` iframes, and no inline scripts are allowed.
- Has a hidden `<input type="file" id="file-input">` (`:127`), a `#ribbon` bookmark marker (`:128`), a `<dialog id="footnote-dialog">` (`:129-139`), and `<script type="module" src="reader.js">` (`:140`).
- Uses CSS variables `--light-bg/--light-fg/--dark-bg/--dark-fg` (`:6-28`), which `setAppearance` sets. Dark mode comes from `prefers-color-scheme` (`:21-33`), so the host web view has to report the system appearance.

### How the book file reaches the Renderer

1. The Shell keeps the path (`book-viewer.js:345`) and loads `reader.html` (`:346`).
2. The page emits `ready` (`reader.js:557`). The Shell calls `init({uiText})` (`book-viewer.js:214-215`), and `init` then calls `loadFile()`, which clicks `#file-input` (`reader.js:514`, `:528`).
3. WebKit fires `run-file-chooser`, and the Shell answers `req.select_files([encodeURI(path)])` without showing any UI (`book-viewer.js:182-183`).
4. The `change` handler calls `makeBook(file)` (`reader.js:497-512`, `:526`). foliate-js sniffs the format: zip/EPUB/CBZ/FBZ, PDF, MOBI or FB2 (`foliate-js/view.js:79-123`). It unpacks in memory and serves each resource through `URL.createObjectURL` (for example `foliate-js/epub.js:454`, `:727`).

`makeBook` also accepts a URL string, which it `fetch`es (`foliate-js/view.js:72-80`). A macOS Shell could therefore drop the file-chooser trick and pass a URL from a custom scheme. That would be a small change to `reader.js:497-529`.

### Web view settings the Shell sets

The reader view (`book-viewer.js:167-180`):
- console output goes to stdout
- developer extras are on
- back/forward gestures, hyperlink auditing, HTML5 database and localStorage are all off
- smooth scrolling is off
- autoplay is allowed, because media overlays need it

The OPDS view (`library.js:502-513`) also sets `disable_web_security: true` (for cross-origin feed fetches), a custom `user_agent` of `Foliate/<version>`, and `enable_javascript_markup: false`.

## 2. The RPC mechanism

The mechanism is in `src/webview.js`. A Swift `WKScriptMessageHandler` combined with `evaluateJavaScript` covers it one-to-one.

| Primitive | Direction | Mechanism | Ref |
|---|---|---|---|
| `run(script)` | Shell→JS | `evaluate_javascript`, result ignored | `:93-96` |
| `eval(exp)` | Shell→JS | evaluates `JSON.stringify(exp)` and parses the result | `:97-109` |
| `exec(func, params)` | Shell→JS, async | Builds `(async () => await func(JSON.parse(decodeURI("…"))))()`, then posts `{token, ok, payload}` back on a private handler named `com.github.johnfactotum.Foliate.<random>`. A promise store resolves it. Only one argument can be passed. | `:43-61`, `:111-122` |
| `iter(func, params)` | Shell→JS | Stores an async generator at `globalThis[handler][name]`. Each `next()` is an `exec`. Used for search. | `:124-142` |
| `provide(name, cb)` | JS→Shell, async | Injects `globalThis[name] = params => promise`. JS posts `{token, payload}` to handler `<private>.<name>`, and the Shell replies by running `globalThis.<name>.resolve(token, ok, value)`. | `:145-173` |
| `registerHandler(name, cb)` | JS→Shell | `register_script_message_handler(name)`. Payloads are JSON strings. | `:174-185` |

Every payload is JSON. Non-serialisable fields such as DOM `Range` objects serialise to `{}`, and the Shell never relies on them.

## 3. Messages: Renderer → Shell

### `viewer` handler

All of these are sent with `emit()` in `reader.js:8-9`. The Shell dispatches them in `book-viewer.js:213-224` and turns everything except `ready`, `pinch-zoom` and `history-index-change` into a GObject signal (`:148-164`). The signals are consumed at `book-viewer.js:534-551`.

| `type` | Payload | Emitted at | Shell reaction |
|---|---|---|---|
| `ready` | — | `reader.js:557` | `exec('init', {uiText})` and inject `showSelection` (`book-viewer.js:214-216`) |
| `book-ready` | `{book, reader}`: the whole `book` and `Reader` objects run through `JSON.stringify` | `reader.js:503` | `#onBookReady` (`book-viewer.js:795-855`) reads `book.metadata` (with `description` already converted to Pango markup, `reader.js:228-229`), `book.toc`, `book.dir`, `book.pageList`, `book.landmarks`, `book.media.duration`, `reader.sectionFractions`, `reader.pageTotal` and `reader.view.language.direction` |
| `book-error` | `{id: 'not-found' \| 'unsupported-type'}` or `{message, stack}` | `reader.js:505-510`, `:527` | error page (`book-viewer.js:782-794`) |
| `relocate` | foliate-view `lastLocation`: `{fraction, section:{current,total}, location:{current,next,total}, time:{section,total}, tocItem, pageItem, cfi}` | `reader.js:336`; shape from `foliate-js/view.js:327-336`, `progress.js:82-97` | updates the TOC, navbar, bookmarks and annotations, and saves `progress` and `lastLocation` (`book-viewer.js:856-867`) |
| `create-overlay` | `{index}` (section index) | `reader.js:338-339` | re-adds that section's annotations (`book-viewer.js:959-964`) |
| `external-link` | `{href}` (plus an `a` element that serialises to `{}`) | `reader.js:249-252`, `:357-360` | `Gtk.UriLauncher` (`book-viewer.js:538`) |
| `selection` | `{action:'copy', text, html}` / `{action:'copy-citation', text, value, tocItem, pageItem}` / `{action:'speak-from-here', ssml}` | `reader.js:412-430` | clipboard with HTML and text, citation string, TTS (`book-viewer.js:929-958`) |
| `show-image` | `{base64, mimetype}`, sent on double-click of an `<img>` | `reader.js:374-380` | native image viewer window (`book-viewer.js:965-996`) |
| `dialog-open` / `dialog-close` | — | `reader.js:275`, `:207` | hide or show the header bar and nav bar (`book-viewer.js:543-550`); scroll paging is suppressed while open (`:247`) |
| `pinch-zoom` | `{scale}` (`visualViewport.scale`) | `reader.js:489-490` | stored to scale popover anchors and to stop scroll paging (`book-viewer.js:218`, `:245`, `:358-361`) |
| `history-index-change` | `{canGoBack, canGoForward}` | `reader.js:367-370` | enables or disables the back and forward actions (`book-viewer.js:219-222`) |

### `showSelection` (request/response)

This call goes through `provide`, at `book-viewer.js:211-212`.

The Renderer awaits `globalThis.showSelection(payload)`:
- with `{type:'selection', text, content, lang, value: cfi, pos:{point:{x,y}, dir:'up'|'down'}}` from `reader.js:410`
- or with `{type:'annotation', value, pos}` from `reader.js:396`

The Shell shows a native popover at `pos` (`book-viewer.js:362-371`, `:876-928`). It resolves with one of these action strings: `'copy' | 'copy-citation' | 'highlight' | 'print' | 'speak-from-here' | 'select' | undefined`. The Renderer then acts on that string (`reader.js:410-432`).

Some popover actions never return to the Renderer:
- `copy-cfi` goes straight to the clipboard.
- `search` drives the Shell search.
- `highlight` makes the Shell create the annotation itself through `BookData.addAnnotation` (`book-viewer.js:893-917`).

### Other pages

These are not the reader page, but a full port has to cover them.

- **OPDS** (`src/opds/main.js` → handler `opds`, `library.js:557-571`):
  - `{type:'download', href, token}` (`opds/main.js:425`)
  - `{type:'cancel', token}` (`:435`)
  - `{type:'state', state}` (`:625`)
  - The Shell also `provide`s `formatNumber`, `formatMime`, `formatPrice`, `formatLanguage`, `formatDate`, `formatList` and `matchLocales` (`library.js:515-524`). After load it injects `globalThis.uiText`, sets `document.documentElement.lang`, and runs `import('./main.js')` (`library.js:526-534`).
  - Shell → JS calls: `updateState`, `updateProgress({progress, token})`, `finishDownload({token})` (`library.js:537`, `:621-625`).
- **Selection tools:**
  - Shell → JS: `exec('init', {msg, text, lang})` (`selection-tools.js:120-125`).
  - JS → Shell: handler `settings` with `{key:'translate-target-language', value}` (`translate.html:206-209`, `selection-tools.js:115-118`).
  - Navigation outside the `foliate-selection-tool:` scheme is cancelled and opened externally (`selection-tools.js:92-104`). OPDS does the same at `library.js:542-555`.

## 4. Messages: Shell → Renderer

These are `exec` calls on global paths. The wrappers are in `book-viewer.js:376-418`, and the input wiring is at `:229-274`. Almost all of them are a passthrough to the foliate-js `View` API (`foliate-js/view.js`).

| Group | Targets (args) |
|---|---|
| Bootstrap | `init({uiText})` (`reader.js:516-529`); `initImport()` and `loadFile()` for headless import (`reader.js:514`, `:531-555`) |
| Appearance | `reader.setAppearance({layout, style, autohideCursor})` (see §5) |
| Navigation | `reader.view.init({lastLocation})`, `goTo(href\|cfi\|index)`, `goToFraction(n)`, `select(cfi)`, `deselect()`, `prev(distance?)`, `next(distance?)`, `goLeft()`, `goRight()`, `renderer.prevSection/nextSection/firstSection/lastSection()`, `history.back/forward()` |
| Gestures | `reader.scrollBy([dx,dy])`, `reader.snap([dx,dy])` (`reader.js:481-486`), driven by `Gtk.EventControllerScroll` (`book-viewer.js:230-262`); mouse buttons 8 and 9 call `history.back/forward` (`:265-274`) |
| Queries | `reader.view.getTOCItemOf(cfi)` → `{label,…}`; `reader.getCover()` → base64 string or null (`reader.js:468-477`) |
| Annotations | `reader.view.addAnnotation({value,color,…})` → `{index,label}`; `deleteAnnotation(a)`; `showAnnotation(a)` (`foliate-js/view.js:366-428`) |
| Search | `iter('reader.view.search', {query, index?, scope, matchCase, matchDiacritics, matchWholeWords})` yields `{progress}`, then `{label, subitems:[{cfi, excerpt}]}` or `{cfi, excerpt}`, then `'done'` (`search.js:7-12`, `:102-133`; `foliate-js/view.js:523-574`). `clearSearch()` |
| TTS | `reader.view.initTTS()`, `tts.start()`, `tts.resume()`, `tts.prev(paused?)`, `tts.next(paused?)` → SSML string; `tts.setMark(mark)` (`book-viewer.js:403-408`, `:711-722`) |
| Media overlay | `startMediaOverlay()`, `mediaOverlay.pause/resume/stop/prev/next()`, `setVolume(v)`, `setRate(r)` |
| Misc | `reader.print()`; ribbon visibility via `run("document.querySelector('#ribbon').style.visibility=…")` (`book-viewer.js:372-375`) |

## 5. Injected settings, styles, themes and fonts

The Renderer has no settings store of its own. Everything comes in through these channels:

1. **`uiText`** (`book-viewer.js:26-43`) carries the gettext-translated strings `loc`, `page`, `pageWithoutTotal`, `close`, and `references.{footnote,endnote,note,glossary,biblioentry}[-go]`. It is passed to `init` and used for the header/footer and footnote dialog text (`reader.js:516-524`, `:268-272`).

2. **`setAppearance`** (`book-viewer.js:316-338`, consumed at `reader.js:285-307`):
   ```
   layout: { gap, maxInlineSize, maxBlockSize, maxColumnCount,
             flow: 'scrolled'|'paginated', animated }
   style:  { lineHeight, justify, hyphenate, invert,
             theme: {light:{fg,bg,link}, dark:{fg,bg,link}, inverted?:{fg,link}},
             overrideFont, userStylesheet }
   autohideCursor
   ```
   - The layout values become `<foliate-paginator>` attributes.
   - The style values feed `getCSS()` (`reader.js:51-163`). It returns a `[before, after]` CSS pair passed to `renderer.setStyles`, plus the CSS variables on `:root` and an `invert` class on `body`.
   - The theme colours are in `themes.js:6-52` (9 built-in themes). Users can add more as `$XDG_CONFIG_HOME/com.github.johnfactotum.Foliate/themes/*.json` (`themes.js:54-73`).
   - `invertTheme` derives `inverted.{fg,link}` (`themes.js:110-113`).
   - The `userStylesheet` string is the contents of `$XDG_CONFIG_HOME/com.github.johnfactotum.Foliate/user-stylesheet.css`, read once at module load (`book-viewer.js:45-46`) and appended to the "after" CSS (`reader.js:163`).

3. **Fonts are not injected as CSS.** They are set as web view settings (`book-viewer.js:305-315`): `serif/sans_serif/monospace/default_font_family`, `default_font_size` and `minimum_font_size`. The families come from Pango font description strings (`:74`). Book CSS can override them unless `overrideFont` adds `* { font-family: revert !important }` (`reader.js:162`).
   - **This is the one place where the contract lives in WebKitGTK `WebKit.Settings` rather than in JS.**
   - WKWebView has no per-family default-font settings. A macOS Shell would have to inject `@font-face`/`font-family` CSS through `setStyles`, or extend `getCSS`.

4. **Shell-side state only:** `brightness` (declared in `book-viewer.js:49`, but no code in `src/` consumes it), the zoom level (`zoom_level`, `:352-354`), and the pinch factor.

The Shell's own chrome is themed to match through a `Gtk.CssProvider` built from the same theme table (`themes.js:75-108`, `book-viewer.js:560-577`).

## 6. On-disk user data: format and location

The paths come from GLib's XDG directories, set in `main.js:31-39`. `pkg.name` is `com.github.johnfactotum.Foliate`.

| What | Path | Format | Ref |
|---|---|---|---|
| Per-book data | `$XDG_DATA_HOME/<pkg.name>/<encodeURIComponent(identifier)>.json` | JSON object, written with no indent and debounced 1 s | `data.js:20`, `utils.js:67-146` |
| Library URI map | `$XDG_DATA_HOME/<pkg.name>/library/uri-store.json` | `{"uris": [[identifier, "~/path" \| "file:///…"], …]}` | `library.js:116-136`, `data.js:95-101` |
| OPDS catalogs | `$XDG_DATA_HOME/<pkg.name>/catalogs/catalogs.json` | `{"catalogs": [{title, uri}, …]}`, indent 2 | `library.js:651`, `:748-754` |
| Covers | `$XDG_CACHE_HOME/<pkg.name>/<encodeURIComponent(identifier)>.png` | PNG scaled to `cover-size` width (default 256). Never overwritten once present. Skipped when `show-covers` is false. | `data.js:83-94` |
| Custom themes | `$XDG_CONFIG_HOME/<pkg.name>/themes/*.json` | `{label?, light:{fg,bg,link}, dark:{fg,bg,link}}` | `themes.js:54-73` |
| User stylesheet | `$XDG_CONFIG_HOME/<pkg.name>/user-stylesheet.css` | CSS | `book-viewer.js:45-46` |
| Preferences | GSettings schemas `com.github.johnfactotum.Foliate{,.window,.library,.viewer,.viewer.view,.viewer.font}` | dconf | `data/com.github.johnfactotum.Foliate.gschema.xml`; bound at `book-viewer.js:553-555`, `selection-tools.js:108`, `utils.js:203-214` |

### The per-book JSON file

The keys are written at `book-viewer.js:850`, `:864-865` and `data.js:78-81`:

```json
{
  "metadata": { "...": "foliate-js book.metadata (title, author, identifier, language, description as Pango markup, ...)" },
  "progress": [locationCurrent, locationTotal],
  "lastLocation": "epubcfi(...)",
  "annotations": [
    { "value": "epubcfi(...)", "color": "yellow|orange|red|magenta|aqua|lime|underline|squiggly|strikethrough|<css rgba>",
      "text": "...", "note": "...", "created": "ISO-8601", "modified": "ISO-8601" }
  ],
  "bookmarks": ["epubcfi(...)", ...]
}
```

- **Annotation fields** are the GObject properties of `FoliateAnnotation` (`annotations.js:15-22`), serialised through `toJSON` (`utils.js:239-241`). The colour vocabulary is at `annotations.js:437-445`, and custom colours come from `Gtk.ColorDialog`, at `:466`.
- **Bookmarks** are bare CFIs. Their labels are recomputed on load with `getTOCItemOf` (`data.js:31-41`, `annotations.js:108-110`).
- **Identifier:** `book.metadata.identifier`, falling back to `foliate:<md5 of the first 10,000,000 bytes>` (`book-viewer.js:434-446`, `:832`).
- **The library** is just the per-book JSON files in `$XDG_DATA_HOME/<pkg.name>/`, sorted by mtime (`library.js:105-115`, `:141-147`). The file location of each book is found first through a GNOME Tracker SPARQL query (`library.js:82-101`, `:118-124`), then through `uri-store.json`.
- **Annotation export** (`annotations.js:632-722`): JSON is the same `{annotations, metadata, …}` object as the per-book file, stringified with indent 2. HTML, Markdown and Org are also offered.
- **Annotation import** accepts that JSON and warns when `metadata.identifier` does not match (`annotations.js:589-630`).

A macOS Shell that keeps this JSON schema and the `encodeURIComponent(identifier)` file naming would be data-compatible with the Linux build: the files could be copied or synced across. Only the directory roots would differ (for example `~/Library/Application Support/...`). GSettings preferences are not portable, and would map to `UserDefaults`.

## 7. Pure JS vs GTK/GIO-bound

### Already pure JS inside the web view (comes free with the Renderer)

- Book parsing for every format, plus rendering, pagination, fixed layout and PDF through the vendored pdf.js (`foliate-js/view.js:79-123`, `:251-258`)
- CFI generation and resolution, progress, TOC and page-list tracking, and navigation history (`foliate-js/view.js:157-197`, `:327-336`, `:429-473`)
- Search with matching options, and the generator protocol (`foliate-js/view.js:523-579`)
- The annotation overlay drawing and hit-testing (`reader.js:345-356`, `foliate-js/view.js:366-418`)
- Footnote popups (`reader.js:205-276`)
- Theme and layout CSS generation (`reader.js:51-163`)
- Print through a hidden iframe (`reader.js:434-467`)
- TTS text segmentation into SSML with marks. foliate-js `tts.js` runs inside the page; only the speaking is native.
- Media overlay playback through `<audio>` in the page
- Cover extraction to base64 (`reader.js:468-477`), and HTML-to-Pango description markup (`reader/markup.js`)

### Shell logic that is plain JS and could move into the page (or be ported as is)

These are GObject-wrapped, but the logic itself has no GTK dependency:
- the scroll-to-page debounce
- the theme table and `invertTheme` (`themes.js:6-52`, `:110-113`; `utils.invertColor` is GTK `RGBA`-based but trivial)
- the `setAppearance` payload assembly (`book-viewer.js:316-338`)
- the annotation and bookmark model ordering by `CFI.compare` (`annotations.js:88-110`, `:181-247`), which already imports foliate-js `epubcfi.js`
- the citation formatting (`book-viewer.js:938-954`)
- the export formatters for JSON, HTML, Markdown and Org (`annotations.js:673-722`)
- `format.js`'s `Intl` formatters, which are already exposed to OPDS through `provide`
- the OPDS browser itself (`src/opds/main.js` runs in a web view; the Shell only supplies formatters and downloads)
- the selection tools (Wiktionary, Wikipedia and Google Translate HTML pages)
- the per-book JSON schema itself

### GTK/GIO/platform-bound (a macOS Shell must re-implement)

- **All chrome:** windows, header bar and nav bar, sidebar with TOC, annotation, bookmark and search lists, popovers anchored at `pos`, preferences dialog, book-info window, image viewer, toasts, and keyboard shortcuts (`book-viewer.js:747-780`)
- **Feeding the file:** `run-file-chooser` interception (`book-viewer.js:182-183`)
- **Custom scheme serving** from GResource (`webview.js:6-30`)
- **Storage:** `JSONStorage` file I/O with a Gio file monitor (`utils.js:67-146`), the XDG paths (`main.js:31-39`), and GSettings bindings (`utils.js:203-214`)
- **Identity and covers:** the MD5 fallback identifier (`GLib.compute_checksum_for_bytes`, `book-viewer.js:434-446`), and cover decoding and scaling with GdkPixbuf (`data.js:83-94`, `utils.base64ToPixbuf`)
- **Platform services:**
  - clipboard with HTML and text targets (`book-viewer.js:929-937`)
  - `Gtk.UriLauncher` for external links (`book-viewer.js:538`)
  - file dialogs for open, save-image, import and export
  - OPDS downloads through `WebKit.Download` (`library.js:599-640`)
  - TTS playback through speech-dispatcher over a Unix socket (SSIP), including `SPEAK` with SSML marks fed back through `tts.setMark` (`speech.js:4-161`, `tts.js:66-80`). On macOS this would be `AVSpeechSynthesizer`, which does not support SSML marks the same way, so it is a likely friction point.
  - the Tracker URI lookup (`library.js:82-101`), which can be dropped on macOS
- **WebKitGTK-specific settings:**
  - default font families and sizes (`book-viewer.js:305-315`)
  - `zoom_level` (`:352-354`)
  - the web inspector (`:355-357`)
  - `disable_web_security` for OPDS (`library.js:511`)
  - context-menu suppression (`book-viewer.js:184`, `:340-342`)
- **Localisation:** gettext strings injected as `uiText` (`book-viewer.js:26-43`, `library.js:530`)

## Open points / caveats

- **The `book-ready` payload is not a defined schema.** It is whatever `JSON.stringify` produces for the foliate-js book object and the `Reader` wrapper, which holds a `<foliate-view>` element whose own fields serialise. A new Shell should depend only on the fields listed in §3.
- **The default data directory on macOS was not checked.** A GLib build on macOS would resolve `$XDG_DATA_HOME` to its own default, but that was not verified here. A native Swift Shell would choose its own directory anyway.
- **foliate-js was read from the main checkout**, since the submodule is uninitialised in this worktree. The pinned commit is `399248a6`.
