# Research: Using the `po/` translations from the Swift Shell

Ticket: `../issues/14-translations-from-swift.md`. Researched 2026-11-06 with Xcode 26.6 (`xcstringstool`) and GNU gettext 1.0 (Homebrew) on macOS 26.

## Bottom line

Keep `po/` as the only source of translations. At build time, convert each `.po` into one generated String Catalog and compile it with Xcode's own `xcstringstool`. Then look strings up through `Bundle`. Map gettext plural indices to CLDR categories by running each language's `Plural-Forms` expression on CLDR's sample numbers. A throwaway converter of about 130 lines did this for all 34 catalogs. The compiled Russian plurals came out right from Swift (details below).

macOS-only strings go into the same `po/` domain. Add the Swift files to `po/POTFILES` and mark strings with `_()`/`ngettext()`. xgettext has no Swift parser, but its C fallback extracts these calls. Translators keep using the same `.po` files and the same PR workflow.

Do not use libintl: it is an extra LGPL dylib to build for two architectures, and it picks languages differently from the rest of the app. A runtime `.mo` reader is a fair fallback, but it duplicates what Foundation already does.

## How strings flow on Linux today

- **Catalogs.** `po/meson.build:1` is the whole i18n setup: `i18n.gettext(meson.project_name(), preset: 'glib')`. `po/POTFILES` lists 31 inputs: JS files in `src/`, the `.ui` files, and the desktop/metainfo files. `po/LINGUAS` has **34 languages**, not about 50. `po/` holds 34 `.po` files and the template `po/com.github.johnfactotum.Foliate.pot`.
- **Workflow.** There is no Weblate. `CONTRIBUTING.md:37-46` says translation is done "via Poedit or by manually editing the `.po` files". `git log -- po` shows one PR per language ("Update Galician translation (#1617)" and so on). A maintainer regenerates the template from time to time ("Update translations", `1d6ea80`).
- **The template is stale.** `POT-Creation-Date: 2024-11-28` (`.pot:11`), yet `src/app.js:196-205` added `ngettext('Imported %d book', …)` and `'Failed to import %d book'` in `d68c1d6` (2026-03-05). Neither is in the `.pot` or any `.po`. Today the `.pot` has 277 messages, exactly one plural (`%d Annotation`, `src/annotations.js:649`), and **no `msgctxt` at all**.
- **Runtime.** `src/main.js:25-26` calls `bindtextdomain`/`textdomain`. GJS's `gettext` module does the rest.
- **`uiText` for the Reader page.** The GJS Shell builds a plain object of already-translated strings and sends it in:
  - `src/book-viewer.js:26-43`: `loc`, `page`, `pageWithoutTotal`, `close`, and ten `references.*` labels. That is 14 `_()` calls, sent by `this.#exec('init', { uiText })` at `src/book-viewer.js:215`.
  - `src/reader/reader.js:516-524`: `init({ uiText })` stores them in `globalThis.uiText`. It formats `loc`/`page` with a tiny `printf` that replaces each `%s` in turn (`reader.js:492-495`), and reads `references` at `reader.js:268-272`.
  - The OPDS page gets its own `uiText` (`src/library.js:46-89`) through `webView.run('globalThis.uiText = …')` (`library.js:530`). `src/opds/main.js` reads it.

  So the Swift Shell has to rebuild the same object. It needs the same English msgids as keys and must hand the translated templates to JS **unformatted**, because the `%s` replacement happens in JS. The reader-only milestone ships `uiText` in English only (`issues/08-spec-reader-only-milestone.md:28,32`), so this work comes after that milestone.

### Catalog quirks any approach must handle

