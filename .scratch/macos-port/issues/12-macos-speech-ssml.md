# Research: macOS speech synthesis and the TTS path's SSML marks

Type: research
Status: open
Map: ../map.md

## Question

Linux Foliate reads aloud through speech-dispatcher (`src/speech.js`, `src/tts.js`): foliate-js produces SSML with `<mark>` elements, and the Shell follows the marks to highlight and move through the text. Can macOS do the same? Check, from Apple's documentation and headers: whether `AVSpeechSynthesizer` accepts SSML (`AVSpeechUtterance(ssmlRepresentation:)`) on macOS 14+, which SSML elements it supports, and whether it reports `<mark>` positions (e.g. `speechSynthesizer(_:willSpeakMarker:utterance:)`, `AVSpeechSynthesisMarker`) or only character ranges; how pausing, resuming, rate, pitch and voice selection work; and whether the Web Speech API in WKWebView is a usable alternative. Describe how the Linux code uses the marks, so the gap is concrete.
