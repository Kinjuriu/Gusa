# Gusa — 4-Developer MVP Plan (v2, communication loop)

**Status:** DRAFT for team review · **Owner:** Ian (Ianodad) · **Date:** 2026-09-02 (v2, replaces the full-spec v1)
**Product spec:** [`docs/SPEC.md`](SPEC.md) · **Decisions:** [`docs/DECISIONS.md`](DECISIONS.md) · **Machine setup:** [`docs/SETUP.md`](SETUP.md)

---

## 0. Read this first

1. **The MVP is the communication loop, nothing else.** A person speaks. The user feels it as Braille vibrations. The user taps Braille back. The phone speaks the reply. That is SPEC §5 + §6 (Journey A and the six-dot reply). Screen reading, form filling, the accessibility service, the event-registration demo: all Phase 2 (D-012).
2. **Flutter only. No Kotlin.** Every native behaviour comes from a pub.dev plugin: `speech_to_text`, `flutter_tts`, `vibration`, `installed_apps`, `android_intent_plus`. The `android/` folder holds a manifest, not code (D-013).
3. **Minimal AI.** Message shortening is rule-based by default and runs offline. An OpenAI simplifier exists behind a build flag, off in the demo, on only if someone owns a key (D-014).
4. **Four lanes, split by layer.** App, Tactile, Input, Voice + Words. Each owns a folder and implements a Dart port. Fakes for every port exist from day one, so every lane builds and tests alone.
5. **Today's demo slice is the baseline.** Branch `spec/demo-slice-by-4` scaffolds the app, the ports, the fakes, and three lane stubs. Week 0 merges it into `develop`. Nobody starts from an empty folder.
6. **The central bet is only testable by people.** Whether Braille through a phone motor is readable is decided at the Stage 1 checkpoint with three real testers (§7).

---

## 1. How much four developers can accomplish

| Availability | Week 0 (baseline + CI) | Stage 1 · Build | Stage 2 · Integrate + tune | Braille-user test |
|---|---|---|---|---|
| Full-time, about 35 h/wk each | 1 day | Week 1 | Week 2 | Week 3 |
| Part-time, about 10 h/wk each | 3 days | Weeks 1–3 | Weeks 4–5 | Week 6 |

Confidence: **medium-high** for the code, **low** for the product bet. The code is small and fully unit-testable in Dart. Whether a person can read it is unknown until §7.

| Stage | What exists, in plain words |
|---|---|
| Week 0 | Demo slice merged to `develop`. Every dev builds and installs on their own phone. CI green. Ports and fakes in `lib/ports/`. Haptic encoding chosen (D-009). |
| Stage 1 | Each lane's real implementation replaces its fake, with tests. On a phone: speak a sentence, feel it; tap `YES`, hear it. Practice mode logs accuracy. |
| Stage 2 | Full loop wired without fakes. Quick replies. Gestures with haptic confirmations. Offline behaviour. Haptic timing tuned from practice data. Test matrix run on two phones. Go / pivot decided. |

---

## 2. Team split

| Lane | Developer | Owns (folders) | Implements | Skills |
|---|---|---|---|---|
| **A — App** | **Ian (Ianodad)** | `lib/app/`, `lib/features/`, `lib/ports/`, `lib/storage/` | Screens, settings storage, integration, demo script. Owns the port definitions and their fakes. | Flutter, state management, the spec |
| **T — Tactile** | *assign* | `lib/core/braille/`, `lib/core/haptics/`, `lib/core/practice/` | `BraillePort` (encode + decode), `HapticPort` (cells → vibration, confirmation codes), practice-mode logger | Dart, `vibration` plugin, patience for user testing |
| **I — Input** | *assign* | `lib/core/braille_keyboard/`, `lib/core/gestures/`, `lib/core/quick_reply/` | Six-dot keyboard widget (chords), gesture engine (§9), quick-reply selector | Dart, multi-touch handling, widget tests |
| **V — Voice + Words** | *assign* | `lib/services/voice/`, `lib/services/simplify/`, `lib/services/launcher/`, `proxy/` (flag only) | `VoicePort` (`speech_to_text` + `flutter_tts`), `SimplifierPort` (rule-based; AI behind flag), `LauncherPort` (stretch) | Dart, plugins, a little prompt work if the AI flag is ever on |

**Why by layer.** Four people touch four folders. Merge conflicts only happen in `lib/ports/`, and those are contract PRs that need both lanes. Lane A is the integrator: Ian is the first consumer of every port, so gaps surface in Lane A's PRs early.

