# Research: macOS speech synthesis and the TTS path's SSML marks

Ticket: `.scratch/macos-port/issues/12-macos-speech-ssml.md`
Date: 2026-11-06
foliate-js submodule commit read: `399248a67a8862ffb5e6463a33f9d52b317ca2eb`.
SDK read: Xcode MacOSX SDK 26.5, `AVFAudio.framework/Headers/AVSpeechSynthesis.h` (header lines are cited below as `AVSS.h:N`).
Probes run on: macOS 26.7.1 (25G241), voice `com.apple.voice.compact.en-US.Samantha`.
WebKit read: `main` at `69d63dfe24f781184fc78d6ee34a7a6f11f3ab87`.
speech-dispatcher read: `brailcom/speechd` `master` at `8972b116`, `doc/ssip.texi`.

Sources are tagged **[header]**, **[Apple docs]**, **[WebKit]**, **[SSIP]**, **[code]** (this repo) or **[probe]**. A **[probe]** is a throwaway Swift script, run on the machine above. Probes are evidence for that OS build only. Apple does not document which SSML elements are supported, so the element-level findings come from probes alone.

## Answer

**Yes. `AVSpeechSynthesizer` can replace speech-dispatcher with the SSML foliate-js already generates, and it reports `<mark>` by name.** On macOS 14+, `AVSpeechUtterance(ssmlRepresentation:)` accepts foliate-js's `<speak>` documents. The delegate's `speechSynthesizer(_:willSpeak:utterance:)` delivers each `<mark name="N"/>` as an `AVSpeechSynthesisMarker` with `mark == .bookmark` and `bookmarkName == "N"`. That is the same name the Linux Shell gets from SSIP's `INDEX_MARK` event and passes straight to `tts.setMark`. The Renderer-side contract (`initTTS` / `start` / `resume` / `prev` / `next` / `from` / `setMark`) can stay unchanged.

Four things differ, and the macOS Shell has to handle them:

1. **A bare `<emphasis>` is silently dropped, text included.** foliate-js wraps `<em>`/`<strong>` in `<emphasis>` with no `level` (`tts.js:66-67`). On macOS that text, and any marks inside it, are neither spoken nor reported **[probe]**. `<emphasis level="moderate">` or `level="strong"` works. Fix: the Shell (or foliate-js) adds `level="moderate"`, or unwraps the element.
2. **Rate and pitch must go in the SSML.** For SSML utterances, `rate` and `pitchMultiplier` are ignored **[header] [Apple docs]**. Wrap the content in `<prosody rate=… pitch=…>`. `rate` was confirmed to take effect **[probe]**; `pitch` was not measured.
3. **Pause and resume can be native.** `pauseSpeaking(at:)` and `continueSpeaking()` work on SSML utterances and marks keep coming after resume **[probe]**. Linux instead implements pause as stop, then re-speaks from the last mark (`src/tts.js:92-95`, `85-91`). That path works on macOS too and is still needed when rate or pitch changes.
4. **Marks can arrive slightly out of order.** Bookmark and word markers for the same word arrive in the same run-loop tick, sometimes bookmark first and sometimes word first. Once, two consecutive bookmarks (`4`, `3`) were delivered reversed in the same tick **[probe]**. foliate-js names marks with increasing integers (`tts.js:41`), so the Shell can drop any mark lower than the last one it forwarded.

The **Web Speech API in WKWebView is not a usable alternative** for this design. WebKit's Cocoa backend builds the utterance with `speechUtteranceWithString:` (plain text, no SSML) and only emits word `boundary` events with a character index. It has no mark/bookmark events **[WebKit]**. Using it would mean rewriting foliate-js's TTS module around plain text plus an offset map. That is possible, but it is a Renderer change, where the AVFoundation path needs none.

## How Linux uses the marks today

Pipeline, Renderer to Shell and back:

- **Segmentation (Renderer).** `View.initTTS(granularity = 'word', highlight)` builds a `TTS` over the current section document. The default `highlight` is `renderer.scrollToAnchor(range, true)`, which scrolls to the word and selects it (`src/foliate-js/view.js:580-586`; `paginator.js:918-919`) **[code]**. The Linux Shell calls `initTTS` with no arguments (`src/book-viewer.js:403`, `712`), so it gets word granularity and select-to-highlight.
- **Blocks.** `getBlocks` cuts the document into one `Range` per block-level element (`tts.js:6-12`, `123-143`). Each block becomes one SSML document, and one SSML document is one utterance.
- **Marks.** For each block, `getFragmentWithMarks` runs `Intl.Segmenter` (word granularity, word-like segments only) over the text. It inserts a `<foliate-mark data-name="0">`, `"1"`, … before each word into a cloned fragment, and keeps a `Map` from name to live-document `Range` (`tts.js:24-45`, `99-119`). `fragmentToSSML` then turns the fragment into an SSML `<speak xmlns="http://www.w3.org/2001/10/synthesis" xml:lang=…>` document (`tts.js:47-97`):
  - `foliate-mark` → `<mark name>` (60-63)
  - `<br>` → `<break/>` (64-65)
  - `<em>`/`<strong>` → `<emphasis>` with no level (66-67)
  - any `lang`/`xml:lang` → `<lang xml:lang>` (69-73)
  - `ssml:ph` → `<phoneme alphabet ph>` (75-83)
