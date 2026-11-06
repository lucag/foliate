# Research: Using the `po/` translations from the Swift Shell

Type: research
Status: open
Map: ../map.md

## Question

Linux Foliate is translated with gettext catalogs in `po/` (about 50 languages), and the Reader page gets its strings through `uiText`. How can the Swift Shell reuse them without a second set of translations? Compare: converting `.po` to String Catalogs (`.xcstrings`) or `.strings` at build time (which tools exist, and how plurals and context map), calling libintl/gettext at run time from Swift, and a small runtime `.mo` reader. For each: plural forms, which macOS language is chosen, the cost to the Xcode build, and how strings new to macOS are added to the catalogs and translated.
