# Research: What dark mode recolours and what it leaves alone

Ticket: `.scratch/macos-port/issues/16-dark-mode-images-vs-figures.md`
Builds on: `.scratch/macos-port/issues/04-pdf-dark-mode.md` (findings on branch `research/pdf-dark-mode`, file `.scratch/macos-port/research/pdf-dark-mode.md`).
Date: 2026-11-06
foliate-js submodule commit read: `399248a67a8862ffb5e6463a33f9d52b317ca2eb` (vendored pdf.js 5.5.207).

Each claim is tagged with its source: a file and line in this repo, an upstream file at a pinned commit, or an experiment ("**Run:**"). Experiments ran in a WKWebView on macOS 26.7.1 (Intel), using the vendored `pdf.mjs` served over local HTTP, on a synthetic PDF built with Ghostscript. Nothing ran in WebKitGTK. The throwaway code was not committed.

## Answer

**The rule:** recolour ink, leave pictures alone.
- **Recolour (ink):** text, vector paths (rules, charts, diagrams), stencil masks (1-bit images painted in the current fill colour: scanned text, logos, Type3 glyphs), and pages that are mostly paper (scans of text).
- **Leave alone (pictures):** colour or greyscale raster images that look like photos or illustrations. Dim them slightly to cut glare.
- **Keep the hue:** the recolour should flip lightness but not hue, so a red curve stays red and a blue bar stays blue.

**PDF (Renderer, foliate-js `pdf.js`):** extend 04's blend-mode remap in two ways.
1. **Add a `color` blend pass** that draws the original page back over the inverted copy. That keeps hue and saturation while flipping lightness (**Run:** red stays red, blue stays blue). It costs one extra full-canvas `drawImage`.
2. **Put raster images back** using `recordOperations` bounding boxes, unchanged or slightly dimmed. Only the *raster* image operators count: stencil masks stay recoloured. Skip any image covering more than about half the page, so full-page scans get recoloured.

**Catch:** the operator *types* for those bounding boxes are only available in a private pdf.js field. The public `getOperatorList()` returns a differently optimised list whose indices don't line up (**Run:** 125 operations against 11 on the same page). Two ways round it:
- Read the private render list behind a guard, and skip image restoration if it's missing.
- Or classify pixels: downsample the page and flag "photo-like" tiles. This uses no pdf.js internals, also catches photos inside scanned pages, and costs about 11–18 ms a page (**Run**).

Either way, all of this lives in the Renderer, works the same in WebKitGTK and WKWebView, and costs well under one page render.

**Reflowable (Reader page CSS, `src/reader/reader.js` `getCSS`, plus an optional per-image check):**
- **Today it is wrong for line art.** Dark mode gives every element, `img` and `svg` included, an opaque theme background (`reader.js:143-147`). Black-ink transparent PNGs, GIFs and SVGs end up black on dark grey, close to invisible. Photos are shown unchanged at full brightness.
- **Recommended default:** leave photos alone and dim them slightly, as Firefox Reader View and Readium do (`brightness(.8)`). Recolour line art: images with transparency or few colours, and inline or `gaiji`-class images. Do it with a same-document SVG `feColorMatrix` filter that maps white to the theme's bg and black to its fg. **Run:** this works in WKWebView. The data-URL form of the filter reference does not.
- **Classifier:** a Chromium/Dark Reader–style check on a 32×32 sample (transparency ratio, colour-bucket count, lightness), run once per image on `load`.
- **User override:** one setting with three choices: images unchanged, smart (default), all inverted. It replaces neither the existing "Invert Colors in Dark Mode" toggle nor the current light-theme `multiply` trick.

**Prior art agrees on the parts, not the whole.** Zathura uses image bounding boxes to keep images (`recolor-reverse-video`), with no size cut-off. KOReader keeps EPUB images uninverted by default and offers a switch for "math or scene-break art". Okular and Sioyek recolour whole pages with no image exception. pdf.js `pageColors` posterises everything and is inert in WebKit anyway. Chromium's Auto Dark Mode and the Dark Reader extension have the most worked-out line-art heuristics.

