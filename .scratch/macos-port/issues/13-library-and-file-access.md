# Grilling: Library and file access on macOS

Type: grilling
Status: open
Map: ../map.md

## Question

How does the macOS app find, add and remember books after the reader-only milestone? Settle:
- how the Linux library (`src/library.js`, `src/data.js`) finds books today and what it stores about a book's location, since the data folder is shared with Linux (`08-spec-reader-only-milestone.md`);
- whether books stay where they are or are copied into the library, and how a moved or renamed file is found again (plain paths, or bookmark data; the app is unsigned and not sandboxed);
- how a book's location is shared with Linux when the data folder moves between machines;
- what the library window shows and how it fits with one window per book (`09-design-reader-window.md`); this may need a prototype ticket.
