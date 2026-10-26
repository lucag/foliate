# Grilling: Spec the reader-only first milestone

Type: grilling
Status: open
Map: ../map.md

## Question

What exactly does the reader-only macOS app (see the Answer in `06-choose-approach.md`) build, and when is it done? Settle:
- the `foliate:` scheme handler, and whether host-less `foliate:///` URLs work with the Reader page's security policy or need a host such as `foliate://app/`;
- how a book reaches the Renderer: reproducing the file-chooser trick through `WKUIDelegate`'s open panel callback;
- the JS↔Swift bridge: message handlers, the token/promise RPC, and injected user scripts (uiText, appearance, fonts as CSS);
- whether the pdf.js worker loads over the custom scheme, and acceptable PDF performance;
- whether PDF recolouring is part of the milestone;
- where user data lives on macOS for this milestone, keeping the Linux JSON format;
- the definition of done, including what to check on Intel and Apple Silicon.
