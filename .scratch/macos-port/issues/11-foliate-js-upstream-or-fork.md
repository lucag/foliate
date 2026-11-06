# Grilling: How Renderer changes reach foliate-js

Type: grilling
Status: open
Map: ../map.md

## Question

`src/foliate-js` is a git submodule of johnfactotum/foliate-js. Some work on the route changes the Renderer: PDF recolouring (`04-pdf-dark-mode.md`), and possibly the additive `openURL` fallback and a lazy Blob-like book source (`08-spec-reader-only-milestone.md`). How do those changes reach the submodule? Options: an upstream PR to johnfactotum/foliate-js first and wait for it; a fork (e.g. lucag/foliate-js) that the submodule points to, with changes sent upstream later; or patches applied at build time. Settle which one, how the fork follows upstream, and whether Linux builds of this repo use the same submodule commit.
