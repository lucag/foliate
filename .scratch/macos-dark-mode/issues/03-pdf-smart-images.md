# PDF Smart, images

Status: ready-for-agent
Blocked by: 01
Spec: ../spec.md

## What to build

- **foliate-js `pdf.js`:** under Smart, run the per-image check (option E in `.scratch/macos-port/issues/16-dark-mode-images-vs-figures.md`) on each raster image found through the operator list. Photos are restored and dimmed to `photoBrightness`. Line art is left recoloured. Images with few, strongly saturated colours (charts) are recoloured with the hue kept when `recolorCharts` is on, and kept dimmed when it's off. Vector charts are always recoloured.
- **Shell:** photo dimming (100% / 85% / 80%) and a **Recolour Charts** switch next to the Images row in the Aa popover and in View › Images in Dark Mode ▸.

## Done when

- [ ] Checklist: a text PDF with a photo, a raster chart and a line drawing, under Smart with Recolour Charts on and off and with each dimming level. Only the photo is restored.
- [ ] The Linux app runs on the bumped submodule and behaves as before.
