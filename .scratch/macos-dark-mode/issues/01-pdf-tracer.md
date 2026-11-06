# PDF tracer

Status: ready-for-human
Blocked by: reader 07, reader 10
Spec: ../spec.md

## What to build

The thinnest path through every layer, for PDFs:
- **Fork:** create `lucag/foliate-js`, branch `foliate-macos`, from `399248a`, and point `.gitmodules` at it (`.scratch/macos-port/issues/11-foliate-js-upstream-or-fork.md`).
- **foliate-js `pdf.js`:** one opt-in option that recolours each rendered page to the theme's fg/bg with canvas blend-mode fills, keeping hue with a `color` pass (`.scratch/macos-port/issues/04-pdf-dark-mode.md`). Restore every raster image from pdf.js's private render operator list, guarded as in `16-dark-mode-images-vs-figures.md`. Trim each box at full resolution: shave edge lines matching the paper colour, up to pdf.js's 1/256-of-the-canvas rounding, so no halo is left. Option off means today's rendering. Open the upstream PR.
- **Reader page:** accept `darkImages`, `photoBrightness`, `recolorCharts` in `setAppearance` and pass them on. A missing field leaves today's behaviour. `darkImages: 'invert'` uses the existing `invert: true` path.
- **Shell:** the app-wide keys `viewer.view.dark-images`, `viewer.view.photo-brightness`, `viewer.view.recolor-charts` behind the preferences type from reader 07. Drop `viewer.view.invert`. Add the **Images in Dark Mode** row (Original / Smart / Invert) to the Aa popover and View › Images in Dark Mode ▸. Until 03, Smart behaves as Original. Photos are dimmed to the stored brightness.

The prototype on branch `prototype/dark-mode-pages` (`macos/prototype-dark-mode/`) has working code for recolouring, the operator list and trimming.

## Done when

- [ ] XCTest: the keys' defaults (`smart`, `0.85`, false); a stored value survives a relaunch.
- [ ] Checklist: a text PDF and a scanned PDF in Default, Sepia and Nord dark under Original and Invert. Text and vectors take the theme with hue kept, every picture is back with no light frame, and the scanned page is restored whole. Light mode is unchanged.
- [ ] The Linux app runs on the bumped submodule and behaves as before, Invert toggle included.
- [ ] The upstream PR is open and linked here.