- **Starting mid-block.** `#speak(doc, getNode)` copies the SSML and deletes every node before a given `<mark>`, so speech starts at that word (`tts.js:223-235`). `start()` and `resume()` start from `#lastMark` (236-246). `from(range)` ("Speak from here") finds the first mark at or after the selection (259-270). `prev`/`next` move whole blocks and reset `#lastMark` (247-258).
- **Following (`setMark`).** `setMark(name)` looks up the word's `Range`, records it as `#lastMark`, and calls `highlight(range)` (`tts.js:271-277`). **This is the whole contract: the Shell has to call `setMark(name)` with the `<mark name>` string at the moment that word is about to be spoken.**
- **Shell transport (`src/speech.js`).** The Shell spawns `speech-dispatcher --spawn` and connects to its Unix socket (13-34). It sends `SET SELF SSML_MODE on` and `SET SELF NOTIFICATION ALL on` (86-87), then `SPEAK` + the SSML + `.` (117-120). Asynchronous 7xx events are parsed so that the third data line is the mark name (46-53). In SSIP, `700` is `INDEX_MARK` with lines `msg_id`, `client_id`, `index_mark`; `702` is `END`; `703` is `CANCELED` **[SSIP `ssip.texi:1305-1340`]**. `speak()` returns an async iterator that finishes on 702/703 (121-137).
- **Shell control (`src/tts.js`).** `#speak` loops over events: on a mark it calls `emit('highlight', mark)`, and `book-viewer.js:719` routes that to `reader.view.tts.setMark(mark)`. On `END` it calls `forward()`, which gets the next block's SSML from `tts.next()` and speaks it (66-77, 107-113). `book-viewer.js:711-719` maps the signals to `tts.start/resume/prev/next` via `#exec` (`book-viewer.js:403-408`). "Speak from here" goes `reader.js:425-429` → `book-viewer.js:956-957` → `tts_box.speak(ssml)`.
- **Pause is not SSIP PAUSE.** `pause()` sends `STOP self` and sets the state to `paused` (`tts.js:92-95`). The next `start()` sees `paused` and asks the Renderer for `tts.resume()`, i.e. SSML truncated at `#lastMark` (85-91). `SSIPClient.pause/resume` (`speech.js:139-144`) are never called.
- **Rate and pitch.** Two scales from -100 to 100 (`ui/tts-box.ui:43-95`) map directly to `SET self RATE n` / `PITCH n`. SSIP defines both as integers in -100..100 **[SSIP `ssip.texi:1013-1036`]** (`speech.js:148-153`). A slider change does stop → set → restart from the last mark if it was playing (`tts.js:44-53`).
- **Voices.** `listSynthesisVoices()` exists (`speech.js:154-160`), but the voice dropdown is commented out (`ui/tts-box.ui:11-31`). Linux has no voice choice today; the speech-dispatcher default is used.

So the macOS Shell needs: speak one SSML string; get a callback per `<mark>` name; know when the utterance has finished (to call `next`) or been cancelled; stop; and set rate and pitch. Pause/resume and voice listing are nice-to-haves.

## AVSpeechSynthesizer on macOS 14+

### SSML input

- `init?(ssmlRepresentation:)` / `+speechUtteranceWithSSMLRepresentation:` are available from macOS 13.0 and **return nil for invalid SSML** **[header `AVSS.h:173-193`] [Apple docs]**. The probe agrees: an unclosed tag and plain text without `<speak>` both returned nil.
- The header discussion (`AVSS.h:182-191`) says:
  - SSML that requests voice attributes "may split a single utterance into multiple parts, each sent to the appropriate synthesizer".
  - If no voice matches, the utterance's `voice` is used, otherwise the system default.
  - "properties that affect the prosidy of a voice such as `rate`, `pitchMultiplier` … will not apply to an utterance that uses an SSML representation."
- **Apple does not list the supported SSML elements** (the `init(ssmlRepresentation:)` doc page has only the text above) **[Apple docs]**. The table below comes from **[probe]**: `write(_:toBufferCallback:)` audio frame counts, plus delegate word/bookmark events on the `speak` path.

