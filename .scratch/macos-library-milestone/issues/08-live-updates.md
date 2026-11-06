# Live updates

Status: ready-for-agent
Blocked by: 01
Spec: ../spec.md

## What to build

- In-process: progress, covers, imports and removals from any window reach the store and the Library window directly as change notifications.
- From outside: an FSEvents stream on the data folder (including `library/`) re-reads only the per-book JSON files that changed, adds new ones, drops deleted ones, and reloads `uri-store.json` and the side files when they change. Changes the app made itself are ignored. Updates are coalesced at about 0.5 s.

## Done when

- [ ] XCTest: the store reacts to an added, changed and deleted JSON in a temporary data folder, and ignores its own writes.
- [ ] Checklist: reading in a reader window updates Continue Reading. Copying a JSON in with Finder adds the book, and deleting one removes it.