**What the demo slice already split.** Today's slice used three lanes (Tactile, Voice, Launcher). The fourth developer takes Input, which the slice folds into Tactile. Splitting keyboard and gestures out of the Braille engine is the natural seam.

---

## 3. Ports are the contract (Week 0)

The contract is five Dart abstract classes in `lib/ports/`, lifted from the demo slice's `lib/features/home/ports.dart`, plus two additions marked **new**.

```dart
class Cell { final List<bool> dots; final String char; }          // dots[0] == dot 1

abstract class BraillePort {
  List<Cell> encode(String text);
  String decode(List<Cell> cells);          // new: the reply path
  bool validate(Cell cell);                 // new
}
abstract class HapticPort {
  Future<void> render(List<Cell> cells);    // a message, with character and word pauses
  Future<void> code(HapticCode code);       // new: success, error, listening, message, confirm (§9)
  Future<void> cancel();
}
abstract class VoicePort {
  Future<String?> listenOnce();
  Future<void> speak(String text);
  Future<void> stop();
}
abstract class SimplifierPort { Future<String> simplify(String spoken); }
abstract class LauncherPort {                // stretch
  Future<List<LaunchableApp>> installedApps();
  List<LaunchableApp> resolve(String phrase, List<LaunchableApp> apps);
  Future<void> launch(String package);
}
```

Rules:
- Every port has a fake in `lib/ports/fakes/`. The app runs fully on fakes with `--dart-define=GUSA_USE_FAKES=true`.
- A PR that changes a port updates the fake, the fixtures, and every consumer in the same PR, and is approved by Lane A and the implementing lane. Label `contract`.
- Fixtures live in `test/fixtures/`: 500-word Braille round-trip list, 30 spoken sentences with expected simplified output, gesture pointer streams.

---

## 4. Stage plan

Sizes are full-time developer days: **S** one or less, **M** two to three, **L** four to five. One GitHub issue per ID; the branch carries the ID.

### Week 0 · Baseline and setup

| ID | Lane | Task | Size | Verify by |
|---|---|---|---|---|
| W0.1 | A | Merge `spec/demo-slice-by-4` into `develop` once it runs Journey A on a phone. Move ports and fakes to `lib/ports/`, add `decode`, `validate`, `code()`. | S | App boots on fakes; `flutter test` green |
| W0.2 | A | CI (`flutter` job), branch protection on `develop` and `main`, CODEOWNERS, PR template, labels, milestones | S | Green check on a no-op PR |
| W0.3 | T | Choose the haptic encoding of a cell (D-009) and write the Beginner / Normal / Fast timing table into `docs/HAPTICS.md` | S | Table reviewed by Ian |
| W0.4 | all | `scripts/doctor.sh`, build, install on your own phone, post a screenshot in the Week 0 issue | S | Four screenshots |

**Week 0 exit:** four phones running the demo slice on fakes; CI green; ports merged; D-009 closed.

### Stage 1 · Build (each lane replaces its fake)

| ID | Lane | Task | Size | Depends on | Verify by |
|---|---|---|---|---|---|
| T1.1 | T | **BrailleEngine**, Grade 1 UEB uncontracted: letters, capital sign, number sign + digits, basic punctuation; `encode`, `decode`, `validate` | M | — | Round-trip on the 500-word list; invalid cells rejected |
| T1.2 | T | **HapticEngine**: cell → dot timeline → `Vibration.vibrate(pattern, intensities)`; modes; character and word pauses; pause / resume / repeat; `hasAmplitudeControl()` fallback; confirmation codes | M | T1.1, W0.3 | Timing tests; felt on a phone; video |
| T1.3 | T | **Practice mode logger**: chars per minute, errors, repeats, session CSV (SPEC §41) | M | T1.2 | CSV from one session |
| I1.1 | I | **Six-dot keyboard widget**: chord input with multi-touch, commit on release or timeout, echo through `HapticPort.code`, large-text mirror | M | T1.1 | Widget tests; typed `YES` on a phone; video |
| I1.2 | I | **GestureEngine**: double tap, long press, swipes, two-finger tap (SPEC §9) from raw pointer events, each with its haptic code | M | — | Synthetic pointer-stream tests; false-positive rate on a scribble fixture |
| I1.3 | I | **Quick-reply selector**: numbered options (1 YES, 2 NO, 3 REPEAT) chosen by tap count or swipe | S | I1.2 | Widget tests |
| V1.1 | V | **VoicePort in**: `speech_to_text` listen with partials, timeout, permission flow, errors mapped to haptic codes | M | — | Recognise a sentence on a phone, online and with data off |
| V1.2 | V | **VoicePort out**: `flutter_tts` with completion handler, rate and pitch from settings, queue | S | — | Speaks `Yes`; completion fires |
| V1.3 | V | **Rule-based simplifier**: uppercase, strip filler, split into short lines, cap length, keep numbers and names; 30 fixtures | M | — | All fixtures pass; runs with no network |
| V1.4 | V | *Flag only:* OpenAI simplifier via a Cloudflare Worker with structured output; off by default | M | V1.3 | Behind `GUSA_AI=on`; fixtures pass through both |
| A1.1 | A | Shell, settings storage (`shared_preferences`), Settings screen: Braille mode, haptic speed and intensity, voice rate | M | — | Change speed, feel the difference |
| A1.2 | A | **Conversation screen** (SPEC §5–6): Listen → feel → reply → speak, with states and haptic codes; repeat-last; large-text mirror | L | T1.2, I1.1, V1.1, V1.2 | Full loop on a phone using fakes, then real ports |
| A1.3 | A | **Braille Mode screen**: free typing → speak | S | I1.1 | Video |
| A1.4 | A | **Onboarding-lite**: how you receive, how you reply, practice (SPEC §35 steps 1, 2, 5) | M | A1.1 | Video |

