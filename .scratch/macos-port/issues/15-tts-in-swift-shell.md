# Grilling: Read-aloud in the Swift Shell

Type: grilling
Status: open
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
