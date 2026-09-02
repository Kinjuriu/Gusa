# Gusa — 4-Developer MVP Plan

**Status:** DRAFT for team review · **Owner:** Ian (Ianodad) · **Date:** 2026-09-02
**Source of truth for product:** [`docs/SPEC.md`](SPEC.md) (46 sections). This plan turns the spec's 3-developer split into 4 lanes, adds the GitHub workflow, the verification gates, and honest estimates.
**Open decisions:** [`docs/DECISIONS.md`](DECISIONS.md) · **Machine setup:** [`docs/SETUP.md`](SETUP.md)

---

## 0. Read this first

1. **Four lanes, split by layer, not by feature.** App (Flutter screens), Tactile (Braille/haptics/gestures), Native (Kotlin), Cloud+Agent (proxy, AI, decision logic). Each lane owns a folder tree. Nobody merges into another lane's folder without that owner's review.
2. **Week 0 is contracts and setup, not features.** No feature code merges until the three contracts are merged with fixtures, fakes exist for every cross-lane call, and CI is green from all four PCs.
3. **Voice is Android-native only.** ElevenLabs is removed from the MVP (Ian, 2026-09-02). Speech-to-text and text-to-speech use Android `SpeechRecognizer` and `TextToSpeech`, behind a Dart `SpeechProvider` interface so a cloud provider can be added later without touching callers.
4. **Two decisions the spec never made must be closed in Week 0:** how the user feels and types Braille while another app is in front (overlay), and how Gusa coexists with TalkBack. Defaults are proposed in DECISIONS.md.
5. **The central bet cannot be validated by code.** Whether a person can read Braille from a phone motor is decided by users. Stage 1 ends with a go/pivot checkpoint on exactly that.

---

## 1. How much can four developers accomplish

### Assumptions
- Four developers, each on their own machine, coordinating only through GitHub.
- Each developer has a **physical Android phone**. Haptics do not work on the emulator, so a lane without a phone cannot verify its own work.
- One shared Cloudflare Workers deployment for the proxy, keys held by one person, small monthly spend cap on the OpenAI key.
- Claude Code or similar tooling is used per developer for implementation speed. It compresses typing, not device debugging or user testing.

### Timeline by availability

| Availability | Week 0 (contracts + setup) | Stage 1 Foundation | Stage 2 Integration | Stage 3 Hero demo | First Braille-user test |
|---|---|---|---|---|---|
| Full-time (~35 h/wk each) | 3 days | Weeks 1–2 | Weeks 3–4 | Weeks 5–6 | Week 7 |
| Part-time (~10 h/wk each) | 1 week | Weeks 2–5 | Weeks 6–9 | Weeks 10–12 | Week 13 |

Confidence: **Medium**. The three things that swing it most: how clean Chrome's accessibility tree is on the test page (Native lane, Stage 1), the overlay spike outcome (Native lane, Week 0), and whether every developer actually has a phone.

### What you will have at the end of each stage

| Stage | What exists, in plain words |
|---|---|
| Week 0 | Repo builds on all four PCs. Contracts merged. Fakes let every lane run alone. CI green. Overlay and TalkBack decisions written down. |
| Stage 1 | APK on a phone: you can type Braille on the six-dot keyboard and feel it echoed back. The accessibility service is enabled and dumps the test event page as JSON. The proxy returns a structured summary for a fixture screen. Android speech round-trips text to voice and back. |
| Stage 2 | Conversation Mode round trip: someone speaks, user feels it, user types Braille, phone speaks it. Read Screen on the test page returns numbered actions. Executor can click Register and fill fields. Offline mode works without the proxy. |
| Stage 3 | The full hero demo (SPEC §43) completes end-to-end on two different phones, driven by someone who did not write the code. Confirmation gate proven. Demo video recorded. User-testing session scheduled. |

---

## 2. Team split