| Issue | Where | Effect |
| --- | --- | --- |
| Placeholder `Plural-Forms: nplurals=INTEGER; plural=EXPRESSION;` | `po/ar.po:19`, `po/el.po:19`, `po/hu.po:19` | libintl falls back to the Germanic `n != 1` (`gettext-runtime/intl/plural-exp.c`, "By default we are using the Germanic form"). A converter must do the same. |
| `ko` declares two forms (`plural=n != 1`) | `po/ko.po:18` | CLDR Korean has only `other`. Both msgstrs are identical, so nothing is lost. |
| `he` declares four forms | `po/he.po:19` | Current CLDR Hebrew has `one`/`two`/`other`. Forms 2 and 3 are identical, so nothing is lost. |
| `oc` (Occitan) | `po/oc.po` | CLDR `plurals.json` has no `oc` rules. Plural entries can't be mapped. Singular strings still work. |
| `#, fuzzy` entries | e.g. `po/de.po:117,239` (`%d Annotation`, `Go to Footnote`) | msgfmt leaves them out by default, so they show in English on Linux too. A converter should also skip them; mine does. |
| Locale names | `zh_CN`, `zh_TW`, `pt_BR` | macOS uses `zh-Hans`, `zh-Hant`, `pt-BR` for `.lproj` names. Apple's identifier rules: "Choosing localization regions and scripts" (Xcode docs). |

## Option A: build-time `.po` to String Catalog (recommended)

**Tools that exist.**
- **Xcode's `xcstringstool`** (`xcrun xcstringstool --help`, Xcode 26.6) has `compile`, `sync`, `extract`, `print`, `generate-symbols` and `installloc`. `compile <file>.xcstrings -o <dir>` writes `<lang>.lproj/Localizable.strings` plus `.stringsdict`. It does not read `.po` files.
- **GNU gettext**: `msgcat --stringtable-output` writes NeXTstep/GNUstep `.strings`. On `po/de.po` it **refuses**: "message catalog has plural form translations, but the output format does not support them". So it is only usable after removing plurals.
- **Translate Toolkit** converts `.strings` with `prop2po`/`po2prop` using the `strings` dialect (`translate/storage/properties.py:543`). It has a `stringsdict` storage class (`translate/storage/stringsdict.py`) but no po↔stringsdict converter in `translate/convert/`, and nothing for `.xcstrings`.
- **Weblate** supports `.strings` and `.stringsdict` (`docs/formats/apple.rst`, `stringsdict.rst`). Foliate does not use Weblate.
- No maintained po→xcstrings tool turned up (GitHub search for `xcstrings` and `gettext swift`).
- Conclusion: write a small converter in the repo.

**Prototype (throwaway, not committed).** I wrote a Python script of about 130 lines and ran it on the real `po/`:
1. It parses each `.po`, skipping fuzzy and obsolete entries.
2. It writes one `.xcstrings` JSON file. For each key, `localizations.<lang>.stringUnit` holds a plain string and `localizations.<lang>.variations.plural.<category>.stringUnit` holds a plural.
3. It runs `xcrun xcstringstool compile`.

Results:
- 34 languages, 277 keys, 0.18 s to convert and 0.5 s to compile, 792 KB of `.lproj` output. The compiled Russian `.stringsdict` for `%d Annotation` has `NSStringPluralRuleType` with `one`/`few`/`many`/`other`.
- A Swift test using `Bundle(path:).localizedString(forKey:value:table:)` and `String(format:locale:)` printed:
  - Russian: "1 примечание", "2 примечания", "5 примечаний", "21 примечание", "22 примечания", "111 примечаний".
  - German: `Seite %s von %s`. Its fuzzy plural correctly fell back to English.

**How plurals map.** gettext picks a msgstr index with a C expression (`Plural-Forms: nplurals=…; plural=…`, gettext manual §"Plural forms"). Apple picks one of the CLDR categories zero/one/two/few/many/other.
- The mapping is decided by data, not by hand: for each CLDR category in `cldr-json/cldr-core/supplemental/plurals.json`, take its `@integer` samples and run the gettext expression on them. The index they all land on is that category's msgstr.
- For categories with only decimal samples (Russian, Ukrainian and Belarusian `other`, Czech `many`), use the gettext index of the truncated integer.
- This needs the same small C-expression evaluator that a `.mo` reader would need: about 35 lines in Python.
- The resulting tables were sensible. Examples: ru `{one:0, few:1, many:2, other:2}`, cs `{one:0, few:1, many:2, other:2}`, fr/es/it/pt-BR `{one:0, many:1, other:1}`, ga `{one…other: 0…4}`, ja/zh `{other:0}`.
- The only conflicts were ko and he, both harmless (see the table above).
- The script reports any category whose samples land on different gettext indices, which catches a wrong `Plural-Forms` header in CI.

