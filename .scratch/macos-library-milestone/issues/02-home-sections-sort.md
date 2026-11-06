# Home, sections and sort

Status: ready-for-agent
Blocked by: 01
Spec: ../spec.md

## What to build

As in `17`:
- **Home** (`house`, the default selection): a large title, then **Continue Reading** (up to four books in progress, newest first, each with cover, progress bar, percentage, last-read date, where you are, and **Resume**), then **Recently Added** (by date added), then **All Books**.
- **Library** sections with counts: All Books, Reading (`book`), Unread (`book.closed`), Finished (`checkmark.circle`). Unread means no progress, and Finished means progress at the end, as Linux computes it from `progress`.
- Badges: NEW and "New" for unread books; a `checkmark` badge and "Finished" for finished ones.
- A large section title with its count and the **"Sorted by …"** pop-up: Last Read (default), Title, Author, Date Added, Progress. The same choices go in **View › Sort By ▸**, and the choice is remembered.
- **View › Show/Hide Sidebar ⌃⌘S.**
- Each empty section gets its own short empty state.

## Done when

- [ ] XCTest: section membership and counts, and all five sort orders (with ties and missing authors) on sample data.
- [ ] Checklist: Home's three parts and Resume, each section, badges, sort pop-up and menu kept in step, sidebar toggle.