| Lane | Developer | Owns (folders) | Skills | Consumes | Provides |
|---|---|---|---|---|---|
| **A — App** | **Ian (Ianodad)** | `lib/app/`, `lib/features/`, `lib/storage/`, `test/features/` | Flutter, Riverpod, go_router, Drift | Tactile engines, Contract A bridge, Contract B AI client | The 8 MVP screens, onboarding, profile, hero-demo orchestration |
| **T — Tactile** | *assign* | `lib/core/braille/`, `lib/core/haptics/`, `lib/core/gestures/`, `lib/core/braille_keyboard/`, `test/core/` | Dart, widget tests, touch handling, some UX research | Native `vibrate()` via Contract A | Braille engine, haptic engine, gesture engine, six-dot keyboard widget |
| **N — Native** | *assign (strongest Android dev)* | `android/`, `pigeons/`, `lib/services/android_bridge/` | Kotlin, AccessibilityService, Pigeon | Contract A definition, Contract C actions | Accessibility service, tree parser, executor, app launcher, native haptics, native speech, overlay |
| **C — Cloud + Agent** | *assign* | `proxy/`, `contracts/`, `lib/services/ai_service/`, `lib/core/agent/`, `test-site/`, `test/core/agent/` | TypeScript, Cloudflare Workers, OpenAI structured outputs, Dart | Contract B and C | Proxy, prompts + evals, intent router, form matcher, policy validator, test event page |

**Why by layer and not by feature.** Two alternatives were considered and rejected:
- *By feature* (one dev per screen or journey): every dev touches Kotlin, Dart and TypeScript, merge conflicts in `android/` are constant, and nobody owns the accessibility service. Rejected.
- *The spec's 3 lanes plus a floating QA dev*: the floater has no folder and no contract, so their PRs are always cross-cutting. Rejected. Instead, verification is built into CI and every lane's definition of done (§6).

Lane A is deliberately the integrator. Ian follows the spec's screens and journeys closely and is the first consumer of every other lane's output, so gaps in contracts surface in Lane A's PRs, early.

---

## 3. Contracts (Week 0, before any feature code)

The spec (§32) names three contracts. Here is where each lives, who owns it, and how it is enforced.

| Contract | Boundary | Location | Owner | Reviewer required | Enforced by |
|---|---|---|---|---|---|
| **A** | Flutter ↔ Android | `pigeons/accessibility_bridge.dart` (Pigeon definition), generated into `lib/services/android_bridge/` and `android/.../bridge/` | Lane N | Lane A + Lane T | Pigeon codegen committed; `flutter analyze` and Kotlin compile fail on drift |
| **B** | Flutter ↔ AI | `contracts/ai/*.schema.json` (request + response per endpoint) | Lane C | Lane A | ajv validation of `contracts/fixtures/ai/*.json` in CI; Dart and Worker tests parse the same fixtures |
| **C** | AI ↔ Android action | `contracts/actions/accessibility-action.schema.json` (SPEC §30, types from §14, risk + confirmation from §15) | Lane C | Lane N | ajv in CI; Kotlin executor test and Dart policy-validator test parse the same fixtures |

### Contract A sketch (Pigeon)

```dart
// pigeons/accessibility_bridge.dart
class ScreenNode {
  late String id;            // stable within one snapshot
  late String role;          // heading | text | button | input | link | checkbox | list | other
  String? text;
  String? hint;
  String? contentDescription;
  late bool clickable;
  late bool editable;
  late bool focused;
  late bool password;        // never sent to AI
  late List<int?> bounds;    // l, t, r, b
}
class ScreenSnapshot { late String packageName; String? title; late List<ScreenNode?> nodes; late int takenAtMs; }
class ActionRequest { late String id; late String type; String? targetNodeId; String? value; String? packageName; }
class ActionResult { late String id; late String status; String? message; } // OK | NOT_FOUND | FAILED | UNSUPPORTED

@HostApi()
abstract class AccessibilityHostApi {
  bool isServiceEnabled();
  void openAccessibilitySettings();
  ScreenSnapshot getCurrentScreen();
  ActionResult performAction(ActionRequest request);
  void vibrate(List<int> timingsMs, List<int> amplitudes);
  void cancelVibration();
  void speak(String text, String utteranceId);
  void startListening();
  void stopListening();
}

@FlutterApi()
abstract class AccessibilityFlutterApi {
  void onScreenChanged(ScreenSnapshot snapshot);
  void onSpeechPartial(String text);
  void onSpeechFinal(String text);
  void onSpeakDone(String utteranceId);
}
```