| Element (as foliate-js emits it unless noted) | Result on macOS 26.7.1 |
|---|---|
| `<speak xmlns=… xml:lang="en">`, with or without `<?xml?>` | Accepted |
| `<speak>` without namespace | Accepted |
| `<mark name="N"/>` | Reported as `.bookmark` with `bookmarkName == "N"`, `textRange == {0,0}` |
| `<break/>`, `<break time="2s"/>` | Works (adds silence; 2s break ≈ +2s of audio) |
| `<emphasis>` **with no `level`** | **Content dropped**: same audio length as the sentence without the word; no word marker; marks inside it not reported. `speechString` omits the text |
| `<emphasis level="moderate">` / `level="strong"` | Works; the word is spoken and its mark is reported |
| `<lang xml:lang="fr">` | Works on the `speak` path (French words spoken, marks inside reported). Through `write(_:toBufferCallback:)` the audio came out *shorter* than the base sentence, which fits the header's "split into multiple parts" note. Not investigated further |
| `<phoneme alphabet="ipa" ph="…">text</phoneme>` | Spoken (audio longer, ~0.85s gap). **A `<mark>` inside `<phoneme>` is not reported.** foliate-js puts word marks inside the phoneme text, so that word's highlight is lost; the next mark arrives normally |
| `<prosody rate="200%">` / `"50%"` | Works: 9660 / 24478 frames vs. 18791 at default. 50% is not 2× slower, so the scale is not linear |
| `<say-as>`, `<sub alias>`, `<p>`, `<s>` | Accepted and spoken (not emitted by foliate-js) |

### Mark reporting

- `AVSpeechSynthesizerDelegate.speechSynthesizer(_:willSpeak:utterance:)` (`willSpeakMarker:`) is **macOS 14.0+** **[header `AVSS.h:308`] [Apple docs]**.
- `AVSpeechSynthesisMarker.Mark` has `.phoneme`, `.word`, `.sentence`, `.paragraph` and `.bookmark` (macOS 13.0) **[header `AVSS.h:36-42`]**. Apple's docs describe `.bookmark` as "A Speech Synthesis Markup Language (SSML) mark tag".
- `bookmarkName` and `phoneme` are macOS 14.0+ **[header `AVSS.h:325-326`] [Apple docs]**.
- `textRange` is documented as "The location and length of the pertaining speech request's **SSML text**" **[header `AVSS.h:322`]**. The probe confirms that `.word` markers index into the **SSML source string**, in UTF-16 units: e.g. `{119,5}` = "Hello" in the full `<?xml…?><speak…>` string. They do not index `speechString`. The older `willSpeakRangeOfSpeechString:` returns the same SSML-source range, so it is out of bounds for `speechString`. Bookmarks carry `textRange {0,0}`; the name is what identifies them.
- **Timing and order.** Each bookmark arrives in the same tick as the `.word` marker of the word that follows it (within 10 ms), so highlighting stays in sync. Within that tick the order varies, and in one run marks `4` and `3` were reversed. Integer names make it easy to drop stale ones.
- **Observed, not documented:** on this build, `write(_:toBufferCallback:toMarkerCallback:)` produced audio but **never called the marker callback**, not even for words. Only the delegate on `speak(_:)` delivered markers. The Shell should use `speak(_:)` + the delegate.

### End, cancel, pause, resume

- `didStart`, `didFinish`, `didPause`, `didContinue` and `didCancel` delegate methods exist from macOS 10.14 **[header `AVSS.h:300-304`]**. `didFinish` maps to SSIP `702 END` → `forward()`. `didCancel` maps to `703`.
- `stopSpeaking(at:)`, `pauseSpeaking(at:)` and `continueSpeaking()` take a `.immediate` / `.word` boundary **[header `AVSS.h:16-19`, `250-252`]**. Apple docs: "After pausing, you can resume the speech from its paused point or stop the speech entirely and remove all remaining utterances in the queue."
- **[probe]** `pauseSpeaking(at: .word)` on an SSML utterance returned true and fired `didPause`. The marker for the word in progress was still delivered just after. `continueSpeaking()` resumed 1 s later and the remaining marks followed. So the macOS Shell *may* use native pause. Keeping Linux's stop-and-re-speak-from-`#lastMark` behaviour also works with no new code paths.
- Utterances are queued; "Enqueing the same AVSpeechUtterance that is already enqueued or is speaking will raise an exception" **[header `AVSS.h:234-235`]**. The synthesizer has to be retained by the app **[Apple docs]**.

### Rate, pitch, volume

