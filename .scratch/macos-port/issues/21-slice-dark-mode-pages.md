# Grilling: Slice dark-mode pages into build work

Type: grilling
Status: open
Map: ../map.md

## Question

`19-design-dark-mode-pages.md` decided how dark-mode pages look. Turn it into buildable slices. Settle:
- which milestone it belongs to: a new slice in [the reader-only build effort](../../macos-reader-milestone/spec.md) after Appearance (slice 07), or a later milestone;
- the split between foliate-js on the fork (PDF recolour, operator-box restore and trimming, pixel detection, the per-image check for PDF raster images) and the Reader page (`getCSS`, the SVG filter, the EPUB per-image check), and how the Shell opts in so Linux is unchanged;
- how the settings (Images in Dark Mode, photo dimming, Recolour Charts) are stored, whether per book or global, and whether they follow the Linux settings format. See `18-preferences-on-macos.md`;
- the definition of done: real PDFs, scans and EPUBs to tune the thresholds on, a cost budget per page, the scan-edge line, and the WebKitGTK re-checks listed in `19`.
