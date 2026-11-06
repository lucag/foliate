# Document types and opening

Status: ready-for-agent
Blocked by: 04
Spec: ../spec.md

## What to build

- `CFBundleDocumentTypes` in `project.yml` for EPUB, MOBI/AZW, FB2, CBZ and PDF, role Viewer, rank **Alternate**, with the right UTIs (declare imported UTIs for those macOS doesn't know).
- Opening from Finder (Open With), by dropping on the Dock icon, and from File › Open Recent.
- One window per book; opening a book that's already open brings its window forward.

## Done when

- [ ] A MOBI/AZW, an FB2 and a CBZ open and render (done criterion 1, with 01).
- [ ] Each format appears under Finder's Open With, and Foliate doesn't become the default PDF app.
- [ ] Open Recent lists books and reopens them; opening the same book twice gives one window.