### Fakes are the parallelism enabler
Every cross-lane dependency gets a fake in Week 0 so each lane can build and test alone:
- `lib/services/android_bridge/fake_accessibility_bridge.dart` — returns the event-page fixture, records actions, vibrates to a log.
- `lib/services/ai_service/fake_ai_service.dart` — returns canned summaries and plans from `contracts/fixtures/ai/`.
- `proxy/test/fixtures/` — recorded OpenAI responses so Worker tests run without keys.
Run the app with `--dart-define=GUSA_USE_FAKES=true`.

### Contract change protocol
A PR that touches `pigeons/` or `contracts/` must: update the fixtures, update every consumer in the same PR, and be approved by both owning lanes. Contract PRs get the `contract` label and jump the review queue.

---

## 4. Stage plan

Sizes are full-time developer days: **S** ≤ 1, **M** 2–3, **L** 4–5. Every task is a GitHub issue with the ID below in its title. "Verify by" is what the PR must show.

### Week 0 — Contracts and setup (all lanes)

| ID | Lane | Task | Size | Verify by |
|---|---|---|---|---|
| W0.1 | A | `flutter create` at repo root, folder layout from SPEC §28, Riverpod + go_router, pinned Flutter version, `analysis_options.yaml`, `.gitignore` | S | `flutter build apk --debug` in CI |
| W0.2 | N | Pigeon definition for Contract A, generated code committed, Kotlin stub returning the fixture screen | M | Kotlin compiles; Dart test calls stub |
| W0.3 | C | Contracts B and C as JSON Schema, fixtures for the event page, ajv CI job | M | `contracts` CI job green |
| W0.4 | C | Proxy skeleton on Cloudflare Workers: routes, zod validation, shared-secret header, rate limit, spend guard, `wrangler dev` | M | `proxy` CI job green; `curl` against `wrangler dev` returns fixture |
| W0.5 | T | Fake bridge + fake AI service, `GUSA_USE_FAKES` flag | S | App boots on emulator with fakes |
| W0.6 | A | CI workflows (flutter, android, proxy, contracts), branch protection, CODEOWNERS, PR template, issue labels, project board | S | Four green checks on a no-op PR |
| W0.7 | N | **Spike: overlay surface** — draw a native six-dot surface with `TYPE_ACCESSIBILITY_OVERLAY` over Chrome and capture touches. Write findings to DECISIONS.md D-001 | M | Video + decision recorded |
| W0.8 | C | Test event page `test-site/event.html` on GitHub Pages: title, date, Free Entry, Name/Email/Phone/Attendance fields with proper `<label for>`, Register button, success page | S | Page live; used by N and A fixtures |
| W0.9 | all | Each dev runs `scripts/doctor.sh`, builds the APK, installs it on their phone, and posts a screenshot in the Week 0 issue | S | Four screenshots |

**Week 0 exit:** all four PCs build and install; contracts merged with fixtures; fakes merged; CI green; D-001 and D-002 closed in DECISIONS.md.

### Stage 1 — Foundation