- For plain-string utterances: `rate` takes `AVSpeechUtteranceMinimumSpeechRate`..`Maximum` (default `AVSpeechUtteranceDefaultSpeechRate`; WebKit's comment gives the range as 0 to 1 with 0.5 as default), `pitchMultiplier` takes 0.5-2, `volume` takes 0-1 **[header `AVSS.h:45-47`, `203-205`]**. **None of these apply to SSML utterances** **[header `AVSS.h:188-189`]**.
- So the Shell maps the -100..100 sliders to SSML `<prosody rate="X%" pitch="Y%">` around the `<speak>` children. The truncation in `TTS.#speak` keeps `<speak>` as the root, so wrapping its children is safe. A rate or pitch change still needs stop → re-speak from the last mark, as on Linux.
- Whether `utterance.volume` is honoured for SSML was not checked.

### Voices

- `AVSpeechSynthesisVoice.speechVoices()`, `voiceWithLanguage:` (BCP-47, prefers enhanced quality) and `voiceWithIdentifier:` (returns nil if the voice isn't downloaded) are documented **[header `AVSS.h:111-140`]**. Voices have `identifier`, `name`, `language`, `quality` (default/enhanced/premium), `gender` and `voiceTraits` **[header `AVSS.h:142-153`]**.
- `AVSpeechSynthesisAvailableVoicesDidChangeNotification` is macOS 14+ **[header `AVSS.h:97`]**. Personal Voice needs `requestPersonalVoiceAuthorization` (macOS 14+) **[header `AVSS.h:276`]**.
- **[probe]** `speechVoices()` returned 180 voices. Setting `utterance.voice` works for SSML utterances. The header says SSML voice attributes can override it.
- Voice choice would be a macOS addition; Linux has no voice selector today.
- The SSML `xml:lang` that foliate-js sets on `<speak>` (from the book's language) does not choose the voice on its own. The Shell should pick `AVSpeechSynthesisVoice(language:)` from the book language (or the user's choice). Inline `<lang>` changes are handled, as tested above.

### NSSpeechSynthesizer

- AppKit's `NSSpeechSynthesizer` is `API_DEPRECATED("Use AVSpeechSynthesizer in AVFoundation instead", macos(10.3, 14.0))` (`AppKit.framework/Headers/NSSpeechSynthesizer.h:19`) **[header]**. Do not use it.

## Web Speech API in WKWebView

- **Exposure.** `window.speechSynthesis` sits behind `EnabledBySetting=SpeechSynthesisAPIEnabled` (`Source/WebCore/Modules/speech/DOMWindow+SpeechSynthesis.idl`). The preference is `status: embedder`, `defaultValue: true`, `disableInLockdownMode: true` (`Source/WTF/Scripts/Preferences/UnifiedWebPreferences.yaml:6093-6101`) **[WebKit]**. It should therefore exist in a plain WKWebView. Not verified in a running WKWebView.
- **No SSML.** `PlatformSpeechSynthesizerCocoa.mm:166` builds `speechUtteranceWithString:utterance->text()`. SSML would be read out as literal text **[WebKit]**.
- **No marks.** The only boundary delegate WebKit implements is `willSpeakRangeOfSpeechString:`. It always emits `SpeechWordBoundary`, with the comment "AVSpeechSynthesizer only supports word boundaries" (`PlatformSpeechSynthesizerCocoa.mm:306-318`). `willSpeakMarker:` is not used **[WebKit]**.
- Rate is remapped from Web Speech's 0.1-10 scale to AVSpeech's (`mapSpeechRateToPlatformRate:`, lines 123-133). Pitch goes straight to `pitchMultiplier`; pause/resume/cancel are native (lines 168-171, 197, 207, 224). Voices are system voices only (`voice.isSystemVoice`, line 341) **[WebKit]**.
- **Consequence.** foliate-js `tts.js` returns SSML strings, and its contract is mark names. To use Web Speech, foliate-js would need a second output mode: per-block plain text plus a char-offset → `Range` table driven by `boundary` events (`charIndex`). That is a Renderer change and a fork from the Linux path. The only gain would be keeping TTS entirely inside the Renderer.

## Not verified

- Behaviour on macOS 14.x and 15.x. All probes ran on macOS 26.7.1; the API surface is from the SDK 26.5 header, and its availability annotations say macOS 14.0 for `willSpeakMarker` / `bookmarkName`. The bare-`<emphasis>` drop, the mark inside `<phoneme>`, and the silent `write` marker callback may differ on earlier releases.
- Voices other than compact Samantha (en-US), including enhanced/premium, Siri and Personal Voice, and non-English voices for whole blocks.
- Whether `<prosody pitch>` and `utterance.volume` take effect on SSML. Only `<prosody rate>` was measured.
- Behaviour with long blocks (very large SSML strings) and with the full serialized output of a real book chapter. The probes used hand-built strings in foliate-js's format.
- Web Speech in an actual WKWebView: whether `speechSynthesis` exists there, needs a user gesture, or is affected by the app sandbox. Only WebKit source was read.
- Sandbox and hardened-runtime entitlements for `AVSpeechSynthesizer` in a distributed app (the probes ran unsandboxed via `swift`).
