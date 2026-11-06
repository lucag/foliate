# Grilling: Read-aloud in the Swift Shell

Type: grilling
Status: resolved
Blocked by: 11
Map: ../map.md

## Question

`12-macos-speech-ssml.md` shows `AVSpeechSynthesizer` can drive the Renderer's existing TTS contract, with three gaps. Settle:
- where the bare-`<emphasis>` fix lives: in foliate-js `tts.js` (which depends on `11-foliate-js-upstream-or-fork.md`) or as a Shell-side rewrite of the SSML before speaking;
- how the rate and pitch sliders map to `<prosody>` percentages, given the non-linear rate scale;
- whether pause uses native `pauseSpeaking`/`continueSpeaking` or keeps Linux's stop and re-speak from the last mark;
- whether to add a voice picker (Linux has none today);
- the read-aloud controls in the immersive reader window (`09-design-reader-window.md`) and the menu items;
- which milestone read-aloud ships in, and how it's checked on macOS 14 as well as 26.

## Answer

**`AVSpeechSynthesizer` behind Linux's existing TTS contract, with a Read Aloud popover in the pill. Read-aloud is the third milestone, after the library.**

- **How Linux does it** (for reference):
  - A popover holds Previous / Play-Pause / Next and Speed and Pitch sliders from −100 to 100 in steps of 5. Its voice dropdown is commented out (`src/ui/tts-box.ui:14-84`).
  - Speak from Here is in the selection popover (`src/ui/selection-popover.ui:30`).
  - EPUB media overlays share the controls (`src/book-viewer.js:821`).
- **`<emphasis>` fix:** in foliate-js. `tts.js:66-67` emits `level="moderate"`, as a change on the fork (`11-foliate-js-upstream-or-fork.md`) and an upstream PR. Linux is unaffected.
- **Speed and pitch:** Linux's −100…100 sliders (step 5) are kept, with the values carried in the SSML.
  - Speed maps geometrically to 0.5×–2× speaking speed, 1× at 0. The `<prosody rate>` percentage for each multiplier is calibrated by measuring words per minute during the build.
  - Pitch maps to `<prosody pitch>` from −50% to +50%; it's checked during the build, since the research didn't test it.
- **Playback:**
  - Pause uses native `pauseSpeaking(at: .word)` / `continueSpeaking()`.
  - Changing speed, pitch or voice stops and re-speaks from the last mark, as on Linux.
  - The Shell drops any mark lower than the last one it forwarded.
  - End and cancel map from `didFinish` / `didCancel`.
- **Voice:** a macOS-only picker listing the voices for the book's language, "System Voice" first, remembered per language. Linux is unchanged.
- **Controls:**
  - A 🔊 Read Aloud button in the top pill (`09-design-reader-window.md`), whose popover holds Previous / Play-Pause / Next, Speed, Pitch and Voice.
  - While speaking, the current word is highlighted, pages turn automatically, and the bottom overlay shows a compact ⏮ ⏯ ⏭ next to the slider.
  - Speak from Here is added to the selection popover.
  - Menus: Edit › Speech ▸ Start Speaking / Stop Speaking, Pause/Resume, Previous/Next Paragraph. No new default shortcuts.
- **Media overlays:** narrated EPUBs use the same controls, with the Renderer playing the audio. Speed becomes the playback rate, and pitch and voice are greyed out.
- **Testing:** on macOS 26 natively, and on macOS 14 in a VMware Fusion VM on the user's Intel Mac (Apple's virtualization can't run macOS guests on Intel). Check marks, `<emphasis level>`, `<phoneme>` and `<prosody>` with at least two voices.