| ID | Lane | Task | Size | Depends on | Verify by |
|---|---|---|---|---|---|
| T1.1 | T | **BrailleEngine** Grade 1 (UEB uncontracted): letters, capital sign, number sign + digits, basic punctuation; `encode`, `decode`, `validate`, `normalizeText`, `nextCharacter` | M | — | Round-trip test over a 500-word list; invalid cells rejected |
| T1.2 | T | **HapticEngine** (Dart): cell → dot timeline → `vibrate()` calls; modes Beginner/Normal/Fast/Custom; settings model; pause/resume/repeat | M | T1.1, W0.2 | Timing unit tests; felt on a phone; video |
| T1.3 | T | **GestureEngine**: SPEC §9 vocabulary from raw pointer events, haptic confirmation codes (§9 table) | M | — | Tests with synthetic pointer streams; false-positive rate on a scribble fixture |
| T1.4 | T | **Six-dot keyboard widget**: chord input with multi-touch, commit on release or timeout, echo through haptics, large-text mirror | M | T1.1, T1.2 | Widget tests; typed `YES` on a phone; video |
| A1.1 | A | App shell: theme, large-text mode, semantics baseline, the 8 screens as routed stubs (SPEC §34) | M | W0.1 | Navigates on emulator; TalkBack reads every stub |
| A1.2 | A | Storage: Drift for profile + settings (SPEC §17), `flutter_secure_storage` for name/email/phone | M | — | Tests; profile survives restart |
| A1.3 | A | Onboarding (SPEC §35 steps 1–4) + Accessibility Setup screen that deep-links to Android settings and polls `isServiceEnabled()` | M | A1.1, W0.2 | Video on a phone |
| A1.4 | A | Settings screen wired to Braille/haptic/output/input models | S | A1.2, T1.2 | Change speed, feel the difference |
| N1.1 | N | **GusaAccessibilityService**: service XML, lifecycle, event subscription, enabled-state query, foreground app tracking | M | W0.2 | Enabled via `adb`; logs window changes |
| N1.2 | N | **AccessibilityTreeParser**: node → `ScreenNode`, role inference, stable ids, `password` flag, Chrome web content handling, depth/size limits | L | N1.1 | Kotlin unit tests on recorded node trees; live dump of the test event page contains title, 4 inputs, Register |
| N1.3 | N | **HapticController**: `VibrationEffect.createWaveform` with amplitudes, fallback for no amplitude control, cancel | S | — | Felt on two different phones |
| N1.4 | N | **SpeechController**: `TextToSpeech` + `SpeechRecognizer` behind Contract A, utterance callbacks, partial results | M | W0.2 | Speak "Yes"; recognise a spoken sentence; both offline |
| C1.1 | C | `SpeechProvider` interface in Dart with `AndroidSpeechProvider` (bridge-backed) and a fake; offline detection | S | N1.4 | Tests; swapping provider needs no caller change |
| C1.2 | C | OpenAI structured-output schemas for `summarize-screen`, `plan`, `simplify`; Worker handlers; eval harness with 10 fixture screens | M | W0.3, W0.4 | Evals pass; responses validate against Contract B |
| C1.3 | C | Dart `AiService` (Dio) + fake, request redaction: strip `password` nodes and OTP-like text before sending (SPEC §37) | M | C1.2 | Tests prove password nodes never leave the device |
| C1.4 | C | **Intent router** (`lib/core/agent/`): local commands bypass AI (BACK, NEXT, REPEAT, HOME, OPEN <app>, READ SCREEN); everything else → AI | S | — | Table-driven tests |

**Stage 1 exit:** on a phone, type Braille and feel it echoed; service enabled, test page dumped as JSON; proxy returns a valid summary for a fixture; Android speech round-trips. **Then run the go/pivot checkpoint (§8).**

### Stage 2 — Integration