## What Foliate does today

### PDF and other fixed-layout books (PDF, CBZ, pre-paginated EPUB)
- **No theme recolouring.** `FixedLayout` has no `setStyles`, so `renderer.setStyles?.()` in `Reader.setAppearance` does nothing for fixed layout (`src/reader/reader.js:302`; 04's findings). `pdf.js` renders with plain `page.render({ canvasContext, viewport })` (`src/foliate-js/pdf.js:28`). CBZ pages are a bare `<img>` in a blob document (`src/foliate-js/comic-book.js:8, 36`).
- **The only dark treatment is the "Invert Colors in Dark Mode" toggle** (`src/ui/book-viewer.ui:91-92`, `src/book-viewer.js:332-333`). In dark mode it applies `filter: invert(1) hue-rotate(180deg)` to every exported `filter` part (`src/reader/reader.html:29-32`). For fixed layout that means each page iframe (`src/foliate-js/fixed-layout.js:88`), so photos and comics turn into negatives with roughly the right hues.

### Reflowable books (EPUB, MOBI/KF8, FB2, …)
`getCSS()` (`src/reader/reader.js:51-163`) is injected through `paginator.setStyles` (`src/foliate-js/paginator.js:1100-1117`).
- **Light theme with a non-white background** (`reader.js:113-136`): every element gets `background-color: theme.light.bg !important`. `svg, img` instead get `background-color: transparent` plus `mix-blend-mode: multiply` (`reader.js:127-130`). The white parts of a JPEG figure therefore take on the paper colour, and photos are mildly tinted. This is the same idea as Readium's `--blend-filter` (see Prior art).
- **Dark theme, Invert off** (`reader.js:137-156`):
  - `body * { color: inherit !important; border-color: currentColor !important; background-color: <dark bg> !important }`.
  - There is **no `img`/`svg` exception**. Every `<img>` and `<svg>` gets an opaque dark background, and there is no blend mode or filter. Effects:
    - **Photos and opaque JPEG/PNG figures:** shown unchanged, as a bright white rectangle on a dark page. This is the glare request in [foliate#1263](https://github.com/johnfactotum/foliate/issues/1263).
    - **Transparent PNG/GIF line art with black ink** (equations, diagrams, gaiji, ornaments): black on the theme's dark bg (for example `#222222`, `src/themes.js:10`), so close to invisible. This follows from the CSS; it was not rendered.
    - **Inline SVG:** shapes using `fill="currentColor"` follow the theme fg through `color: inherit`. Hard-coded `fill="#000"` and SVG `<text>` with the default fill stay black and close to invisible. Readium handles the text case with `svg text { fill: currentColor }` (see Prior art); Foliate doesn't.
    - **CSS `background-image`s** are kept (only `background-color` is overridden).
- **Dark theme, Invert on:** the reflowable rules are skipped (`reader.js:138`). Text gets `theme.inverted` colours (`src/themes.js:110-113`) and the whole iframe and background are inverted by `reader.html:29-32`, which also targets `paginator.js:545` `#background part="filter"`. Images are double-handled: inverted, then hue-rotated. Line art reads correctly; photos become negatives.
- **Image sizing** only touches max size and `object-fit` (`paginator.js:341-360`). Images get no class or flag the CSS could use to tell kinds of image apart.
- **Image viewer:** the double-click viewer has its own invert toggle, `<ctrl>i` (`src/image-viewer.js:53`, `src/ui/image-viewer.ui:69-70`).

### Upstream
- **Foliate:**
  - [#1263](https://github.com/johnfactotum/foliate/issues/1263) (open): dim images in dark mode, citing Firefox, Epiphany and Tuba.
  - [#1315](https://github.com/johnfactotum/foliate/issues/1315) (open): syntax highlighting lost in non-default themes. This is the same `color: inherit !important` blanket.
  - [#1597](https://github.com/johnfactotum/foliate/issues/1597) (open): page colour independent of app theme.
  - Searches for "invert image", "image dark mode", "svg dark" and "transparent" found nothing else on images (searched 2026-11-06).
- **foliate-js:** no issue on dark-mode images (04's searches; rechecked 2026-11-06).

## PDF: telling pictures from ink

### What pdf.js 5.5.207 exposes

**Operators** (`pdf.mjs:281-325`, `OPS`).

Raster images:
- `paintImageXObject` (85)
- `paintInlineImageXObject` (86)
- `paintInlineImageXObjectGroup` (87)
- `paintImageXObjectRepeat` (88)

Stencil masks, which paint a 1-bit image in the current fill colour:
- `paintImageMaskXObject` (83)
- `paintImageMaskXObjectGroup` (84)
- `paintImageMaskXObjectRepeat` (89)
- `paintSolidColorImageMask` (90)

Ink:
- `constructPath` (91), for vector paths
- `showText` (44)
- `shadingFill` (62), for gradients

How they paint (`pdf.mjs:12216-12416`):
- **Stencil masks:** go through `_createMaskCanvas` and the fill colour (`pdf.mjs:12216-12232`, `12254-12287`). They behave like text. JBIG2 and CCITT bilevel scans, black-and-white logos and Type3 bitmap glyphs arrive this way, so they should be **recoloured**.
- **Transparent images:** an image with an SMask arrives as an RGBA bitmap through the same raster path. A transparent PNG-like diagram is therefore indistinguishable by operator from a photo. Only its pixels tell the two apart.
- **Transfer functions:** these use `ctx.filter` (`applyTransferMapsToCanvas` / `…ToBitmap`, `pdf.mjs:12322-12345`), so they are **already silently ignored in WebKit**. The **Run** below confirms `ctx.filter` is inert. This is a rare PDF feature, noted only because it is another `ctx.filter` dependency.

**`recordOperations`** (documented render option; `pdf.mjs:14866, 14895-14906`):
- **Lifetime:** the first render of a page with `recordOperations: true` stores `page.recordedBBoxes`, a `BBoxReader` (`pdf.mjs:9275-9300`). It is recorded **only once per page** (`!this.recordedBBoxes`, `pdf.mjs:14895`). Later zoom re-renders reuse it at no recording cost, which suits `onZoom` re-rendering on every layout (`fixed-layout.js:136-139`).
- **Shape:** boxes are axis-aligned, clipped to the current clip box (`recordBBox`, `pdf.mjs:9498-9513`), and **quantised to 1/256 of the canvas width and height**, rounded outward (`pdf.mjs:9588-9592`). A rotated image gives its enclosing rectangle. Restoring a box can therefore pull in a strip up to about 1/256 of the page of surrounding pixels (about 7–9 px on a 1836×2376 canvas). The **Run** output showed a thin light edge below the restored photo.
- **pdf.js's own use:** the viewer uses these boxes with `operationsFilter` to re-render only part of a page (`web/pdf_page_detail_view.js:190-221` @ v5.5.207). It indexes by operator position only and never needs operator types.

**Index trap:**
- **Why the lists differ:** `recordedBBoxes[i]` is indexed against the operator list of the *render* intent. That list is built with the `QueueOptimizer`. `page.getOperatorList()` adds the `OPLIST` flag (`pdf.mjs:14972-14977`, `15561-15562`), which switches the worker to the `NullOptimizer` (`pdf.worker.mjs:7029`). The optimiser folds runs of `save, transform, paint…, restore` into the group or repeat operators (`pdf.worker.mjs:6589, 6689, 6772`). For inline images and masks it does this from 10 in a row (`pdf.worker.mjs:6605, 6705`).
- **Run (page 3: 15 small stencil masks and 15 small inline colour images):** the render list has **11** operations, with `paintImageMaskXObject` ×1, `paintImageMaskXObjectRepeat` ×1 and `paintInlineImageXObjectGroup` ×1. `getOperatorList()` returns **125**, with `paintImageMaskXObject` ×15 and `paintInlineImageXObject` ×15. `recordedBBoxes.length` was 11. **Matching `getOperatorList().fnArray` against `recordedBBoxes` by index (04's suggestion) gives wrong answers on such pages.**
- **Run (page 1, no foldable runs):** both lists had 94 operations and matched. So the bug only shows on some pages.
- **Where the right list lives:** in `page._intentStates.get(cacheKey).operatorList.fnArray`, a private field (`pdf.mjs:14793`, `14885-14892`). The experiment read it through `[...page._intentStates.values()]`. Using it means guarding against its absence and re-checking on every pdf.js bump.

**Text layer:** `streamTextContent` gives text positions (`pdf.js:31-36`). It isn't needed to find images: text is ink and gets recoloured either way. One possible use is as a "this page has real text" signal, to tell a scanned page that has an OCR layer from a born-digital one.

### Options for PDFs

| | How | Fidelity | Cost per page (Run, WKWebView, 1836×2376 canvas) | WebKit | Lives in |
|---|---|---|---|---|---|
| **A. 04's remap, no image handling** | `difference` → `multiply(fg−bg)` → `lighter(bg)` | Text and line art get exact theme colours (**Run:** white→bg, black→fg exact). **Hues flip**: red→cyan, blue→orange. Photos become tinted negatives. | ~4 ms (2400×3200) | yes | Renderer |
| **B. A + keep hue** | After `difference`, `globalCompositeOperation='color'` and draw the pre-remap copy, then the tint steps | Lightness flips, hue and saturation kept (**Run:** red `rgb(204,26,26)` → `rgb(255,142,142)`, blue → light blue, greys unchanged). Same idea as Zathura `recolor-keephue` and Okular "Invert Lightness/Luma". Photos still negatives. | + one full-canvas `drawImage` (included in the 13–14 ms below) | `color` is a standard canvas blend mode. **Run:** works in WKWebView. Not run on WebKitGTK. | Renderer |
| **C. B + restore raster boxes** | `recordOperations`; for raster-image ops only (not masks), copy the box back from the pre-remap copy at ~85% alpha over the theme bg (dim); skip boxes over ~50% of the page | Photos keep their colours, dimmed. Stencil-mask scans, text and vectors recoloured. Full-page scans recoloured. Box quantisation leaves a thin halo. Text drawn *over* an image gets restored as original (dark on light), which is usually what you want. | 13–14 ms for remap and restore together; recording overhead lost in noise on this small page (cold render 43–54 ms plain, 61 ms recording) | yes | Renderer; needs `_intentStates` (private) for op types |
| **D. B + pixel tiles** | Downsample the canvas 8×, then per tile count 4-bit-per-channel colour buckets. Many buckets → photo tile, restore it | No pdf.js internals. Also handles photos *inside* scans and raster line art (few colours, gets recoloured). Tile edges are coarse (here 96×96 device px). Smooth gradients and screenshots can be misread. | 11–18 ms (classification), plus the remap. A full `getImageData` would be 44 ms at 7.7 MP, so downsample first. **Run** tile maps flagged exactly the photo region on page 1 and nothing on the scan page | yes (`getImageData` on a GPU canvas forces a readback) | Renderer |
| **E. C refined per image** | For each raster box, sample ≤1000 pixels of the copy and run a Chromium-style check: few colours or mostly paper → recolour; many colours → keep | Best: embedded PNG charts and diagrams get recoloured, photos are kept | + a small `getImageData` per image | yes | Renderer |
| pdf.js `pageColors` | built-in HCM filter at `endDrawing` (`pdf.mjs:11014-11038`) | 6-level posterisation of *everything*, images included | — | **Run: inert.** `'filter' in CanvasRenderingContext2D.prototype` is `false`. Assigning `ctx.filter='invert(1)'` only creates an expando and a white fill stays white, on detached and attached canvases alike. | Renderer |
| CSS invert (today) | `reader.html:29-32` | Everything inverted, photos as negatives | composite-time | yes | Shell CSS |

Notes:
- **Full-page scans:**
  - **Covered by one raster image** (**Run** page 2: one `paintImageXObject` with box `[0,0,1,1]`). Option C must recolour these (size cut-off). Zathura doesn't, see Prior art.
  - **Bilevel scans** (JBIG2/CCITT) are stencil masks or 1-bit images and recolour cleanly.
  - **Scans with a photo on the page** need option D or E to keep the photo.
- **Images under text:** the text is restored with the box under C. Under D a tile with text over a photo is still "photo". Both are acceptable.
- **Masks and SMasks:** handled by the operator split above. Soft-masked raster images are still "raster".
- **Highlights / overlayer:** unaffected. The text and annotation layers are DOM above the canvas (`pdf.js:31-66`).
- **Invert toggle:** turn the remap off while "Invert Colors in Dark Mode" is on, or the two stack (as in 04).

## Reflowable: telling pictures from line art

### What a book gives us
- **The element:** `<img>` (raster or SVG), inline `<svg>`, `<image>` inside SVG (cover wrappers), CSS `background-image`, MathML (text, so already themed by `color: inherit`).
- **Free hints:**
  - **Media type:** JPEG is almost always a photo or scan; PNG, GIF and SVG are often line art.
  - **Rendered size:** about one line height means inline maths, gaiji or ornaments.
  - **Class names:** Readium's `img[class*="gaiji"]`.
  - EPUB has no standard "line art" marker.
- **Pixels:** book resources load from same-origin `blob:` URLs, so drawing them to a canvas should not taint it. Not run. SVG-as-image drawn to canvas was not checked either.

### Options for reflowable

| | Fidelity | Cost | WebKit | Lives in |
|---|---|---|---|---|
| **R0. Today** | Photos: full glare. Transparent line art: close to invisible (opaque dark `background-color` under black ink). | none | yes | Reader page CSS |
| **R1. Leave alone + dim** (`img { filter: brightness(.8) }` in dark; drop the opaque bg on `img, svg`, i.e. `background-color: transparent`) | Photos dimmed (Firefox Reader View / Readium default). Transparent line art is still black on dark, so still unreadable. | composite-time | yes | Reader page CSS |
| **R2. Opaque light backing for transparent images** (`img { background: #fff }` or the light theme bg) | Line art readable as a light card on a dark page (Apple's advice amounts to this, see Prior art). Glare. | none | yes | CSS |
| **R3. Recolour everything** (`filter: invert(1) hue-rotate(180deg)` on `img`) | Line art correct; photos negatives. KOReader's "Invert Images: off" case. | composite-time | yes | CSS |
| **R4. Exact theme duotone for line art** (inject `<svg><filter><feColorMatrix>` into the book document and use `filter: url(#id)`) | Maps luminance to theme fg/bg exactly (**Run:** white → `#222222` exactly) | composite-time; SVG filters may take a software path | **Run:** works in WKWebView with a **same-document** filter. A `data:` URL filter reference is **ignored** (element stays white). Not run on WebKitGTK. | Reader page (injects into the book document) |
| **R5. Classify per image, then R1 or R4** | Photos kept and dimmed, line art recoloured | One ≤32×32 `drawImage` + `getImageData` per image, once, on load | yes | Reader page (`#onLoad`, `reader.js:372-375`) or a foliate-js hook |

**A line-art check for R5,** pieced together from the prior art below. Run it on a ≤32×32 downsample and stop at the first rule that matches.
1. **Mostly transparent** (≥10% of pixels with alpha < 0.05):
   - Mostly dark ink → recolour.
   - Mostly light ink → leave alone; it is already visible on dark.
2. **Few colours** (Chromium: under ~0.8 of the 16 grey buckets, or under ~1.5% of the 4096 colour buckets) **and mostly light** → line art on white paper → recolour.
3. **Many colours** → photo → leave alone, dim.
4. **Few colours but strongly saturated** → a colour chart or icon → leave alone, or recolour with the hue kept.
5. **Rendered height ≤ ~1.5em, or class contains `gaiji`** → recolour (inline glyph or maths).
6. **Escape hatch:** the user setting (unchanged / smart / invert all), as KOReader and Readium offer.

## Prior art

- **pdf.js `pageColors`** (5.5.207):
  - A whole-canvas SVG filter after drawing (`pdf.mjs:11029-11038`). No image exception in 5.5.207: the per-image `ctx.filter = "none"` reset in `paintInlineImageXObject` (`pdf.mjs:12353-12358`) is a no-op, because the filter is applied only at `endDrawing`.
  - The Firefox viewer uses it only in forced-colours (high-contrast) mode or with the `forcePageColors` pref (`web/app.js:454-463` @ v5.5.207; defaults `Canvas`/`CanvasText`, `web/app_options.js:336-350`). It is not a dark theme.
- **Firefox Reader View:** dark and contrast themes apply `filter: brightness(0.8) contrast(1.2)` to `.moz-reader-block-img` (`toolkit/themes/shared/aboutReader.css:95-114`). It adds the class to block images (`toolkit/components/reader/AboutReader.sys.mjs:1319-1324`). Images are dimmed, never inverted. (mozilla-firefox/firefox @ `4ae5875878e4`.)
- **Okular:**
  - Accessibility "Change colors" modes (`conf/okular_core.kcfg:53-67`): Inverted (the default), Paper, Recolor, BlackWhite, InvertLightness, InvertLuma, InvertLumaSymmetric, HueShift±.
  - Each is applied to the whole page pixmap (`gui/pagepainter.cpp:290-318`) with **no image exception**. Highlights switch to `Difference` compositing in Inverted/Recolor (`pagepainter.cpp:321-337`).
  - Source: KDE/okular @ `0bc4d80e6df9`.
- **Zathura:**
  - `recolor` with `recolor-lightcolor/darkcolor`, `recolor-keephue` (hue-preserving) and `recolor-reverse-video` ("Defines if original image colors should be kept while recoloring", `doc/man/zathurarc.5.rst:889-893`).
  - With reverse-video, `recolor()` asks the backend for the page's image rectangles (`zathura_page_images_get`) and skips every pixel inside them (`zathura/render.c:715-778, 565-573`).
  - **No size cut-off,** so a scanned page stays unrecoloured.
  - Source: pwmt/zathura @ `6889036e71c7`.
- **Sioyek:**
  - Dark mode is a fragment shader over the whole page texture: invert, contrast, hue +180° (`pdf_viewer/shaders/dark_mode.fragment`).
  - Custom colours use a 4×4 colour matrix (`custom_colors.fragment`).
  - **No image exception.**
  - Source: ahrm/sioyek @ `1e2f8037`.
- **KOReader:**
  - **EPUB (crengine):** night mode inverts the screen. By default crengine pre-inverts images, so they show in their original colours (`frontend/document/credocument.lua:827-835`). The "Invert Images" option exists to turn that off: "Useful if your book contains mainly inlined mathematical content or scene break art" (`frontend/ui/data/creoptions.lua:736-748`).
  - **PDF/DjVu:** whole-page only. "Invert Document… Useful for image-heavy documents such as comics or manga" (`frontend/ui/data/koptoptions.lua:699-707`; `frontend/document/koptinterface.lua:591-619`).
  - Source: koreader/koreader @ `ddfc91fd9cc7`.
- **Apple Books** (Asset Guide, "Interior Image Requirements"):
  - "In night mode, the transparent areas of an image are black… If your image has dark text within a transparent image, that text could be difficult to read in night mode. Instead, we suggest you use a JPEG with a white background." Gaiji "should have transparent backgrounds for optimum display across themes" ([help.apple.com](https://help.apple.com/itc/booksassetguide/en.lproj/itca71ad3c33.html), fetched 2026-11-06).
  - So Apple Books leaves images as they are and puts the burden on publishers. The guide doesn't say outright that images are never inverted.
- **Readium CSS:**
  - Flags, all opt-in user settings, not automatic:
    - `--USER__darkenImages` (`brightness(80%)`)
    - `--USER__invertImages` (`invert(100%)`)
    - `--USER__invertGaiji` (`img[class*="gaiji"]` only)
    - `--blend-filter` (`mix-blend-mode: multiply` with a transparent background on `img, svg`)
  - Source: `css/src/modules/user-settings-submodules/ReadiumCSS-imageFilters_pref.css:9-73`.
  - Its custom colours set `svg text { fill: currentColor }` (`ReadiumCSS-customColors_pref.css:27-30`).
  - Source: readium/readium-css @ `803fea474b3c`.
- **Chromium Auto Dark Mode:**
  - `DarkModeImageClassifier` samples ≤1000 pixels in a ≤10×10 block grid (`dark_mode_image_classifier.cc:20-22`).
  - Features: transparency ratio, background ratio, 4-bit colour-bucket ratio, high-luminance, saturated and chromatic ratios.
  - Decision tree (`:354-415`; neural-net fallback `:327-352`):
    - Transparent with a light foreground → don't invert.
    - Few saturated colours → don't invert.
    - Few colours → invert.
    - Many colours → photo, don't invert.
    - Anything in between goes to a small neural net.
  - Source: chromium/chromium @ `210a781e7b79` (2026-05-24).
- **Dark Reader extension:**
  - Analyses images (CSS backgrounds) on a ≤32×32 downsample (`src/inject/dynamic-theme/image.ts:122, 141-258`), producing `isDark`, `isLight`, `isTransparent` and `isLarge` (>512×512).
  - Rules (`modify-css.ts:592-631`):
    - Large, light and opaque → hide.
    - Dark and transparent → invert.
    - Light and opaque → invert.
    - Otherwise → leave alone.
  - Source: darkreader/darkreader @ `16315ce11428`.

## WebKit support summary
- **Canvas `ctx.filter`: not available.** **Run** on WKWebView, macOS 26.7.1: it is not in the prototype and has no effect, which confirms 04's inference. pdf.js `pageColors` and pdf.js transfer functions are therefore inert.
- **Canvas `globalCompositeOperation`** `difference`, `multiply`, `lighter` and `color`: **Run** gives correct results in WKWebView. These are standard modes and should hold in WebKitGTK; not run there.
- **CSS `filter`** functions and same-document `url(#svgFilter)` on HTML elements: work (**Run**). `data:` URL filter references are ignored (**Run**).
- **`getImageData`:** works. Cost: 44 ms for a full 2400×3200 readback, ~11–18 ms for an 8× downsample plus tile classification (**Run**).

## Not verified
- Nothing was run in WebKitGTK. All **Run** results are WKWebView on macOS 26.7.1, Intel.
- Timings come from one synthetic Ghostscript PDF and single runs. The `recordOperations` overhead on heavy real-world pages is not measured.
- How tight the bounding boxes are around clipped, rotated or soft-masked images in real PDFs. Quantisation is known from the code.
- Whether `page._intentStates` stays shaped the same in later pdf.js releases.
- Canvas tainting for `blob:` SVG and raster images in the book iframe; the R5 classifier relies on it not happening.
- The reflowable failure modes (invisible transparent line art, glaring photos) are read from the CSS. No book was rendered.
- The classifier thresholds above are borrowed from Chromium and Dark Reader and were not tuned on books.