**Stage 1 exit:** every fake replaced; on a phone, speak a sentence and feel it, tap `YES` and hear it; practice mode exports a CSV. **Then run the checkpoint (§7).**

### Stage 2 · Integrate and tune

| ID | Lane | Task | Size | Verify by |
|---|---|---|---|---|
| A2.1 | A | Wire real ports as the default build; fakes only behind the flag; end-to-end loop with quick replies and gestures | M | Run by a non-author on two phones |
| A2.2 | A | Offline behaviour: recogniser unavailable → haptic error + large-text prompt; TTS engine missing → prompt to install | S | Data off, still usable |
| T2.1 | T | Haptic tuning from practice CSVs; Beginner timings; word-pause length | M | Recognition accuracy before and after |
| I2.1 | I | Keyboard accuracy pass: chord timing window, palm rejection, edge taps | M | Error rate before and after |
| V2.1 | V | *Stretch:* app launcher by tap or speech from the demo slice's launcher lane | M | Opens WhatsApp, Chrome, Phone |
| all | all | Test matrix subset (SPEC §40): Braille accuracy, haptic recognition, gesture accuracy, offline, speech in, speech out, on two phones → `docs/TEST-RESULTS.md` | M | Checklist complete |

**Stage 2 exit:** the loop runs without fakes on two phones; test matrix filled; go / pivot decided; user session scheduled.

---

## 5. GitHub workflow

```
gusa/
├── lib/app/                 shell, router, theme                      A
├── lib/features/            conversation, braille_mode, settings, onboarding, practice  A
├── lib/ports/               the five ports + fakes                    A (contract PRs need both lanes)
├── lib/storage/             settings persistence                      A
├── lib/core/braille/        BrailleEngine                             T
├── lib/core/haptics/        HapticEngine                              T
├── lib/core/practice/       accuracy logger                           T
├── lib/core/braille_keyboard/  six-dot widget                         I
├── lib/core/gestures/       GestureEngine                             I
├── lib/core/quick_reply/    quick-reply selector                      I
├── lib/services/voice/      speech_to_text + flutter_tts              V
├── lib/services/simplify/   rule-based + optional AI                  V
├── lib/services/launcher/   installed_apps (stretch)                  V
├── proxy/                   Worker, only if GUSA_AI=on                V
├── android/                 manifest and Gradle config only, no Kotlin
├── test/                    mirrors lib/; fixtures in test/fixtures/
├── scripts/                 doctor.sh
└── docs/                    SPEC, TEAM-PLAN, DECISIONS, SETUP, HAPTICS, TEST-RESULTS
```

| Branch | Purpose | Protection |
|---|---|---|
| `main` | Demo-ready. Stage merges only. | PR, 2 approvals, checks green, no force-push |
| `develop` | Integration. Every task PR targets this. | PR, 1 CODEOWNER approval, checks green |
| `feat/<lane>/<id>-<slug>` | One task per branch, e.g. `feat/t/T1.1-braille-engine` | Delete after merge |
| `contract/<slug>` | Any change under `lib/ports/` | Lane A + implementing lane approve |

