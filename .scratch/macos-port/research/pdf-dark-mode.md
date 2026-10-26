# Research: PDF dark mode in the Renderer

Ticket: `.scratch/macos-port/issues/04-pdf-dark-mode.md`
Date: 2026-10-25
foliate-js submodule commit read: `399248a67a8862ffb5e6463a33f9d52b317ca2eb` (vendored pdf.js **5.5.207**, build `527964698`; header of `src/foliate-js/vendor/pdfjs/pdf.mjs` lines 24-25; upstream commit "Update PDF.js to 5.5.207", [foliate-js@1217096](https://github.com/johnfactotum/foliate-js/commit/1217096245004b1e8ca369367e883f3db37c88cf)).

Nothing here was run in a live WebView. Fidelity and cost notes come from reading the code and specs. Each claim is tagged with its source.

## Answer

Recommended: **per-page canvas compositing in foliate-js `pdf.js`**, i.e. in the Renderer. After `page.render()` finishes, remap the page bitmap to the theme's fg/bg with two or three full-canvas `fillRect` calls using the `difference`, `multiply` and `lighter` blend modes. For dark themes, optionally put image regions back using pdf.js's documented `recordOperations` bounding boxes. Because this lives in the Renderer it works the same on Linux (WebKitGTK) and on any macOS WebView, and the text and annotation layers stay untouched.

pdf.js's `pageColors` is in the vendored 5.5.207, but **it does nothing in WebKit**: it relies on `CanvasRenderingContext2D.filter`, which WebKit still ships off by default. Even where it works, it turns the page, images included, into a 6-level duotone.

The CSS `invert(1) hue-rotate(180deg)` filter **already exists** in the Shell as "Invert Colors in Dark Mode" and already reaches PDF pages. Keep it as the cheap fallback. It cannot follow the theme's colours and it inverts images.

## How the Shell passes theme colours today

- **Theme data.** `src/themes.js` defines `themes[]`, each with `light`/`dark` `{fg, bg, link}`, plus user JSON themes from the `themes` config dir (lines 6-75). `invertTheme()` (line 110) adds an `inverted` fg/link computed with `utils.invertColor` = invert + hue-rotate 180 (`src/utils.js:390`).
- **Shell to WebView.** `src/book-viewer.js:318-339` resolves the selected theme and calls `this.#exec('reader.setAppearance', { layout, style: { …, invert, theme }, autohideCursor })`.
- **WebView side (`src/reader/reader.js:285-306`, `Reader.setAppearance`):**
  - It sets the CSS variables `--light-bg/fg` and `--dark-bg/fg` on the reader page. `reader.html` uses them for the page body (`reader.html:6-28`), so **the area around PDF pages already follows the theme**.
  - It calls `renderer.setStyles?.(getCSS(this.style))`. `getCSS` (`reader.js:51+`) produces a CSS string injected into reflowable book documents (`html { color; background-color }` rules, etc.).
  - **`FixedLayout` has no `setStyles`** (`src/foliate-js/fixed-layout.js`, whole file), so the optional call is a no-op for PDFs/FXL. PDF pages never receive the theme.
  - It toggles `body.invert`. In dark mode, `reader.html:29-32` then applies `.invert foliate-view::part(filter) { color-scheme: light; filter: invert(1) hue-rotate(180deg) }`.
- **The invert filter reaches PDFs.** `FixedLayout` sets `part="filter"` on every page iframe (`fixed-layout.js:88`), and `View` re-exports it (`renderer.setAttribute('exportparts', 'head,foot,filter')`, `view.js:259`). So the existing invert toggle already applies to PDF pages, in dark mode only, as a whole-iframe invert.
- **How a PDF page is built.** `pdf.js` `renderPage()` returns `{ src, onZoom }` (`pdf.js:69-107`). `FixedLayout.#render()` calls `onZoom({ doc, scale })` on **every** layout pass (`fixed-layout.js:135-139`). That re-runs `render()`, which rasterises into a new `<canvas>` with `page.render({ canvasContext, viewport })` (`pdf.js:15-29`) and then builds the text layer and annotation layer over it. The page HTML has no background of its own. The canvas is opaque because pdf.js fills it with `background || "#ffffff"` (`pdf.mjs:10925`).
- **No highlight overlays on PDFs yet.** `FixedLayout` never dispatches `create-overlayer`, and `getContents()` has `// TODO: index, overlayer` (`fixed-layout.js:308-313`), so `View.addAnnotation` finds no overlayer for PDF pages (`view.js:262-263, 400-404`). For PDFs, "highlights" today means only the text-layer `::selection`. Any future overlayer will be an SVG in the iframe, outside the canvas.

## Option 1: pdf.js `pageColors` render option

**Supported by the vendored version?** Yes. `PDFPageProxy.render({ …, background, pageColors, recordOperations, operationsFilter })` (`pdf.mjs:14853-14868`). The JSDoc says pageColors "Overwrites background and foreground colors with user defined ones in order to improve readability in high contrast mode". It also notes that `background` "may be partially, or completely, ignored when the `pageColors`-option is used" ([api.js @ v5.5.207, lines 1251-1262](https://github.com/mozilla/pdf.js/blob/v5.5.207/src/display/api.js#L1251-L1262)). The value is `{ foreground, background }` CSS colours.

**How it works in 5.5.207.** It is not per-operator colour substitution. At `endDrawing()`, `CanvasGraphics.#drawFilter()` sets `ctx.filter = url(#hcm)` and redraws the whole canvas onto itself (`pdf.mjs:11014-11038`; also after each annotation canvas, `pdf.mjs:12207-12214`). `DOMFilterFactory.addHCMFilter` builds that SVG filter (`pdf.mjs:8943-8996`) in three steps:
1. sRGB to linear transfer.
2. Luminance to grey `feColorMatrix` (0.2126/0.7152/0.0722).
3. `feComponentTransfer` with `type="discrete"` (`pdf.mjs` `#appendFeFunc`) over 6 steps from fg to bg.

The filter is skipped entirely when fg/bg is `#000000`/`#ffffff`.

**Fidelity.** Every pixel, images and vector colour included, becomes one of **6 posterised tones** between fg and bg. Text contrast is good. Photos, charts and coloured diagrams lose all hue and most tonal detail. The text layer and annotation layer are separate DOM and unaffected.

**WebKit blocker.** The mechanism needs `CanvasRenderingContext2D.filter`, which WebKit does not enable:
- `CanvasFiltersEnabled` has `status: testable`, `defaultValue: false` in WebKit `main` ([UnifiedWebPreferences.yaml](https://github.com/WebKit/WebKit/blob/main/Source/WTF/Scripts/Preferences/UnifiedWebPreferences.yaml), fetched 2026-10-25).
- caniuse lists Safari 18.0 through 27.x as "disabled by default" ([caniuse](https://caniuse.com/mdn-api_canvasrenderingcontext2d_filter)).
- The implementation landed behind that flag in 278000@main ([WebKit bug 198416](https://bugs.webkit.org/show_bug.cgi?id=198416)).
- There is a related bug: filter stays `none` on canvases not attached to a document ([WebKit bug 276135](https://bugs.webkit.org/show_bug.cgi?id=276135)). That matters here because `pdf.js` renders into a detached `document.createElement('canvas')` (`pdf.js:24`).

So in WebKitGTK and in WKWebView the `ctx.filter = …` assignment has no effect, and `pageColors` silently yields an unchanged page (inferred from the code path, not run).

The flag can be turned on:
- **WebKitGTK:** `webkit_settings_set_feature_enabled()` (since 2.42, [docs](https://webkitgtk.org/reference/webkitgtk/stable/method.Settings.set_feature_enabled.html)). The docs describe TESTABLE features as "may not be yet ready to ship" ([WebKitFeatureStatus](https://webkitgtk.org/reference/webkitgtk/stable/enum.FeatureStatus.html)).
- **WKWebView:** only through private SPI. Not verified; it would need its own check.

**Cost.** One extra full-canvas filtered `drawImage` per render. Cheap where supported.
**Where it lives.** Renderer (`pdf.js` `render()`). It would need fg/bg passed in.
**Verdict.** Not usable: a silent no-op on both target engines, and it degrades images badly where it does work.

## Option 2: CSS filter (invert + hue-rotate) on the page iframe/canvas

**Status.** Already implemented and shipping (see "How the Shell passes theme colours today" above). It is Shell-side CSS in `src/reader/reader.html` that targets the Renderer's exported `filter` part.

**Fidelity.**
- **Images:** inverted luminance. `hue-rotate(180deg)` only restores approximate hue, so photos look like negatives with roughly correct hues.
- **Colours:** maps white to black and black to white, not to the theme's `bg`/`fg`. Sepia, Solarized and similar themes cannot be honoured. Foliate works around this for reflowable text by passing `theme.inverted` colours (`themes.js:110-113`), but nothing equivalent happens for PDF pixels.
- **Text layer and selection:** the filter applies to the whole iframe, so selection colours and the annotation layer are inverted too. Today's `reader.html:29-32` needs `color-scheme: light` to keep the iframe background transparent.
- **Highlights:** any future overlayer drawn inside the iframe would also be inverted. That interacts badly with `--overlayer-highlight-blend-mode: screen` in dark mode (`reader.html:36-43`).

**Variant.** A CSS `filter: url(#duotone)` pointing at an inline SVG `feColorMatrix`/`feComponentTransfer` could map to the exact theme colours. Its image fidelity matches `pageColors`, or is better if not posterised. Image regions still get mangled.

**Cost.** The filter is applied at paint/composite time, on every repaint, scroll and zoom, rather than once per raster. `invert`/`hue-rotate` are simple. SVG reference filters are generally a software path in WebKit. Not measured.
**Where it lives.** Shell stylesheet. It works on any WebKit port without Renderer changes, which is why it is the easiest fallback.
**Verdict.** Keep as-is for the "invert" toggle. It is not a way to make PDFs follow the theme's colours.

## Option 3: per-page compositing in foliate-js `pdf.js` (recommended)

**Mechanism.** In `pdf.js` `render()`, after `await page.render(...)` (`pdf.js:28`) and before the canvas is adopted into the iframe, remap the bitmap with Canvas 2D blend modes. All of these have been Baseline since 2015 and work in WebKit ([MDN globalCompositeOperation](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/globalCompositeOperation)). Each channel gets a linear map *c → fg + c·(bg − fg)*, so white becomes bg and black becomes fg:
- **Light themes (bg lighter than fg per channel):**
  1. `multiply` fill with `(bg − fg)`.
  2. `lighter` (additive) fill with `fg`.
- **Dark themes (bg darker than fg):**
  1. `difference` fill with `#fff`, which inverts the bitmap.
  2. `multiply` fill with `(fg − bg)`.
  3. `lighter` fill with `bg`.
- **Mixed-sign channels** (rare: a theme whose fg is lighter than bg in one channel and darker in another): pick the dominant direction by luminance and accept a small error. A `getImageData` pixel loop is an exact alternative, at a higher cost.

**Restoring images in dark mode.**
1. Render with `recordOperations: true`. pdf.js then stores `page.recordedBBoxes`, a `BBoxReader` holding normalised [0,1] per-operator bounding boxes (`pdf.mjs:9275-9300, 9653-9656, 14895-14906`). This option is documented: "Record the dependencies and bounding boxes of all PDF operations that render onto the canvas" ([api.js @ v5.5.207, lines 1272-1273](https://github.com/mozilla/pdf.js/blob/v5.5.207/src/display/api.js#L1272-L1273)).
2. Find the image operations by matching `page.getOperatorList().fnArray` against `pdfjsLib.OPS.paintImageXObject` / `paintInlineImageXObject` / `paintImageMaskXObject` (`pdf.mjs:12288, 12346`).
3. Copy those rectangles back from a pre-remap copy of the canvas, optionally dimmed to reduce glare (the request in [foliate#1263](https://github.com/johnfactotum/foliate/issues/1263)).

The documented `operationsFilter` (`api.js` lines 1274-1280) would allow an images-only second pass instead of a copy. Both are newer APIs; check them on each pdf.js bump.

**Fidelity.**
- **Text and vector art:** exact theme fg/bg, anti-aliasing kept (linear map).
- **Light-theme images:** a mild "paper" contrast stretch toward fg/bg; colour is kept.
- **Dark-theme images:** inverted unless restored. With restoration they look the same as on screen today.
- **Text layer and annotation layer:** untouched DOM over the canvas. Selection and link hit-areas stay correct, and a future overlayer SVG sits above the canvas unfiltered.
- **Edge case:** a full-page scanned PDF is one big image. Restoration would leave it white. Use a size heuristic, for example skip restoring images that cover more than ~80% of the page, so scans get remapped too.

**Cost.**
- Two or three full-canvas `fillRect` calls per render: negligible next to PDF rasterisation, and GPU-backed where the canvas is accelerated.
- `render()` already re-rasterises on every `FixedLayout.#render()`, so there is no new invalidation path.
- Image restoration adds one same-size scratch canvas, roughly 4 bytes × page pixels (for example about 30 MB at 2× DPR on a large page) for as long as the render runs.
- `recordOperations` adds bbox tracking during rendering (internal `CanvasDependencyTracker`). Not measured.

**Where it lives.**
- The pixel work is in the Renderer (foliate-js `pdf.js`), so Linux and the macOS Shell both benefit and the Shell–Renderer contract only needs colours.
- **Plumbing needed.** `renderPage()`'s `onZoom` would take `{ doc, scale, colors }`. `FixedLayout` would need a colour setter that stores `{fg, bg}` and calls `this.#render()`. That re-invokes `onZoom` for the visible pages, and the `makePDF` cache keeps `{src, onZoom}`, so a theme change re-renders without reloading.
- The Shell side is one call from `Reader.setAppearance` (`reader.js:285-306`) next to the existing `renderer.setStyles?.(…)`, passing the light or dark theme colours already resolved there. It should choose light or dark the same way `prefers-color-scheme` does in `reader.html`.
- The new FXL renderer API (for example `setColors` or an attribute) is a Renderer change that would ideally go upstream.
- **Interaction with Invert.** Disable compositing when `invert` is on, or the two transforms stack.

## Upstream status

- **foliate-js:** no issue or PR about PDF dark mode, theme colours or `pageColors`. Searched 2026-10-25:
  - Issues: `repo:johnfactotum/foliate-js is:issue dark OR theme OR invert OR color` returns 8 hits, none about PDF colours. The closest is [#58 "Default background colors?"](https://github.com/johnfactotum/foliate-js/issues/58), about EPUB.
  - PRs: `repo:johnfactotum/foliate-js pdf` returns 21. They cover layout, search, TTS, flash, scroll and annotations ([#141](https://github.com/johnfactotum/foliate-js/pull/141), [#155](https://github.com/johnfactotum/foliate-js/pull/155), [#136](https://github.com/johnfactotum/foliate-js/pull/136), etc.). None touch colours.
  - The last `pdf.js` commit upstream is the 5.5.207 bump ([1217096](https://github.com/johnfactotum/foliate-js/commit/1217096245004b1e8ca369367e883f3db37c88cf)). `grep pageColors src/foliate-js/*.js` finds nothing.
- **Foliate:** no issue that specifically asks for PDFs to follow the theme. Related:
  - [#1263](https://github.com/johnfactotum/foliate/issues/1263): dim images in dark mode.
  - [#1597](https://github.com/johnfactotum/foliate/issues/1597): page colour independent of the app theme.
  - [#1598](https://github.com/johnfactotum/foliate/issues/1598): white flash on PDF/CBZ page change. This is relevant because the opaque white canvas and the empty iframe show before the remap. A themed `render({ background })` or an iframe background would hide it.
  - [#1331](https://github.com/johnfactotum/foliate/issues/1331): high-contrast dark theme.

## Open questions / not verified

- Runtime check that `ctx.filter` really is inert in the shipped WebKitGTK (2.4x/2.5x) and WKWebView builds. The conclusion rests on the WebKit preference default and caniuse, not on a run.
- Cost of `recordOperations` on heavy pages, and whether its bboxes are tight enough around clipped or rotated images.
- Whether WKWebView exposes `CanvasFiltersEnabled` other than through private SPI.
