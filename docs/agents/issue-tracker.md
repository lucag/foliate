# Issue tracker: Local Markdown

Issues and specs for this repo live as markdown files in `.scratch/`.

## Conventions

- One feature per directory: `.scratch/<feature-slug>/`
- The spec is `.scratch/<feature-slug>/spec.md`
- Implementation issues are one file per ticket at `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01`, never a single combined tickets file
- Triage state is recorded as a `Status:` line near the top of each issue file (see `triage-labels.md` for the role strings)
- Comments and conversation history append to the bottom of the file under a `## Comments` heading

## When a skill says "publish to the issue tracker"

Create a new file under `.scratch/<feature-slug>/` (creating the directory if needed).

## When a skill says "fetch the relevant ticket"

Read the file at the referenced path. The user will normally pass the path or the issue number directly.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a file with one **child** file per ticket.

- **Map**: `.scratch/<effort>/map.md` (the Notes / Decisions-so-far / Fog body).
- **Child ticket**: `.scratch/<effort>/issues/NN-<slug>.md`, numbered from `01`, with the question in the body. A `Type:` line records the ticket type (`research`/`prototype`/`grilling`/`task`); a `Status:` line records `open`/`claimed`/`resolved`, or `wontfix` once ruled out of scope.
- **Blocking**: see Blocking below. A ticket is unblocked when every ticket it lists is `resolved` or `wontfix`.
- **Frontier**: `node scripts/scratch-check.js frontier .scratch/<effort>`; first by number wins.
- **Claim**: set `Status: claimed` and save before any work.
- **Resolve**: append the answer under an `## Answer` heading, set `Status: resolved`, then add a context pointer (gist + link) at the **top** of the map's Decisions-so-far in `map.md` (newest first). A `wontfix` ticket gets its line under Out of scope instead.
- **Slicing tickets** (a ticket whose answer creates or changes a build effort): before resolving, run `grep -rln '<effort name>' .scratch/<map-effort>/issues` and account for every work item an earlier answer assigns to that effort: each is a slice or is ruled out in the Answer.

## Blocking

A `Blocked by:` line near the top of any ticket (wayfinder or build) lists comma-separated blockers, or `(none)`:
- `NN`: ticket `NN` in the same effort;
- `<effort-dir> NN`: ticket `NN` in another effort, for example `macos-reader-milestone 07`;
- an optional trailing `(note)` on an item, for example `02 (if it runs)`.

A build ticket is done when its `Status:` is `resolved`; a ticket that won't run (a conditional slice that wasn't needed) is `wontfix`. Run `node scripts/scratch-check.js` after editing `.scratch/`: it checks statuses, blocker targets and the map's Decisions-so-far links, and CI runs it.
