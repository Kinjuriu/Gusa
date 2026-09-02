# SPEC V — Voice + Words lane (speech in, speech out, simplifier, Worker)

**Developer:** Kevin (@future-centaur) · **Branch:** `feat/v/V1.1-speech-in` (first task; then V1.3, W0.5, V1.4, V1.5; V2.2 in Stage 2) · **Reviewer:** Ian
**Owns:** `lib/services/voice/`, `lib/services/simplify/`, `lib/services/launcher/` (stretch), `proxy/`, `test/services/`, `test/fixtures/sentences_30.json`
**Reads:** [`TEAM-PLAN.md`](../TEAM-PLAN.md) §3–4, [`DECISIONS.md`](../DECISIONS.md) D-003 D-004 D-006 D-013 D-014 D-015 D-016, [`WIREFRAMES.md`](../WIREFRAMES.md) screen 2, [`SPEC.md`](../SPEC.md) §5, §19–22, §37–38

Dispute anything here in your PR.

## Goal

Hear what a person says, cut it down to what a Braille reader needs, propose replies, and speak the user's answer back. Android speech both ways in Stage 1. One Cloudflare Worker that adds Claude reply suggestions (Stage 1) and an ElevenLabs voice (Stage 2). Every cloud path has an offline path that the caller cannot tell apart.

## Ports you implement

```dart
abstract class VoicePort {
  Future<String?> listenOnce({Duration listenFor = const Duration(seconds: 8), void Function(String partial)? onPartial});
  Future<void> speak(String text);   // ElevenLabs online (Stage 2), Android TTS offline; caller never knows which
  Future<void> stop();
  Stream<VoiceState> get state;      // idle, listening, speaking, error
}

class SimplifiedMessage { final String short; final List<String> replies; final bool fromAi; }
abstract class SimplifierPort { Future<SimplifiedMessage> simplify(String spoken); }
```

## V1.1 · Speech in (M) — start here

File: `lib/services/voice/android_speech_in.dart`, the only file that imports `speech_to_text`.

- Initialise once; request microphone permission through the plugin; surface `VoiceError.noPermission`, `noRecognizer`, `network`, `timeout` as the `error` state with a message Lane A can show.
- `listenOnce`: `listenFor` 8 s, `pauseFor` 3 s, partial results forwarded to `onPartial`, returns the final text or null on timeout.
- Locale from Settings (default `en-KE`, fall back to `en-US` if the phone lacks it).

Verify on a phone: a sentence recognised with data on, then with data off (note whether this phone recognises offline; many do not, that is a device fact to record, not a bug). Put both results in the PR.

## V1.2 · Speech out, Android (S)

File: `lib/services/voice/android_speech_out.dart`, the only file that imports `flutter_tts`. `awaitSpeakCompletion(true)`, completion handler drives the `speaking → idle` transition; rate and pitch from Settings; a queue so two `speak` calls do not overlap; `stop` clears it.

## V1.3 · Rule-based simplifier (M)

File: `lib/services/simplify/rule_based_simplifier.dart`. No network, no plugin.

Steps, in order: trim and collapse whitespace → split into sentences → drop filler phrases from a list you keep in `filler_phrases.dart` (start with: `um`, `uh`, `please`, `would you like to`, `do you want to`, `i was wondering if`, `i think`, `just`, `kind of`, `you know`) → keep every number, date word and capitalised word → uppercase → wrap at 40 characters → at most 3 lines, the rest dropped.

Replies: if the original ends with `?`, `[YES, NO, REPEAT]`; otherwise `[OK, REPEAT]`. `fromAi: false`.

Fixtures: `test/fixtures/sentences_30.json`, 30 entries `{spoken, short, replies}`. Include the spec's own examples: "Would you like to attend the event tomorrow?" → `EVENT TOMORROW.\nATTEND?`, and "Your booking scheduled for Wednesday afternoon has unfortunately been rescheduled to Thursday at 9 AM" → `BOOKING CHANGED.\nTHURSDAY 9 AM.` Tests run all 30.

