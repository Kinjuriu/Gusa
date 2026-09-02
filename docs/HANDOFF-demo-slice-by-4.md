# HANDOFF — Gusa demo slice ("done by 4")

Branch: `spec/demo-slice-by-4`   Parent: `docs/team-plan`   Status: MERGED into docs/team-plan (659572b) — awaiting a phone
Owner: Ian (orchestrated by Claude)   Updated: 2026-09-02 15:10 EAT

## What this spec is doing

Build a demoable vertical slice of Gusa by 16:00 today, from an empty repo.

**Scope cut, stated honestly.** SPEC §43 (the full MVP demo) needs the Android
AccessibilityService to read Chrome's tree, parse a form and fill it. That is Stage 3
of TEAM-PLAN — weeks 5–6 with 4 full-time devs. It cannot land in 3 hours and cannot be
faked convincingly. So today we build **the first half of §43 — Journey A (SPEC §5) —
plus the always-on tap/speech launcher**:

| IN (today) | OUT (not today) |
|---|---|
| Speech-to-text (Android SpeechRecognizer) | AccessibilityService reading Chrome's tree |
| AI shortens the sentence (§5 simplification) | READ SCREEN / numbered actions |
| Braille encode + haptic render of the reply | Form fill / executor |
| TTS speaks the user's reply back | Overlay (D-001), TalkBack (D-002) |
| Always-on surface: reach an app/feature by TAP or SPEECH | The other 7 MVP screens |

## Where it is at right now

**All three lanes are built, merged and integrated. 71 tests green, `flutter analyze`
clean.** The app compiles and runs on fakes today. The ONLY thing left is plugging in a
physical Android phone and walking Journey A on it.

## Done
- [x] `flutter create` android-only scaffold, deps pinned — `887f201`
- [x] Android manifest: RECORD_AUDIO, VIBRATE, INTERNET, WAKE_LOCK + `<queries>` for
      launchable apps, SpeechRecognizer and TTS engines (API 30+ package visibility)
- [x] D-011 recorded (no user-facing auth in MVP) — on `docs/team-plan`, pushed
- [x] Lane T braille + haptics — 16 tests — merged
- [x] Lane V voice (SpeechProvider + Android impl + fake) — 20 tests — merged
- [x] Lane C launcher + AI simplifier — 27 tests — merged
- [x] Always-on home surface, Journey A controller, Braille visualiser — 8 tests
- [x] Adapters wiring lanes to the surface (`real_ports.dart`) — `df2fce7`

## Remaining
- [ ] **Connect an Android phone and run it.** Everything else is done.
- [ ] Tune haptic timings on-device — the constants at the top of
      `lib/core/haptics/haptic_engine.dart` are guesses until someone feels them.
- [ ] Optional: set `--dart-define=GUSA_AI_API_KEY=...` for real AI shortening;
      without it the rule-based fallback runs.

## Decisions made
- **Scope cut to Journey A + launcher** (above). Rejected: attempting the accessibility
  service today — it is the multi-week item and a fake would misrepresent the product.
- **Lane split by layer, 3 lanes**, matching SPEC §31's 3 developers (TEAM-PLAN's 4-lane
  split is a later reorganisation; Ian confirmed 3 devs today).
- **No API key required.** The AI simplifier falls back to a rule-based no-network
  implementation, so the demo runs offline. A hanging network call would kill a demo.
- **Ambiguity is reportable, not guessed.** `AppResolver` returns a ranked list with a
  confidence signal — a blind-deaf user cannot see that the wrong app opened.

## Reconcile with the team's v2 plan (docs/specs/) — NOT yet done

While this slice was being built, `docs/team-plan` advanced 4 commits: a v2 replan
("narrow MVP to the communication loop, Flutter only, minimal AI"), D-012…D-016, and
three lane specs. The merge was clean (they touched only docs + .github, no code) and
the architectures CONVERGED INDEPENDENTLY — `docs/specs/` names the same ports this
slice already implements: `Cell`, `BraillePort`, `HapticPort`, `VoicePort`,
`SimplifierPort`. Two real deltas remain:

1. **`SimplifierPort` return type.** `SPEC-V-voice.md` wants
   `Future<SimplifiedMessage> simplify(...)` with `{short, replies, fromAi}` — reply
   suggestions per D-016. This slice returns a bare `String`. Widening it is small:
   the adapter in `lib/features/home/real_ports.dart` is the only caller.
2. **The Input lane does not exist.** `SPEC-I-input.md` (six-dot Braille keyboard +
   gestures) is how the user TYPES a reply — the second half of Journey A (SPEC §6).
   This slice can only render Braille OUT, not take it IN; the demo's "user
   Braille-types YES" step is done by pressing SPEAK "YES".
   The `LauncherPort` built here (open an app by tap or voice) is not in their plan at
   all — it came from Ian's "always on, tap or speech to access app or feature".

## Open flags / risks
- 🔴 **NO ANDROID PHONE IS CONNECTED.** `adb devices` is empty. Haptics do not exist on
  an emulator, so nothing in this demo is verifiable without a device on USB. This is
  the critical path, ahead of any code.
- 🔴 **3 hours from an empty repo is not the plan's timeline.** TEAM-PLAN puts Week 0
  setup alone at 3 days with 4 devs. Today produces a demo slice, not the MVP.
- D-001 (overlay) and D-002 (TalkBack) remain OPEN and gate the lanes after today.
- Braille reading by a real user is unvalidated — that is the §41 user test, not a code task.

## Verification
```
cd "/Users/adera/My Work/projects/gusa"
/Users/adera/flutter/bin/flutter analyze && /Users/adera/flutter/bin/flutter test
/Users/adera/flutter/bin/flutter run           # needs a physical phone
```
Last result (2026-09-02 14:15): `flutter analyze` — No issues found.
`flutter test` — **All tests passed (71)**.

Run on fakes, no device needed:
```
/Users/adera/flutter/bin/flutter run --dart-define=GUSA_FAKE=true
```

## Git state
Branch `spec/demo-slice-by-4` at `df2fce7`, NOT pushed yet. The three lane branches
(`spec/demo-tactile`, `spec/demo-voice`, `spec/demo-launcher`) are merged into it; their
worktrees (`../gusa-wt-*`) can be removed with `git worktree remove`.
Parent `docs/team-plan` is pushed and carries D-011.

## Resume instruction
Plug in an Android phone, then:
```
cd "/Users/adera/My Work/projects/gusa"
/Users/adera/flutter/bin/flutter run
```
Press LISTEN, speak a sentence, and confirm you feel it as Braille pulses. Then tune the
timing constants in `lib/core/haptics/haptic_engine.dart` until the cells are readable.