**How `msgctxt` maps.** None is used today. If one appears, it must become part of the key, because a String Catalog key has no separate context field. I used `ctxt + "\u0004" + msgid`, the same join `.mo` files use (gettext manual §"MO Files": "the concatenation of the context, a EOT byte, and the original string"). Swift's `pgettext` wrapper would build the same key.

**Which macOS language is chosen.** `Bundle` does it, the same way as for any Mac app. It sees the generated `.lproj` folders and orders them by the user's language list, including the per-app choice in System Settings → General → Language & Region → Applications (Apple support guide mh26684). Test results from `Bundle.preferredLocalizations(from:forPreferences:)` with 35 localizations:

| User prefers | Bundle chose |
| --- | --- |
| `ru, de` | `ru` |
| `zh-Hant-TW` | `zh-Hant` |
| `pt-PT` | `pt-BR` |
| `fr-CA` | `fr` |
| `sr-Latn` | `en` (correct: `sr.po` is Cyrillic) |
| default list starting `en-US` | `en` |

AppKit's own text (standard menu items, panels) uses the same choice, so the app's UI language stays consistent.

**Cost to the Xcode build.**
- Add one Run Script phase: convert, run `xcstringstool compile`, and copy the `.lproj` folders into the app's Resources. It needs `python3` (already present wherever Xcode's command-line tools are) or the same script written in Swift (`xcrun swift`).
- The CLDR `plurals.json` (about 77 KB) must be vendored, or the category tables checked in.
- Declare `po/*.po` as script inputs, so Xcode reruns the phase only when they change.
- Don't commit the generated `.xcstrings`; it would be a second copy of the translations.
- Keep it out of Xcode's own `Localizable.xcstrings`. Xcode's build-time sync rewrites catalogs it extracts into, and the Apple docs say "Each time you build your project, Xcode updates your string catalogs".

**Swift-side gotchas.**
- `%d` in a msgid becomes a `d` format type in the `.stringsdict`. Pass `Int32`, or have the converter rewrite `%d` to `%lld` for 64-bit `Int`. I passed `Int32`.
- `%s` in Foundation formatting means a C string. Templates sent to JS through `uiText` are not formatted in Swift, so this matters only for strings Swift formats itself.

## Option B: libintl/gettext at run time from Swift

- **Linking.** macOS ships no libintl. Homebrew's libintl is single-architecture: `lipo -info` gives `x86_64` here. A universal app needs libintl built from source for arm64 and x86_64, then embedded and relinked. It is LGPL-2.1+ (`brew info gettext`), which is fine for GPL Foliate but adds packaging work.
- **Swift API.** `libintl.h` maps `gettext` to `libintl_gettext` through macros (`/usr/local/include/libintl.h:216,293`), so Swift needs a small module map or shim. `pgettext` is a macro in `gettext.h`, not a library symbol, so it would need reimplementing.
- **Plural forms.** Exact gettext semantics: the `.mo` header expression is evaluated at run time, with the Germanic fallback for broken headers. No CLDR mapping is needed.
- **Language choice.** `guess_category_value` in `gettext-runtime/intl/dcigettext.c` checks, in order:
  1. `LANGUAGE`,
  2. `LC_ALL`/`LC_*`/`LANG`,
  3. otherwise `_nl_language_preferences_default()`, which on macOS calls `CFLocaleCopyPreferredLanguages()` (`intl/langprefs.c:227-300`).

  The macOS list follows the per-app override: running with `-AppleLanguages "(ru, de)"` changed `CFLocaleCopyPreferredLanguages()`. But gettext matches differently from `Bundle`:
  - it **stops at the first `en`** in the list (`langprefs.c`, "when we see "en" … ignore all further elements");
  - it falls back only from `ll_CC` to `ll`, so `pt-PT` finds no `pt.mo` and shows English, where Bundle picks `pt-BR`;
  - it maps `zh-Hans`/`zh-Hant` to `zh_CN`/`zh_TW` through a table (gnulib `localename-unsafe.c:1353-1356`).

  It also has no idea which localizations AppKit picked. Without `.lproj` folders or `CFBundleLocalizations`, standard menus stay English while app strings are translated. A Finder-launched app normally has no `LANG`, so step 3 applies. A Terminal-launched one inherits `LANG` (here `en_US.UTF-8`), which **overrides** the macOS language list.