## W0.5 · Worker skeleton (M)

Folder: `proxy/` (TypeScript, Cloudflare Workers, `wrangler`). Routes:

| Route | Body | Returns |
|---|---|---|
| `POST /ai/message` | `{spoken: string, locale?: string}` | `SimplifiedMessage` JSON |
| `POST /voice/tts` | `{text: string}` | `audio/mpeg` bytes |

- `x-gusa-secret` header checked against `GUSA_SHARED_SECRET`; 401 otherwise.
- zod validation of every body; 400 with a reason.
- Rate limit: per-IP, 30 requests per minute, in KV.
- Spend guard: a monthly request counter in KV; over `MONTHLY_CAP` return 503 with `{fallback: true}` so the app goes offline-mode gracefully.
- Provider adapters behind `AI_PROVIDER=claude|openai` and a single `tts` adapter. Recorded provider responses in `proxy/test/fixtures/` so `npm test` (vitest) runs with no keys.
- Secrets: `ANTHROPIC_API_KEY`, `ELEVENLABS_API_KEY`, optionally `OPENAI_API_KEY`, set with `wrangler secret put`. Never in the repo, never in the app.

## V1.4 · Claude reply suggestions (M)

Worker side: `@anthropic-ai/sdk`, model `claude-opus-5`, structured output (`output_config.format` with a JSON schema for `{short: string, replies: string[] (max 3)}`), `output_config.effort: "low"`, `max_tokens` small. **Read the Anthropic TypeScript SDK docs for the exact structured-output call before writing it; do not guess field names from memory.** System instruction: shorten to at most 3 lines of 40 uppercase characters, keep numbers, dates and names, propose up to 3 replies of at most 12 characters, uppercase, no questions.

App side: `lib/services/simplify/claude_simplifier.dart` calls the Worker with a 3-second budget (Dio timeout), sends **only** `spoken` and `locale`, and on any failure or timeout returns `RuleBasedSimplifier.simplify(spoken)`. `fromAi` tells the UI which path ran, for the evals only; the screen never shows it.

Tests: the 30 fixtures through the live call once, results checked for schema validity, uppercase, ≤ 12-char replies, no `?` in replies; Worker unit tests use recorded responses.

## V1.5 · Evals and cost (S)

`docs/AI-EVALS.md`: p95 latency from 50 calls on a phone over mobile data, cost per message (from `usage` in the response), fallback rate. If p95 is above 3 s, say so; the model choice is Ian's (D-016).

## Stage 2 · V2.2 ElevenLabs voice (M)

Worker `/voice/tts` calls the ElevenLabs text-to-speech endpoint for one chosen voice and streams the mp3 back. App: `lib/services/voice/elevenlabs_speech_out.dart` plays it with `just_audio`, 2-second budget then Android voice. On first launch with network, synthesise `YES`, `NO`, `OK`, `REPEAT` once and cache them in app storage so quick replies start in under 200 ms. `VoicePort.speak` picks the provider; nothing above it knows.

## Definition of done, every PR

- [ ] Task ID in the PR title, one task per PR, target `develop`
- [ ] `flutter analyze` clean, `flutter test` green; `npm test` green for `proxy/` PRs
- [ ] Phone video or recording for V1.1, V1.2, V2.2, with data on and off
- [ ] Plugin imports confined to the adapter files named above
- [ ] No key, no user sentence, no audio in any log

## How to start

```bash
git fetch && git checkout feat/v/V1.1-speech-in     # created for you from develop
flutter pub get && flutter test
cd proxy && npm ci && npm test && npx wrangler dev    # once W0.5 exists
```

## Report format at each PR

Five lines: done / diverged / blocked · what you changed from this spec and why · phone tested on · anything the App lane must know.
