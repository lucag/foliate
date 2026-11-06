# Research: macOS speech synthesis and the TTS path's SSML marks

Type: research
Status: resolved
Map: ../map.md

## Question

Linux Foliate reads aloud through speech-dispatcher (`src/speech.js`, `src/tts.js`): foliate-js produces SSML with `<mark>` elements, and the Shell follows the marks to highlight and move through the text. Can macOS do the same? Check, from Apple's documentation and headers: whether `AVSpeechSynthesizer` accepts SSML (`AVSpeechUtterance(ssmlRepresentation:)`) on macOS 14+, which SSML elements it supports, and whether it reports `<mark>` positions (e.g. `speechSynthesizer(_:willSpeakMarker:utterance:)`, `AVSpeechSynthesisMarker`) or only character ranges; how pausing, resuming, rate, pitch and voice selection work; and whether the Web Speech API in WKWebView is a usable alternative. Describe how the Linux code uses the marks, so the gap is concrete.

## Context

Findings: branch `research/macos-speech-ssml`, commit `99978e2`, file `.scratch/macos-port/research/macos-speech-ssml.md`.

## Answer

**Yes, with small adaptations.** On macOS 14+, `AVSpeechSynthesizer` can replace speech-dispatcher without changing the Renderer's TTS contract (`initTTS`/`start`/`resume`/`prev`/`next`/`from`/`setMark`). `AVSpeechUtterance(ssmlRepresentation:)` accepts foliate-js's `<speak>` documents. `speechSynthesizer(_:willSpeak:utterance:)` reports each `<mark name="N"/>` as an `AVSpeechSynthesisMarker` with `.bookmark` and `bookmarkName == "N"`, the same string Linux gets from SSIP `700 INDEX_MARK`. The SSML behaviour below comes from test runs on macOS 26.7.1, because Apple doesn't document it.

- **How Linux uses the marks:** foliate-js puts a numbered `<mark>` before every word (`src/foliate-js/tts.js:24-45,99-119`), one SSML document per block. The Shell reads the mark from each 7xx event (`src/speech.js:46-53`) and calls `tts.setMark`, which highlights the word (`src/tts.js:72-73`, `src/book-viewer.js:719`). `702 END` moves to the next block (`src/tts.js:76,107-113`). Pause is really a stop, and resume re-speaks from the last mark (`src/tts.js:44-53,85-95`).
- **Gap 1:** a bare `<emphasis>` (foliate-js emits one with no `level`, `tts.js:66-67`) is dropped, text and marks included. Fix: add a level, or unwrap it.
- **Gap 2:** for SSML utterances, the `rate` and `pitchMultiplier` properties are ignored. The Shell wraps the content in `<prosody rate pitch>`, mapping from the -100..100 sliders. The rate scale isn't linear.
- **Gap 3:** mark order relative to word events varies, and two marks once arrived reversed. The Shell drops any mark lower than the last one it forwarded. A mark inside `<phoneme>` isn't reported, so that one word isn't highlighted.
- **Works directly:** `didFinish`/`didCancel` replace `702`/`703`. `stopSpeaking(at:)`, native pause and continue (marks keep coming after resume), `<break>`, `<lang>`, `<phoneme>` and `<prosody rate>` all work. There are voice lists and selection (Linux has no voice picker today). `NSSpeechSynthesizer` is deprecated; don't use it.
- **Ruled out:** the Web Speech API in WKWebView. WebKit builds the utterance from plain text, with word boundaries only and no SSML or marks (`PlatformSpeechSynthesizerCocoa.mm:166,306-318`).
- **Not verified:** behaviour on macOS 14 and 15 or with other voices; `<prosody pitch>` and volume; real chapter-length SSML; the offline `write(...)` marker callback (it never fired); Web Speech in a live WKWebView.
