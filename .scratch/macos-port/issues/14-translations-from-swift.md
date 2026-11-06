# Research: Using the `po/` translations from the Swift Shell

Type: research
Status: resolved
Map: ../map.md

## Question

Linux Foliate is translated with gettext catalogs in `po/` (about 50 languages), and the Reader page gets its strings through `uiText`. How can the Swift Shell reuse them without a second set of translations? Compare: converting `.po` to String Catalogs (`.xcstrings`) or `.strings` at build time (which tools exist, and how plurals and context map), calling libintl/gettext at run time from Swift, and a small runtime `.mo` reader. For each: plural forms, which macOS language is chosen, the cost to the Xcode build, and how strings new to macOS are added to the catalogs and translated.

## Context

Findings: branch `research/translations-from-swift`, commit `efb0808`, file `.scratch/macos-port/research/translations-from-swift.md`.

## Answer

**Keep `po/` as the only source of translations, and convert it at build time.** A small converter (ours to write; no existing tool handles plurals) turns every `.po` into one generated String Catalog, `xcrun xcstringstool compile` compiles it, and Swift looks strings up through `Bundle`. A throwaway version was tested end to end: 34 languages, 277 keys, under a second, with correct Russian plurals in Swift.

- **Ruled out:** libintl at run time. It's an extra LGPL library to build for both architectures, and it picks languages differently from AppKit (it stops at the first `en`, can't fall back from pt-PT to pt-BR, and lets `LANG` override). The fallback, if conversion fails, is a small runtime `.mo` reader.
- **Plurals:** each language's gettext `Plural-Forms` is evaluated on CLDR's sample numbers to map msgstr indexes to CLDR categories, so nothing is hand-mapped. Fuzzy entries are skipped, as msgfmt does. `oc` has no CLDR rules, so its plurals can't be mapped.
- **Context:** no `msgctxt` is used today. If one appears, the key becomes `ctxt\x04msgid`.
- **Language choice:** `Bundle` picks from the `.lproj` folders, matching AppKit and the per-app language setting.
- **Strings new to macOS:** they go into the same `po/` domain. Mark them in Swift as `_("…")` or `ngettext(…)` (one-line literals, no `\(…)`), and add the Swift files to `po/POTFILES`. xgettext's C fallback extracts them, `// TRANSLATORS:` comments included. Translators' workflow (Poedit or PRs, `CONTRIBUTING.md:37-46`) doesn't change.
- **`uiText`:** `src/book-viewer.js:26-43` builds 14 translated templates and sends them in `init` (`:215`). The Reader page fills in each `%s` (`src/reader/reader.js:492-495,516-524`). The Swift Shell rebuilds the same object, keyed by the same English strings, unformatted.
- **Build wiring:** a Run Script phase with `po/*.po` as inputs and a vendored CLDR `plurals.json`. The generated catalog is kept apart from Xcode's own `Localizable.xcstrings` and is not committed. `%d` is passed as `Int32`, or rewritten to `%lld`.
- **Side finding:** the `.pot` is stale. The "Imported %d book" and "Failed to import %d book" plurals (`src/app.js:196-205`, `d68c1d6`) are in no catalog. `po/LINGUAS` has 34 languages, not about 50.
- **Not verified:** a real Xcode target (none exists yet); whether the script should write the `.lproj` folders itself or hand Xcode a `.xcstrings`; the `.xcstrings` schema (no published spec); that AppKit's standard menus need `.lproj` folders.
