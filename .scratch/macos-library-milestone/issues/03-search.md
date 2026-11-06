# Search

Status: ready-for-agent
Blocked by: 01
Spec: ../spec.md

## What to build

As in `17`: typing in the sidebar's **Search Library** field shows a **Results** grid on the right, matching title and author, case- and diacritic-insensitive, whichever section is selected. **Edit › Find… ⌘F** focuses the field, and Esc clears it and returns to the section. No matches gets its own empty state.

## Done when

- [ ] XCTest: matching (case, diacritics, author lists, partial words).
- [ ] Checklist: ⌘F, typing, Esc, empty results.
