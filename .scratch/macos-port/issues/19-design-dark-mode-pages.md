# Prototype: How dark-mode pages look

Type: prototype
Status: open
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
