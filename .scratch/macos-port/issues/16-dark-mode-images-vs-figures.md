# Research: What dark mode recolours and what it leaves alone

Type: research
Status: open
Map: ../map.md

## Question

`04-pdf-dark-mode.md` chose recolouring PDF pages in the Renderer, and mentioned only as an option keeping raster images un-inverted using pdf.js `recordOperations` bounding boxes. Which parts of a page should dark mode recolour, and how can the Renderer tell them apart, for both PDFs and reflowable books (EPUB and the other Renderer formats)?

- **PDF:** how to tell raster photos from vector figures (charts, diagrams, line art) and from text; what pdf.js (vendored 5.5.207) exposes for this (operator lists, `paintImageXObject` and friends, `recordOperations` bounding boxes, the text layer); how full-page scans, images under text, masks and transparent images behave; the cost per page.
- **Reflowable:** what Foliate and foliate-js do today with `<img>`, SVG and CSS backgrounds in dark themes (`src/themes.js`, `src/reader/`, foliate-js `paginator.js` and the style hooks, the "Invert Colors in Dark Mode" filter at `src/reader/reader.html:29-32`); options such as leaving images alone, dimming them, inverting only line art or transparent images, and heuristics (transparency, colour count, size) for spotting line art.
- **Prior art:** what pdf.js `pageColors`, Firefox Reader View, Okular, Zathura, Sioyek, KOReader, Apple Books and Readium do, from their source or docs; and any upstream Foliate or foliate-js issues.
- For each option: fidelity, cost, WebKit support in both WebKitGTK and WKWebView (canvas `ctx.filter` is off in WebKit, see `04`), and whether it lives in the Renderer so Linux gets it too.
