# Grilling: Slice dark-mode pages into build work

Type: grilling
Status: resolved
Blocked by: 18
Map: ../map.md

## Question

`19-design-dark-mode-pages.md` decided how dark-mode pages look. Turn it into buildable slices. Settle:
- which milestone it belongs to: a new slice in [the reader-only build effort](../../macos-reader-milestone/spec.md) after Appearance (slice 07), or a later milestone;
- the split between foliate-js on the fork (PDF recolour, operator-box restore and trimming, pixel detection, the per-image check for PDF raster images) and the Reader page (`getCSS`, the SVG filter, the EPUB per-image check), and how the Shell opts in so Linux is unchanged;
- how the settings (Images in Dark Mode, photo dimming, Recolour Charts) are stored, whether per book or global, and whether they follow the Linux settings format. See `18-preferences-on-macos.md`;
- the definition of done: real PDFs, scans and EPUBs to tune the thresholds on, a cost budget per page, the scan-edge line, and the WebKitGTK re-checks listed in `19`.

## Answer

**Six slices in a separate build effort, [`.scratch/macos-dark-mode/`](../../macos-dark-mode/spec.md)** (its `spec.md` plus `issues/01-06`), in the format of the reader milestone.

- **Milestone:** a separate effort, blocked by reader slices 07 (Appearance) and 10 (Document types). It runs in parallel with the library milestone, and its first slice creates the foliate-js fork. Folding it into the reader milestone would have pulled the fork and threshold tuning into a milestone built on the unchanged pin.
- **Slices:** 01 PDF tracer (fork, recolouring, operator-list restore of every image with trimming, Invert through the existing path, the Images row and menu, the app-wide keys; Smart behaves as Original until 03). Then 02 Per-book overrides and 03 PDF Smart, images (per-image check, photo dimming, Recolour Charts) in parallel. Then 04 PDF Smart, scans (pixel detection) and 05 EPUB Smart (Reader page only) in parallel. 06 Acceptance last. 01, 04 and 06 are `ready-for-human`; 02, 03 and 05 are `ready-for-agent`.
- **Opt-in:** three optional `reader.setAppearance` fields, `darkImages`, `photoBrightness` and `recolorCharts`. When a field is missing, today's code runs, so Linux is unchanged. `darkImages: 'invert'` reuses the existing `invert: true` path. The PDF part is one small additive option in foliate-js `pdf.js`, whose exact shape is slice 01's call; the EPUB part is in `src/reader/reader.js`.
- **Settings:** app-wide values in `UserDefaults` under GSettings-style keys: `viewer.view.dark-images` (`original`/`smart`/`invert`, default `smart`), `viewer.view.photo-brightness` (`1.0`/`0.85`/`0.8`, default `0.85`) and `viewer.view.recolor-charts` (default false). `viewer.view.invert` is dropped on macOS, with no migration.
- **Per book:** the user asked for appearance settings per book, as with text size. A check showed that `18-preferences-on-macos.md` made only the Book text size per book and kept everything else global. The user chose to make the three dark-mode settings per book, and only those. They follow the text-size model: the Aa popover and View menu set an override for one book, setting by setting, in a `UserDefaults` dictionary keyed by book identifier. Use Default clears the overrides. The app-wide values are set in Settings, and changing one moves every book without an override. The per-book JSON is unchanged.
- **Comics:** no special case. A black-and-white page counts as line art and is recoloured, and a colour page counts as a photo and is kept, dimmed. A per-book override is the way out.
- **Done:**
  - **Books:** about 8 that the user supplies, kept outside git: about 3 text PDFs, about 2 scans, about 3 EPUBs, plus one CBZ.
  - **Cost**, on the Intel Mac with Smart on: the page turn stays under 300 ms; recolouring plus detection adds ≤ 60 ms per PDF page, and the EPUB check ≤ 100 ms per section. Over budget, a PDF page is shown recoloured first and its photos are painted a moment later.
  - **Scan edge:** a line is acceptable only if it also shows in Original.
  - **Linux:** the Linux app is run on each bumped submodule and behaves as before.
- **Out of scope:** Linux adopting dark-mode pages, with the five WebKitGTK re-checks from `19`.
- **Gap found:** `18` put the Settings window in the library milestone, but `20` sliced the library without it. It is now library slice 10, [Settings window](../../macos-library-milestone/issues/10-settings-window.md), blocked by reader 07, and library acceptance waits on it. Its Appearance tab shows the three app-wide dark-mode settings; whichever of it and dark-mode slice 06 lands later makes the swap.
- **Comments added:** reader slice 07 (the Aa popover will gain the dark-mode controls) and library slice 10.
- **Glossary:** **Dark-mode image settings** added: how pictures are treated when pages are dark, app-wide with a per-book override.