Rules: rebase on `develop` before opening a PR; squash-merge; PR title starts with the task ID; one lane's folders per PR unless it is a contract PR.

CODEOWNERS: `/lib/app/ /lib/features/ /lib/storage/ /docs/` → `@ianodad`; `/lib/ports/` → `@ianodad` plus all three lane owners; `/lib/core/braille/ /lib/core/haptics/ /lib/core/practice/` → tactile dev; `/lib/core/braille_keyboard/ /lib/core/gestures/ /lib/core/quick_reply/` → input dev; `/lib/services/ /proxy/` → voice dev.

Rhythm: **Monday 30 min** to pick issues and name blockers. **Friday 30 min** integration build from `develop`, CI attaches the APK to a pre-release, everyone installs it, one person demos. **Reviews within 24 h.**

---

## 6. Verification

| Check | What runs | Fails when |
|---|---|---|
| CI `flutter` on every PR | `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test`, `flutter build apk --debug`, APK uploaded as an artifact | Any lint, test, or build error |
| Fixture tests (inside `flutter test`) | Braille 500-word round trip; 30 simplifier sentences; gesture pointer streams | Any engine drifts from its fixtures |
| PR definition of done | Linked issue · tests · contract rule respected · **phone video for any T, I, V, or screen work** · docs updated · nothing logged that a user said | A box is unchecked |
| Friday APK | Built from `develop`, installed by all four | Anyone's phone fails the loop |
| Stage exit demo | Live on a phone in the Friday call against §4 exit criteria; results in `docs/TEST-RESULTS.md` with phone model and Android version | Any exit criterion missed |
| Device matrix | Two phones from different makers, one low-end; record `hasAmplitudeControl()`, TTS engine, recogniser availability with data off | A lane verifies on one phone only |

There is no Kotlin test job, no emulator job, no contract-schema job. The whole product is Dart, so `flutter test` is the safety net, and the phone is the truth.

---

## 7. Go / pivot checkpoint (end of Stage 1)

Three people who did not build it, at least one a Braille reader if possible, use practice mode for 15 minutes each.

| Measure | Go | Pivot |
|---|---|---|
| Character recognition after 10 min practice | ≥ 70 % | < 50 % |
| Words per minute on a 5-word message | ≥ 5 | < 2 |
| Would use it again | 2 of 3 | 0 of 3 |

Pivot options, ranked: change the cell encoding (D-009), slow Beginner mode further, or bring Bluetooth Braille-display output forward from Phase 2 and keep the six-dot keyboard as input. Ian decides; recorded in DECISIONS.md.

---

## 8. Risks and owners

| # | Risk | Mitigation | Owner |
|---|---|---|---|
| 1 | Braille through one motor may be too slow or unreadable (rough estimate ~1.2 s per character, under 10 wpm) | §7 checkpoint; practice-mode data; Beginner mode | T |
| 2 | Android speech recognition often needs network and has a short pause timeout | Test with data off on each phone; long-timeout listen options; large-text fallback | V |
| 3 | Low-end phones lack amplitude control | `hasAmplitudeControl()` fallback to duration-only patterns; test on the low-end phone | T |
| 4 | Multi-touch chords misfire on cheap digitisers | I2.1 accuracy pass; single-dot sequential mode as fallback | I |
| 5 | `QUERY_ALL_PACKAGES` for the launcher can be rejected by Play | Launcher is stretch; ship without it or with a short allow-list | V |
| 6 | Emulator has no haptics | Every dev has a phone (W0.4) | all |
| 7 | Phase 2 will need native code: `flutter_accessibility_service` 1.2 exposes only the event node, not the full tree | Known now, not the MVP's problem; noted in D-013 | — |

---

## 9. Deviations from the spec, on purpose

| Spec says | This plan does | Why |
|---|---|---|
| Full MVP incl. accessibility service, screen reading, forms, event registration (§10–16, §43) | Communication loop only (§5–6, §8–9, §35 partial, §41–42 partial) | Ian, 2026-09-02: focus, speed, validate the haptic bet first |
| Flutter + native Kotlin | Flutter only, plugins for native behaviour | Ian, 2026-09-02 |
| ElevenLabs + OpenAI as core | Android speech; rule-based simplifier; OpenAI behind a flag, off | Ian, 2026-09-02: minimal AI |
| 3 developers | 4 lanes (Input split from Tactile) | Team is four |
| 8 MVP screens (§34) | 5: Home, Conversation, Braille Mode, Settings, Practice (+ onboarding-lite) | No screen-reading or profile screens needed |
