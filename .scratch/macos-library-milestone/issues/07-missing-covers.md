# Missing covers

Status: ready-for-agent
Blocked by: 04, 06
Spec: ../spec.md

## What to build

A low-priority background pass. For each book in the store with no cached cover whose location resolves (04), it runs the importer (06) to make only the cover, one book at a time, and updates the grid cell. It runs after launch and when new books appear, and pauses while an import is running. A missing book keeps the greyed placeholder.

## Done when

- [ ] XCTest: the pass picks exactly the books that are found and have no cover, and writes only the cover, leaving the JSON untouched.
- [ ] Checklist: clear the cover cache (or copy in a Linux data folder) and covers appear without opening the books.
