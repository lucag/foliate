# Research: What dark mode recolours and what it leaves alone

Type: research
Status: resolved
Map: ../map.md

## Question

`04-pdf-dark-mode.md` chose recolouring PDF pages in the Renderer, and mentioned only as an option keeping raster images un-inverted using pdf.js `recordOperations` bounding boxes. Which parts of a page should dark mode recolour, and how can the Renderer tell them apart, for both PDFs and reflowable books (EPUB and the other Renderer formats)?

- **PDF:** how to tell raster photos from vector figures (charts, diagrams, line art) and from text; what pdf.js (vendored 5.5.207) exposes for this (operator lists, `paintImageXObject` and friends, `recordOperations` bounding boxes, the text layer); how full-page scans, images under text, masks and transparent images behave; the cost per page.
- **Reflowable:** what Foliate and foliate-js do today with `<img>`, SVG and CSS backgrounds in dark themes (`src/themes.js`, `src/reader/`, foliate-js `paginator.js` and the style hooks, the "Invert Colors in Dark Mode" filter at `src/reader/reader.html:29-32`); options such as leaving images alone, dimming them, inverting only line art or transparent images, and heuristics (transparency, colour count, size) for spotting line art.
- **Prior art:** what pdf.js `pageColors`, Firefox Reader View, Okular, Zathura, Sioyek, KOReader, Apple Books and Readium do, from their source or docs; and any upstream Foliate or foliate-js issues.
- For each option: fidelity, cost, WebKit support in both WebKitGTK and WKWebView (canvas `ctx.filter` is off in WebKit, see `04`), and whether it lives in the Renderer so Linux gets it too.

## Context

Findings: branch `research/dark-mode-images-vs-figures`, commit `4fa7d83`, file `.scratch/macos-port/research/dark-mode-images-vs-figures.md`. Experiments ran in a WKWebView on macOS 26.7.1 (Intel) with the vendored pdf.js.

## Answer

**Recolour ink, leave pictures alone, and keep the hue.** Text, vector paths (rules, charts, diagrams), 1-bit stencil images and pages that are mostly paper (scanned text) get recoloured. Photos and illustrations stay as they are, dimmed a little. Lightness flips but hue doesn't, so a red curve stays red. It all lives in shared code, so Linux gets it too: foliate-js for PDFs, the Reader page for reflowable books. A setting offers images unchanged / smart (default) / all inverted.

**PDF (foliate-js `pdf.js`)**
- **Keep the hue:** `04-pdf-dark-mode.md`'s blend-mode recolour flips hues (red turned cyan in the test). Drawing the original page back with `globalCompositeOperation = 'color'` after the `difference` fill fixes it.
- **Put photos back:** after recolouring, copy raster images back from the original at about 85%. Count only `paintImageXObject` / `paintInlineImageXObject` and their group and repeat forms, not stencils, which pdf.js paints in the fill colour (`pdf.mjs:12216-12287`). Skip images covering more than about half the page, so scans still get recoloured.
- **Correction to `04`:** `page.recordedBBoxes` is indexed against the render's own merged operator list, not the one `getOperatorList()` returns (125 against 11 operations on a test page; `pdf.mjs:14972-14977,15561`, `pdf.worker.mjs:7029`). The render's list is only in the private `page._intentStates`. Two ways round it:
  - read the private list behind a guard, and skip restoring photos if it's missing;
  - or detect photos from pixels: shrink the page 8× and flag tiles with many colours. This uses no pdf.js internals, also finds photos inside scans, and cost 11–18 ms a page.
- **Cost:** about 13–14 ms a page for recolour plus restore at 1836×2376, against 43–61 ms to render. Boxes are rounded outward to 1/256 of the canvas (`pdf.mjs:9588-9592`), which leaves a thin halo round restored photos.
- **Confirmed:** `pageColors` stays ruled out. Canvas `ctx.filter` does nothing in WKWebView.

**Reflowable (`src/reader/reader.js` `getCSS`)**
- **Today:** dark mode puts an opaque theme background on every element, `img` and `svg` included (`reader.js:143-147`). Black-ink transparent PNG, GIF and SVG images end up nearly invisible, and photos glare (foliate#1263). SVG with a hard-coded black fill stays black. Light themes' `mix-blend-mode: multiply` on images (`reader.js:127-130`) stays.
- **Recommended:**
  - Drop the opaque background on `img, svg`.
  - Dim photos with `filter: brightness(.8)`, as Firefox Reader View and Readium do.
  - Recolour line art to the exact theme colours with an SVG colour-matrix filter placed in the book's document. A data-URL version of the filter was ignored.
  - Add `svg text { fill: currentColor }`.
- **Spotting line art:** on each image's load (`reader.js:372-375`), check a 32×32 sample:
  - mostly transparent with dark ink → recolour;
  - few colours and mostly light → recolour;
  - many colours → photo, dim only;
  - few but strongly saturated colours → leave alone;
  - about one line high, or a `gaiji` class → recolour.

  The thresholds are borrowed from Chromium and Dark Reader.

**Prior art**
- Zathura keeps image areas with no size cut-off (`render.c:715-778`).
- KOReader keeps EPUB image colours, with an opt-out, and inverts whole PDF pages (`creoptions.lua:736-748`).
- Okular and Sioyek recolour whole pages.
- Apple Books leaves images alone.
- Readium has opt-in darken and invert, and `gaiji` invert.
- Firefox Reader View uses `brightness(.8) contrast(1.2)`.

**Not verified:** anything in WebKitGTK; timings beyond single runs on one synthetic PDF; whether `_intentStates` keeps its shape in later pdf.js releases; how tight bounding boxes are for clipped, rotated or masked images; whether `blob:` book images can be read from a canvas (the line-art check needs it); reflowable behaviour in a real book; thresholds tuned on books.
