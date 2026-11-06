# PDF Smart, scans

Status: ready-for-human
Blocked by: 03
Spec: ../spec.md

## What to build

In foliate-js `pdf.js`, under Smart, pixel detection of photos where there is no operator box (a photo inside a scanned page, or when the private operator list is missing), as in `.scratch/macos-port/issues/19-design-dark-mode-pages.md`:
- 4× downsample, 16-px tiles; "paper" is the page's most common colour;
- gaps between photo tiles are filled, and each connected group is restored as one rectangle;
- the rectangle grows line by line until a line is mostly paper, so captions stay out;
- trimmed by lightness, up to one 4-px cell, then inset 2 px.

If detection pushes a page over budget (≤ 60 ms added per page on the user's Intel Mac), show the recoloured page first and paint the restored photos a moment later.

## Done when

- [ ] Checklist: a scanned PDF with a photo, in Default, Sepia and Nord dark. The photo is restored, its caption stays recoloured, and there's no light frame. A light edge line is acceptable only if it also shows in Original.
- [ ] Timing on the Intel Mac: added cost per page and page turn, recorded here.
- [ ] The Linux app runs on the bumped submodule and behaves as before.
