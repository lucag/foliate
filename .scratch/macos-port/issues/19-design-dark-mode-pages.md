# Prototype: How dark-mode pages look

Type: prototype
Status: resolved
Map: ../map.md

## Question

`16-dark-mode-images-vs-figures.md` recommends recolouring ink, leaving pictures dimmed, and keeping hue, for PDFs and reflowable books. Make it concrete enough to judge. Render the same pages in each option, in a few dark themes (Default dark, Sepia dark, Nord):
- a text PDF with a colour chart and a photo; a scanned PDF; an EPUB with a photo, transparent black line art, an SVG diagram and a `gaiji`-style inline image;
- options: today's behaviour, the "Invert Colors" filter, recolour-all, smart (with photos restored from the private operator list *and* from pixel detection), and photo dimming at 100/85/80%.

Settle:
- which option is the default, and whether the images unchanged / smart / all-inverted setting is exposed, and where (the Aa popover, `09-design-reader-window.md`);
- the PDF photo-detection method;
- the dimming level;
- whether the "Invert Colors in Dark Mode" toggle stays;
- whether the halo round restored photos is acceptable.

The prototype runs in WKWebView. Note what needs checking again in WebKitGTK. Renderer changes go on the fork (`11-foliate-js-upstream-or-fork.md`).

## Context

Prototype: branch `prototype/dark-mode-pages` (commit `f7da4ff`), `macos/prototype-dark-mode/`. Run `macos/prototype-dark-mode/run.sh` to open it in a WKWebView. It renders a text PDF, a scanned PDF and an EPUB chapter under each option, in Default, Sepia and Nord dark, with photo dimming at 100/85/80%.

## Answer

**Smart is the default, and the reader can change it.** Text, vectors, line art and scans are recoloured to the theme with the hue kept. Photos are put back, dimmed.

- **PDF smart = both detection methods together:**
  - **Operator list:** raster images found through pdf.js's private render operator list, guarded as in `16-dark-mode-images-vs-figures.md`.
  - **Pixel detection:** photo tiles found by pixel detection where there is no operator box, for example a photo inside a scanned page, or when the private list is missing. Detection is:
    - 4× downsample, 16-px tiles;
    - "paper" is the page's most common colour;
    - gaps between photo tiles are filled;
    - each connected group of tiles is restored as one rectangle;
    - the rectangle grows line by line until a line is mostly paper, so captions stay out.
  - **Cost:** about 20–40 ms a page on the test pages, against about 170 ms to render.
- **EPUB smart:** the per-image 32×32 check from `16`:
  - line art, gaiji and inline SVG are recoloured through a same-document SVG filter (invert, hue-rotate 180°, map to the theme's fg/bg);
  - photos are dimmed with `filter: brightness()`;
  - the opaque background on `img, svg` goes.
- **No halo.** The light frame round photos restored from operator boxes was ruled unacceptable. Each box is trimmed at full resolution:
  - **Operator boxes:** edge lines matching the paper colour are shaved off, up to the 1/256-of-the-canvas rounding pdf.js adds. On the test page that removed 9×13 px and the frame, with the photo intact.
  - **Pixel regions:** trimmed by lightness, up to one 4-px cell, then inset 2 px.
- **Setting: Images in Dark Mode: Original / Smart / Invert.** It sits in both the Aa popover (as a row) and View › Images in Dark Mode ▸.
  - **Original:** text and vectors are recoloured, every picture is shown as in the book (dimmed), and PDF scans are put back too.
  - **Smart:** the default.
  - **Invert:** today's "Invert Colors in Dark Mode" (`invert(1) hue-rotate(180deg)` on the whole page). The separate toggle goes on macOS and becomes this choice.
- **Photo dimming is the reader's choice:** 100% (none), 85% or 80%, next to the Images setting. The default is 85% (from `16`; the user didn't set one).
- **Charts are an option:** a "Recolour Charts" switch, off by default. It decides whether raster images with few, strongly saturated colours are recoloured with the hue kept or kept as they are (dimmed). It applies wherever a raster image is classified: EPUB images, and PDF images from operator boxes, which get the same per-image check (option E in `16`). Vector charts in PDFs are always recoloured with the hue kept.
- **Where it lives:** the PDF part goes in foliate-js `pdf.js` on the fork (`11-foliate-js-upstream-or-fork.md`). The EPUB part goes in the Reader page (`src/reader/reader.js` `getCSS` and `#onLoad`). Both are opt-in options the Shell turns on, so Linux behaviour and its Invert toggle stay unchanged until Linux adopts them.
- **Prototype findings:**
  - Book images in `blob:` URLs don't taint the canvas, so the EPUB check works.
  - The EPUB iframe needs `color-scheme: dark` to stay transparent over the theme background.
  - WebKit once drew an iframe image as fully transparent on the first `drawImage`, even after `decode()`. It wasn't reproduced; the check retries after a frame.
  - A 1–2 px light line remains at the edge of the photo in the scan. It looks like the scanned photo's own anti-aliased edge, not restored paper. Check it on real scans when building.
  - The thresholds are tuned on the synthetic test pages only.
- **Check again in WebKitGTK:**
  - the `color` and `difference` canvas blend modes;
  - the same-document SVG filter;
  - `getImageData` cost;
  - `blob:` canvas tainting;
  - the first-draw race.