| ID | Lane | Task | Size | Depends on | Verify by |
|---|---|---|---|---|---|
| T2.1 | T | Tactile reader: play a whole message with word pauses, repeat-last, pause/resume, speed from settings | M | T1.2 | Recognition test with 3 people (see §8) |
| T2.2 | T | Practice mode + accuracy logger for user testing (SPEC §41 metrics: chars/min, errors, repeats) | M | T1.4 | CSV export from a session |
| A2.1 | A | Touch/Braille Mode screen: keyboard + reader + gestures | M | T1.4, T2.1 | Video |
| A2.2 | A | **Conversation Mode** (SPEC §5–6): listen → simplify (AI, optional) → tactile/large text; Braille reply → speak | L | C1.1, C1.2, T2.1 | Full round trip on a phone, offline and online |
| A2.3 | A | **Read Screen** (SPEC §11–12): `getCurrentScreen` → AI summary → numbered actions → select → execute via policy validator | L | N1.2, C1.2, C2.2 | Test page read aloud and felt; action list correct |
| A2.4 | A | **Form Assistant UI** (SPEC §16): missing-field prompts, choice lists, confirmation screen, success haptic | M | C2.1 | Test page filled from profile; Attendance asked |
| N2.1 | N | **AccessibilityExecutor**: CLICK, SET_TEXT (ACTION_SET_TEXT with clipboard fallback), SCROLL_FORWARD/BACKWARD, GO_BACK, GO_HOME, FOCUS_NODE, READ_NODE; result codes | L | N1.2 | Kotlin tests; fills and submits the test page from `adb` |
| N2.2 | N | **AppLauncher**: friendly name → package, launch intents, OPEN WHATSAPP / CHROME / PHONE | S | — | Opens all three |
| N2.3 | N | **Overlay surface** (if D-001 = overlay): native six-dot input + haptic on top of other apps, forwarding to Flutter via bridge | L | W0.7 | Type Braille while Chrome is in front; video |
| C2.1 | C | **Form matcher** (SPEC §18): synonym tables, confidence, profile mapping, UNKNOWN → ask; AI fallback for ambiguous labels | M | C1.2 | Fixture forms; ≥0.9 confidence on the test page |
| C2.2 | C | **Policy validator** (SPEC §15): allowed types only, risk class, confirmation required for submit/send/upload, rejects unknown targets | M | W0.3 | Tests: no CLICK on Register without confirmation |
| C2.3 | C | **Action planner** prompt: returns only Contract C actions; eval set; never free text | M | C1.2 | Evals; 0 schema violations on 50 runs |
| C2.4 | C | Simplify + error-explanation prompts (short, uppercase, tactile-friendly) + evals | S | C1.2 | Evals |

**Stage 2 exit:** Conversation Mode round trip; Read Screen on the test page; executor fills and clicks; offline degrades to Android speech and no AI.

### Stage 3 — Hero demo

| ID | Lane | Task | Size | Verify by |
|---|---|---|---|---|
| A3.1 | A | Hero flow orchestration (SPEC §43) end-to-end, error recovery, graceful degradation switch | L | Run by a non-author on two phones |
| N3.1 | N | Chrome form robustness: label inference for unlabeled inputs (nearby text, hint), SET_TEXT reliability on web inputs, scroll-into-view | M | Works on the test page and on one real third-party event page |
| T3.1 | T | Haptic pattern tuning from practice-mode data; Beginner mode timings | M | Recognition accuracy before/after table |
| C3.1 | C | Latency + cost pass: cache identical screen summaries, trim node payloads, secrets rotation doc | S | p95 latency and cost per demo run recorded |
| all | all | Test matrix (SPEC §40) run on 2 phones, results in `docs/TEST-RESULTS.md`; demo video; user test scheduled | M | Checklist complete |

---

## 5. GitHub workflow

### Repo layout (monorepo)

```
gusa/
├── lib/                 Flutter app (lanes A, T, C own subfolders)
│   ├── app/             shell, router, theme            (A)
│   ├── features/        the 8 screens                   (A)
│   ├── storage/         Drift, secure storage           (A)
│   ├── core/braille/    braille engine                  (T)
│   ├── core/haptics/    haptic engine                   (T)
│   ├── core/gestures/   gesture engine                  (T)
│   ├── core/braille_keyboard/  six-dot widget           (T)
│   ├── core/agent/      intent router, form matcher, policy validator (C)
│   └── services/        android_bridge (N), ai_service (C), speech (C)
├── android/             Kotlin: service, parser, executor, haptics, speech (N)
├── pigeons/             Contract A definition (N)
├── contracts/           Contracts B + C schemas and fixtures (C)
├── proxy/               Cloudflare Worker, TypeScript (C)
├── test-site/           test event page, GitHub Pages (C)
├── scripts/             doctor.sh, enable-service.sh, run-proxy.sh
├── docs/                SPEC, this plan, DECISIONS, SETUP, TEST-RESULTS
└── .github/             workflows, CODEOWNERS, PR template
```

