# Grilling: Preferences on macOS

Type: grilling
Status: open
Map: ../map.md

## Question

Linux keeps preferences in GSettings (dconf), not in files (`03-shell-renderer-contract.md`), so they can't move between machines the way the data folder does. What replaces it on macOS? Settle:
- which GSettings keys the macOS app needs, and which it drops (read the schema under `data/`);
- where they live: `UserDefaults` (the stopgap in the reader-only milestone's slice 07), or a file, and whether any should follow the data folder between machines;
- the per-language voice choice from `15-tts-in-swift-shell.md`, and the appearance settings;
- the Settings window (Foliate › Settings…, greyed in `09-design-reader-window.md`): what it holds and when it ships;
- how this connects with the user stylesheet and themes under `$XDG_CONFIG_HOME` on Linux.
