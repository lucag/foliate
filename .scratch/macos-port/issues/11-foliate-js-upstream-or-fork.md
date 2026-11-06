# Grilling: How Renderer changes reach foliate-js

Type: grilling
Status: resolved
Map: ../map.md

## Question

`src/foliate-js` is a git submodule of johnfactotum/foliate-js. Some work on the route changes the Renderer: PDF recolouring (`04-pdf-dark-mode.md`), and possibly the additive `openURL` fallback and a lazy Blob-like book source (`08-spec-reader-only-milestone.md`). How do those changes reach the submodule? Options: an upstream PR to johnfactotum/foliate-js first and wait for it; a fork (e.g. lucag/foliate-js) that the submodule points to, with changes sent upstream later; or patches applied at build time. Settle which one, how the fork follows upstream, and whether Linux builds of this repo use the same submodule commit.

## Answer

**A temporary fork, `lucag/foliate-js`, that the submodule points to, with every change also sent upstream.** The macOS port aims to go upstream into johnfactotum/foliate eventually, so the fork stays small and its changes stay upstreamable.

- **Why not wait for upstream:** about a dozen outside PRs to johnfactotum/foliate-js have been open since August 2026, and none were merged in that time. The last upstream commit was 2026-05-01. Build-time patches were ruled out because they hide changes from git and fight the submodule.
- **Mechanics:**
  - Changes go on a branch `foliate-macos` in `lucag/foliate-js`, and `.gitmodules` points at the fork. It's the only build file that names the URL.
  - Each change is opened upstream as its own small PR at the same time.
- **Base and following upstream:**
  - The branch starts from the currently pinned `399248a`, the same commit upstream Foliate's `gtk4` uses.
  - Upstream `main` is **merged** in, never rebased, so commits pinned in this repo's history stay fetchable.
  - Merge when upstream Foliate bumps its submodule, or when a fix is needed.
- **Both platforms:** Linux and macOS builds use the same submodule commit. Changes are additive and Linux-inert, except where they're meant to help both, as PDF recolouring is. Each change is checked on the Linux app before the submodule is bumped.
- **When:** lazily. The fork is created by the first ticket that needs a Renderer change: PDF recolouring, the dark-mode follow-up, or the read-aloud `<emphasis>` fix. The reader-only milestone builds on the unchanged upstream pin.