### Branches

| Branch | Purpose | Protection |
|---|---|---|
| `main` | Demo-ready. Only stage merges land here. | PR only, 2 approvals, all checks, no force-push |
| `develop` | Integration. Every feature PR targets this. | PR only, 1 CODEOWNER approval, all checks, no force-push |
| `feat/<lane>/<id>-<slug>` | One task per branch, e.g. `feat/t/T1.1-braille-engine` | Delete after merge |
| `fix/<lane>/<slug>` | Bug fixes | Same as feat |
| `contract/<slug>` | Any change under `pigeons/` or `contracts/` | Both owning lanes approve |

Rules: rebase on `develop` before opening a PR; squash-merge; PR title starts with the task ID; a PR touches one lane's folders unless it is a `contract/` PR.

### CODEOWNERS (routes reviews automatically)

```
/lib/app/                 @ianodad
/lib/features/            @ianodad
/lib/storage/             @ianodad
/lib/core/braille/        @<tactile-dev>
/lib/core/haptics/        @<tactile-dev>
/lib/core/gestures/       @<tactile-dev>
/lib/core/braille_keyboard/ @<tactile-dev>
/lib/core/agent/          @<cloud-dev>
/lib/services/ai_service/ @<cloud-dev>
/lib/services/android_bridge/ @<native-dev>
/android/                 @<native-dev>
/pigeons/                 @<native-dev> @ianodad
/contracts/               @<cloud-dev> @<native-dev>
/proxy/                   @<cloud-dev>
/test-site/               @<cloud-dev>
/docs/                    @ianodad
```

### Issues and board
- One GitHub issue per task ID above. Labels: `lane:app`, `lane:tactile`, `lane:native`, `lane:cloud`, `stage:0|1|2|3`, `contract`, `blocked`.
- Milestones: `Week 0`, `Stage 1`, `Stage 2`, `Stage 3`.
- Project board columns: Backlog → This week → In progress → In review → Done.

### Rhythm
- **Monday, 30 min:** each dev picks issues for the week, blockers named.
- **Friday, 30 min:** integration build from `develop` (CI attaches the APK to a pre-release), everyone installs it on their phone, one person demos the week's slice.
- **Reviews within 24 h.** A PR waiting longer than that is raised in the group chat.

---

## 6. Verification (a way to know it works)

### CI on every PR

| Job | Runs | Fails when |
|---|---|---|
| `flutter` | `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test --coverage`, `flutter build apk --debug`, uploads APK | Any lint, test, or build error |
| `android` | `./gradlew testDebugUnitTest` (parser and executor tests on recorded node trees) | Kotlin test failure |
| `proxy` | `npm ci && npm test` (vitest, recorded OpenAI fixtures), `wrangler deploy --dry-run` | Test failure or bad Worker config |
| `contracts` | ajv validates every file in `contracts/fixtures/` against its schema; Pigeon regenerate + `git diff --exit-code` | Fixture drift or uncommitted generated code |
| `emulator` (nightly, from Stage 2) | Boots API 34, installs APK, enables service via `adb`, opens the test page in Chrome, asserts the dump contains "Register" and 4 inputs | Tree parsing regresses |

### Definition of done (PR template)
- [ ] Linked issue with task ID
- [ ] Tests added or updated, CI green
- [ ] Touches `pigeons/` or `contracts/`? Both owning lanes approved, fixtures updated
- [ ] UI, haptic, or native work: phone video or screen recording attached
- [ ] Docs updated if behaviour changed (SETUP, DECISIONS, contract READMEs)
- [ ] No secrets, no screen histories, no raw accessibility trees logged