- **Build cost.** `msgfmt` for all 34 catalogs takes 0.5 s and gives 616 KB of `.mo` files. On top of that comes building and embedding libintl twice.
- **New strings.** Same as option A (`po/POTFILES`).

## Option C: a small runtime `.mo` reader in Swift

- **Format** (gettext manual §"MO Files"):
  - magic `0x950412de`, which also shows the byte order;
  - a revision field, N, and offsets to the original and translation descriptor tables (length and offset pairs);
  - an optional hash table, which can be skipped because "The size S of the hash table can be zero";
  - originals stored sorted, so binary search works;
  - context joined as `ctxt\x04msgid`, plural forms NUL-separated.

  Reading it in Swift with `Data` is perhaps 80 lines. Add the plural C-expression evaluator (about 60 lines in Swift; the Python one was 35) and the Germanic fallback.
- **Plural forms.** Exact gettext semantics, the same as option B.
- **Language choice.** Can be made the same as Bundle: call `Bundle.preferredLocalizations(from: availableMoLanguages, forPreferences: Locale.preferredLanguages)`. Ship empty `<lang>.lproj` folders (or `CFBundleLocalizations`) so AppKit agrees.
- **Build cost.** `msgfmt` in a Run Script phase. The build machine then needs GNU gettext (`brew install gettext`). Alternatively the reader could parse `.po` directly and skip `msgfmt`.
- **Trade-off.** No CLDR mapping step and no Apple-format edge cases. But it is our own lookup code to maintain, and it bypasses `Bundle`, `String(localized:)` and SwiftUI `Text` localization. Every SwiftUI label would need an explicit `Text(verbatim: tr("…"))`.

## How macOS-only strings are added and translated (all options)

1. Mark Swift strings with gettext-style calls, for example `_("Open in New Window")` and `ngettext("%d book", "%d books", n)`, where `_` and `ngettext` are Swift functions that look up the generated tables.
2. Add the `macos/**/*.swift` files to `po/POTFILES`. xgettext has no Swift language: its `--help` lists C, C++, ObjectiveC, …, Vala, Tcl, … but no Swift. It warns "extension 'swift' is unknown; will try C" and its C parser extracts the calls anyway.
   - Tested on a sample Swift file: it extracted `_()`, the `ngettext` plural pair and `// TRANSLATORS:` comments, and gave escaped quotes correctly. It ignored an unmarked interpolated string.
   - It warns on Swift `"""` multi-line literals. Marked strings must be plain one-line literals without `\(…)` interpolation; use `%@`/`%d` placeholders instead.
3. Regenerate the `.pot` (meson's `<project>-pot` target) and `msgmerge` the `.po` files as now. Translators see the macOS strings in the same `.po` files, and shared words like "Close" or "Search" are reused for free. This is Linux-inert: the strings exist in the catalog but Linux code never looks them up.
4. Xcode's alternative (Product → Export Localizations, `xcodebuild -exportLocalizations` producing XLIFF in a `.xcloc`, per Apple's "Exporting localizations") would create a second translation workflow and a second store. It is not recommended.

## Comparison

