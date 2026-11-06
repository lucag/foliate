# EPUB Smart

Status: ready-for-agent
Blocked by: 03
Spec: ../spec.md

## What to build

In the Reader page (`src/reader/reader.js` `getCSS` and `#onLoad`), only when `darkImages` is set, as in `.scratch/macos-port/issues/19-design-dark-mode-pages.md`:
- set `color-scheme: dark` on the book iframe so it stays transparent over the theme background, and drop the opaque background on `img, svg`;
- under Smart, run the 32×32 per-image check on each image. Line art, gaiji and inline SVG are recoloured through a same-document SVG filter (invert, hue-rotate 180°, map to the theme's fg/bg). Photos are dimmed with `filter: brightness(photoBrightness)`. Charts follow `recolorCharts` as in 03;
- under Original, every image is kept and dimmed;
- retry the check after a frame when the first `drawImage` comes back fully transparent;
- fixed-layout books and CBZ get the same per-image check, with no special case.

No foliate-js change.

## Done when

- [ ] Checklist: an illustrated EPUB, one with line art or gaiji, a fixed-layout book and a CBZ, under each option, in Default, Sepia and Nord dark. Light mode is unchanged.
- [ ] The Linux app behaves as before.
