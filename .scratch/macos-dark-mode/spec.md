# Spec: macOS dark-mode pages

The macOS **Shell** recolours book pages to the dark theme instead of leaving PDFs with their own page colours. Text, vectors, line art and scans take the theme's colours with their hue kept. Photos are put back, dimmed. The reader chooses how pictures are treated through the **Dark-mode image settings**: app-wide values that any book can override.

Decided in the wayfinder map `.scratch/macos-port/map.md`, mainly:
- `.scratch/macos-port/issues/19-design-dark-mode-pages.md`: how dark pages look, the detection methods and their parameters, the settings and where they appear (prototype on branch `prototype/dark-mode-pages`, `macos/prototype-dark-mode/`);
- `.scratch/macos-port/issues/16-dark-mode-images-vs-figures.md` and `04-pdf-dark-mode.md`: the research behind it;
- `.scratch/macos-port/issues/21-slice-dark-mode-pages.md`: this slicing, the storage, the opt-in and the done criteria;
- `.scratch/macos-port/issues/11-foliate-js-upstream-or-fork.md`: the fork this effort creates;
- `.scratch/macos-port/issues/18-preferences-on-macos.md`: how preferences are stored.

## Standing rules

All the reader milestone's standing rules apply (`.scratch/macos-reader-milestone/spec.md`: Linux-inert shared changes, XcodeGen project, bundle, the `xcodegen -s macos/project.yml && xcodebuild build test` gate, XCTest for logic that isn't UI plus a manual checklist per slice, no XCUITest, each slice wires its own menu items). In addition:

- **Prerequisites:** reader slices 07 (Appearance) and 10 (Document types and opening). The library milestone isn't needed; the two efforts run in parallel.
- **Fork:** slice 01 creates `lucag/foliate-js`, branch `foliate-macos`, from the pinned `399248a`, and points `.gitmodules` at it. Each foliate-js change also goes upstream as its own small PR. Before every submodule bump, run the Linux app on it and check it behaves as before.
- **Opt-in:** the Shell passes three optional fields to `reader.setAppearance`: `darkImages` (`'original' | 'smart' | 'invert'`), `photoBrightness` (`1 | 0.85 | 0.8`) and `recolorCharts` (boolean). When a field is missing, today's code runs. Linux never sends them, so it keeps its own Invert toggle. `darkImages: 'invert'` goes through the existing `invert: true` path; there is no second Invert.
- **Where the code goes:** PDF recolouring, operator-list restore, trimming, the PDF per-image check and pixel detection go in foliate-js `pdf.js` on the fork, behind one small additive option (its exact shape is slice 01's call). EPUB handling goes in the Reader page (`src/reader/reader.js` `getCSS` and `#onLoad`), without a fork change.
- **Settings:** app-wide values in `UserDefaults`, under GSettings-style keys that Linux could adopt as they are:
  - `viewer.view.dark-images`: `original` / `smart` / `invert`, default `smart`;
  - `viewer.view.photo-brightness`: `1.0` / `0.85` / `0.8`, default `0.85`;
  - `viewer.view.recolor-charts`: boolean, default false.

  `viewer.view.invert` is dropped on macOS (nothing has shipped, so there is no migration). The app-wide values are set in the Settings window's Appearance tab (library slice 10).
- **Per-book overrides:** the Aa popover and View › Images in Dark Mode ▸ set a book's own value, one setting at a time, in a `UserDefaults` dictionary keyed by the book identifier, like **Book text size**. A book without an override follows the app-wide value, and changing that value moves every such book. **Use Default** clears the book's overrides. The per-book JSON is unchanged.
- **Comics:** no special case. A CBZ or fixed-layout page is one image, so a black-and-white page counts as line art and is recoloured, and a colour page counts as a photo and is kept, dimmed. A per-book override is the way out.

## Slices

| # | Slice | Blocked by | Status |
| --- | --- | --- | --- |
| 01 | PDF tracer | reader 07, 10 | ready-for-human |
| 02 | Per-book overrides | 01 | ready-for-agent |
| 03 | PDF Smart, images | 01 | ready-for-agent |
| 04 | PDF Smart, scans | 03 | ready-for-human |
| 05 | EPUB Smart | 03 | ready-for-agent |
| 06 | Acceptance | all others | ready-for-human |

After 01, slices 02 and 03 can run in parallel. After 03, slices 04 and 05 can run in parallel.

## Done criteria and their owners

1. In dark mode, PDF text and vectors take the theme's colours with their hue kept, and Original puts every picture back with no halo: 01.
2. Smart keeps photos (dimmed by the chosen amount) and recolours line art, in PDFs (03, and 04 for scans) and EPUBs (05). Recolour Charts works on both (03, 05). Invert behaves as before (01).
3. Per-book overrides survive a relaunch, and Use Default returns a book to the app-wide values: 02.
4. **Books:** the thresholds are tuned on about 8 books the user supplies, kept outside git and listed by file name in 06: about 3 text PDFs with photos, charts and vector figures; about 2 scanned PDFs, at least one with a photo on the page; and about 3 EPUBs (one illustrated, one with line art or gaiji, one fixed-layout or comic-like). Plus one CBZ.
5. **Cost**, on the user's Intel Mac with Smart on: the page turn stays under 300 ms once loaded; recolouring plus detection adds at most 60 ms per PDF page; the EPUB per-image check adds at most 100 ms per section. When a PDF page goes over, it is shown recoloured first and its photos are painted a moment later (04).
6. **Scan edge:** a light line at the edge of a restored photo is acceptable only if the same line also shows in Original. Otherwise trimming must remove it: 04.
7. **Linux-inert:** the Linux app on the final submodule behaves as before, Invert toggle included: 01 and 06.

06 re-runs all seven.

## Out of scope

Linux adopting dark-mode pages, and the WebKitGTK re-checks it would need (the `color` and `difference` canvas blend modes, the same-document SVG filter, `getImageData` cost, `blob:` canvas tainting, the first-draw race). See Out of scope on the map.
