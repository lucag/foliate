# Grilling: Slice the reader-only milestone into build tickets

Type: grilling
Status: claimed
Map: ../map.md

## Question

The destination needs work slices ready to build. Break the reader-only milestone (the Answer in `08-spec-reader-only-milestone.md`, with its interface replaced by the Answer in `09-design-reader-window.md`) into ordered, independently buildable vertical slices, each with its own definition of done. Settle:
- what the tracer bullet slice includes and excludes, and what happens if its fallback (`globalThis.openURL`) is needed;
- the order of the slices after it (bridge, user data and progress, overlays and popovers, highlights, menu bar, states, document types and Open Recent, universal build), and which of them can run in parallel;
- where the Xcode project and Swift sources live under `macos/` and how the Reader page and foliate-js get into the app bundle (copied at build time, or referenced in place);
- how each slice is checked (manual checklist, XCTest, a round trip with Linux), and which slice owns each of the milestone's six done criteria;
- the format of the build tickets: which tracker, and whether they are `ready-for-agent` or `ready-for-human`.