| | A: po → xcstrings → Bundle | B: libintl | C: own `.mo` reader |
| --- | --- | --- | --- |
| Plurals | CLDR via sample-number mapping. Lossless on today's catalogs except `oc`. | Exact gettext | Exact gettext |
| Context | Key `ctxt\x04msgid` (none used today) | `pgettext` must be reimplemented | Native |
| Language choice | `Bundle`, consistent with AppKit and per-app setting | Own algorithm: stops at `en`, no cross-region fallback, `LANG` from Terminal wins | `Bundle` if wired as above |
| Build | One script phase. Needs python3 or Swift plus vendored CLDR data. About 0.7 s | Universal libintl build plus embedding, plus msgfmt | msgfmt (GNU gettext on the build machine) or a `.po` parser |
| Runtime code | None (Foundation) | Shim module map | About 150 lines to maintain |
| SwiftUI `Text` | Works via `Bundle` lookup | Manual | Manual |

## Not verified

- Wiring into a real Xcode target. I tested the CLI chain and a standalone Swift lookup, not a Run Script phase in `macos/*.xcodeproj` (no such project on this branch). Still unchecked: whether the script should copy `.lproj` folders itself or emit a `.xcstrings` that Xcode's `CompileXCStrings` rule picks up, and whether Xcode's catalog sync then touches the generated file.
- The `.xcstrings` JSON layout is from Apple's examples and what `xcstringstool compile` accepted. I found no published Apple schema.
- AppKit standard menu localization depending on `.lproj` or `CFBundleLocalizations`: from platform knowledge, not tested here.
- libintl behaviour on a real Finder-launched app, and the `zh-Hant-TW` → `zh_TW` path, read from source only.
- `ie` (Interlingue) and `oc`: unknown whether macOS lets users pick them, and so whether those `.lproj` folders are ever used.
- `po2prop`'s handling of plurals in the `strings` dialect was not checked; `.strings` cannot hold plurals anyway.

## Sources

- Repo: `po/meson.build`, `po/POTFILES`, `po/LINGUAS`, `po/*.po`, `po/com.github.johnfactotum.Foliate.pot`, `CONTRIBUTING.md:37-46`, `src/book-viewer.js:26-43,215`, `src/reader/reader.js:268-272,492-495,516-524`, `src/library.js:46-89,530`, `src/main.js:25-26`, `src/app.js:196-205`, `src/annotations.js:649`.
- Apple: [Localizing and varying text with a string catalog](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog); [Exporting localizations](https://developer.apple.com/documentation/xcode/exporting-localizations); [Choosing localization regions and scripts](https://developer.apple.com/documentation/xcode/choosing-localization-regions-and-scripts); [Bundle.preferredLocalizations](https://developer.apple.com/documentation/foundation/bundle/preferredlocalizations); [Change the language your Mac uses](https://support.apple.com/guide/mac-help/mh26684/mac); `xcrun xcstringstool help compile|extract` (Xcode 26.6).
- GNU gettext manual: [MO Files](https://www.gnu.org/software/gettext/manual/html_node/MO-Files.html), [Plural forms](https://www.gnu.org/software/gettext/manual/html_node/Plural-forms.html), [Locale Environment Variables](https://www.gnu.org/software/gettext/manual/html_node/Locale-Environment-Variables.html); source `gettext-runtime/intl/{dcigettext.c,langprefs.c,plural-exp.c}` (autotools-mirror/gettext master); gnulib `lib/localename-unsafe.c`; `msgcat`/`xgettext --help` (gettext 1.0).
- CLDR: [`cldr-json/cldr-core/supplemental/plurals.json`](https://github.com/unicode-org/cldr-json/blob/main/cldr-json/cldr-core/supplemental/plurals.json).
- Translate Toolkit: `translate/storage/properties.py`, `translate/storage/stringsdict.py`, `translate/convert/` (github.com/translate/translate). Weblate: `docs/formats/apple.rst`, `stringsdict.rst` (github.com/WeblateOrg/weblate).
