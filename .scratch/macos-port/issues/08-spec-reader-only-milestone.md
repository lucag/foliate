# Grilling: Spec the reader-only first milestone

Type: grilling
Status: resolved
Map: ../map.md

## Question

What exactly does the reader-only macOS app (see the Answer in `06-choose-approach.md`) build, and when is it done? Settle:
- the `foliate:` scheme handler, and whether host-less `foliate:///` URLs work with the Reader page's security policy or need a host such as `foliate://app/`;
- how a book reaches the Renderer: reproducing the file-chooser trick through `WKUIDelegate`'s open panel callback;
- the JS↔Swift bridge: message handlers, the token/promise RPC, and injected user scripts (uiText, appearance, fonts as CSS);
- whether the pdf.js worker loads over the custom scheme, and acceptable PDF performance;
- whether PDF recolouring is part of the milestone;
- the Safari 26.2+ startup check and its user-facing message (decided in `07-pdfjs-safari-compat.md`);
- where user data lives on macOS for this milestone, keeping the Linux JSON format;
- the definition of done, including what to check on Intel and Apple Silicon.

## Answer

**One milestone, starting with a tracer bullet.** The first slice renders one EPUB and one PDF end to end, and its code is kept.

- **Tracer bullet checks:**
  - **Scheme and CSP:** the Reader page loads from `foliate://app/reader/reader.html`, with a host so `'self'` has a real origin, and its CSP passes. Everything in `src/reader/` and foliate-js is relative, so no shared code changes.
  - **Book loading:** the `loadFile()` file-input trick (`src/reader/reader.js:514`) is answered by `WKUIDelegate`'s open-panel callback. **Fallback** if a scripted `.click()` without a user gesture is blocked: an additive `globalThis.openURL(url)` in the Reader page, with books served at `foliate://book/<token>` through a lazy, range-reading Blob-like wrapper. Linux never calls it.
  - **pdf.js worker:** should load over the custom scheme. If it doesn't, running on the main thread is accepted for this milestone and logged as a performance issue.
  - **PDF speed**, on the user's Intel Mac with a ~300-page text PDF and a scanned PDF: page turn under 300 ms once loaded, first page under 2 s.
- **Bridge:** reproduce the existing contract: the `viewer` message handler, the token/promise RPC, and `showSelection`. Injected user scripts carry `uiText` (English only for this milestone), appearance settings, fonts as CSS, and the Safari 26.2+ check with its update prompt (see `07-pdfjs-safari-compat.md`).
- **User data:** books, progress and annotations in `~/Library/Application Support/com.github.johnfactotum.Foliate/`, or `$XDG_DATA_HOME/com.github.johnfactotum.Foliate/` when it's set. Covers in `~/Library/Caches/com.github.johnfactotum.Foliate/`. Same file names and JSON as Linux.
- **App identity:** bundle ID `io.github.lucag.Foliate`; the data folder keeps upstream's name for compatibility. Registered as an **Alternate** handler for EPUB, MOBI/AZW, FB2, CBZ and PDF. Opens files from File › Open, Finder and the Dock.
- **Interface:** minimal, specified by `09-design-reader-window.md`: one window per book, a toolbar with back/next and a table-of-contents popover, an appearance menu (theme, font size), and a selection popover with Highlight and Copy.
- **Not included:** PDF recolouring (it waits on the foliate-js upstream/fork decision), translations, library, TTS, OPDS.
- **Done when:**
  1. All five formats open and render.
  2. Progress is restored on reopen.
  3. Highlights are created and saved.
  4. A round trip with the user's Linux Foliate keeps progress and highlights intact in both directions.
  5. The PDF speed targets are met.
  6. The universal build is verified with `lipo` and runs on Intel. Apple Silicon testing moves to packaging, since the user has no Apple Silicon Mac.