### Cross-lane safety net
The same fixtures under `contracts/fixtures/` are parsed by a Dart test, a Kotlin test, and a Worker test. If one lane changes a shape, three CI jobs fail, not one.

### Stage demos
Each stage exit is a live demo on a phone in the Friday call, checked against the exit criteria in §4 and, for Stage 3, against SPEC §42. Results go in `docs/TEST-RESULTS.md` with the phone model and Android version.

### Device matrix
Minimum two phones from different makers, one low-end. Record for each: amplitude control supported, Chrome version, TalkBack version.

### User testing
SPEC §41 is the protocol. Practice mode (T2.2) exports the metrics. Schedule the first session at the Stage 3 exit, and a smaller informal one at the Stage 1 checkpoint (§8).

---

## 7. Risks and owners

| # | Risk | Why it matters | Mitigation | Owner |
|---|---|---|---|---|
| 1 | Braille through one vibration motor may be too slow or unreadable. Rough estimate ~1.2 s per character, under 10 words per minute | The whole product rides on it | Stage 1 go/pivot checkpoint with three real people; practice-mode metrics; Beginner mode | T |
| 2 | Spec is silent on how the user types while Chrome is in front | Decides what A, T and N build | Week 0 spike W0.7; D-001 | N |
| 3 | Gusa gestures collide with TalkBack; only one service can own touch exploration | "TalkBack compatibility" and §9 gestures conflict | D-002 default: Gusa gestures only inside Gusa screens for MVP | T, N |
| 4 | Proxy is an open relay: no accounts, APK is unpackable | Someone burns the OpenAI key | Shared secret header, rotation, small spend cap, per-key rate limit; Play Integrity in Phase 2 | C |
| 5 | Chrome web forms often expose unlabeled inputs | Deterministic form matcher fails on real pages | Own test page with proper labels first; N3.1 label inference later | N, C |
| 6 | Password and OTP text reaching OpenAI | Privacy, trust | `password` flag stripped in C1.3; OTP heuristic; test proves it | C |
| 7 | Emulator has no haptics | A lane without a phone cannot verify itself | Every dev has a phone (W0.9) | all |
| 8 | Contracts drift silently between lanes | Integration hell in Stage 2 | Shared fixtures, three-way CI, contract PR rule | C, N |

---

## 8. Go / pivot checkpoint (end of Stage 1)

Before Stage 2, three people who did not build it (at least one Braille reader if at all possible) use practice mode for 15 minutes each.

| Measure | Go | Pivot |
|---|---|---|
| Character recognition after 10 min practice | ≥ 70 % | < 50 % |
| Words per minute on a 5-word message | ≥ 5 | < 2 |
| Would use it again (yes/no) | 2 of 3 | 0 of 3 |

Pivot options, ranked: change the encoding (dot-by-dot vs. row-by-row vs. long/short), slow Beginner mode further, or bring forward Bluetooth Braille display support from Phase 2 as the primary output and keep the six-dot keyboard as input. The decision is Ian's, recorded in DECISIONS.md.

---

## 9. Deviations from the spec, on purpose

| Spec says | This plan does | Why |
|---|---|---|
| 3 developers | 4 lanes | Team is 4; splits Flutter into App and Tactile |
| ElevenLabs for STT/TTS, `/voice/*` proxy routes | Android native speech only, no voice routes | Ian, 2026-09-02. Removes a paid dependency and two endpoints; provider interface keeps the door open |
| MethodChannel first, Pigeon later | Pigeon from day 1 | Four devs on separate machines need typed contracts from the start |
| "TalkBack compatibility" as a test | Gusa gestures only inside Gusa screens for MVP | One service owns touch exploration; revisit after user testing |
| No test page named | Own event page on GitHub Pages | A controlled page makes Stage 1 and 2 verifiable |
