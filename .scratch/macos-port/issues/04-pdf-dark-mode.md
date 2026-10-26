# Research: PDF dark mode in the Renderer

Type: research
Status: resolved
Map: ../map.md

## Question

Foliate applies theme and background colours to reflowable books but not to PDFs. How could PDF pages follow the reading theme? Options to evaluate: the pdf.js `pageColors` render option, canvas or CSS filters (invert plus hue-rotate, which mangles images), and per-page compositing in foliate-js `pdf.js` / `fixed-layout.js`. For each: fidelity (images, highlights), performance cost, and whether it lives in the Renderer (benefiting Linux too) or in the Shell. Also check whether upstream foliate-js has an issue or work in progress on this.

## Context

Findings: branch `research/pdf-dark-mode`, file `.scratch/macos-port/research/pdf-dark-mode.md`.

## Answer

**Recolour each PDF page in the Renderer** (foliate-js `pdf.js`). After `page.render()`, a few full-canvas blend-mode fills (`difference`, then `multiply` by fg−bg, then `lighter` to add the base colour) map white to the theme background and black to the theme foreground. It's cheap compared with rendering the page, leaves the text and link layers alone, and works the same on Linux and macOS. Optionally, pdf.js's `recordOperations` bounding boxes can restore image areas un-inverted, with a size cut-off so full-page scans still get recoloured.

- **Why PDFs ignore the theme today:** `Reader.setAppearance` (`src/reader/reader.js:285`) calls `renderer.setStyles?.()`, and `FixedLayout` has no `setStyles`, so the call does nothing for PDFs. Only the background around the pages follows the theme.
- **Ruled out:** pdf.js `pageColors` (the vendored version is 5.5.207). It relies on canvas `ctx.filter`, which WebKit has off by default, so it would silently do nothing in both WebKitGTK and WKWebView. Where it works, it posterizes images.
- **Existing fallback:** the Shell's "Invert Colors in Dark Mode" CSS filter (`src/reader/reader.html:29-32`) already reaches PDFs. It can't use theme colours, and it inverts images and selections. Keep it, and turn the recolouring off while it's on.
- **What it takes:** a colour setter on `FixedLayout` passed through to `onZoom`, plus one call from `Reader.setAppearance`.
- **Upstream:** no foliate-js issue or PR exists. The related Foliate issues are #1263, #1597, #1598 and #1331.
- **Caveat:** this was not tested in a live web view. The conclusions come from reading the code.

The full findings are on branch `research/pdf-dark-mode`, commit `1157be5`.
