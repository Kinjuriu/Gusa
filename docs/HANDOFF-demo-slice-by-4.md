# HANDOFF — Gusa demo slice ("done by 4")

Branch: `spec/demo-slice-by-4`   Parent: `docs/team-plan`   Status: IN PROGRESS
Owner: Ian (orchestrated by Claude)   Updated: 2026-09-02 13:25 EAT

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

Scaffold + manifest + folder contracts are committed. Three lanes are running in
parallel worktrees. The always-on home surface is being built in the main tree.

## Done
- [x] `flutter create` android-only scaffold, deps pinned — `887f201`
- [x] Android manifest: RECORD_AUDIO, VIBRATE, INTERNET, WAKE_LOCK + `<queries>` for
      launchable apps, SpeechRecognizer and TTS engines (API 30+ package visibility)
- [x] D-011 recorded (no user-facing auth in MVP) — on `docs/team-plan`, pushed

## Remaining
- [ ] Lane T — `lib/core/braille/` + `lib/core/haptics/` — worktree `gusa-wt-tactile`, branch `spec/demo-tactile`
- [ ] Lane V — `lib/services/voice/` — worktree `gusa-wt-voice`, branch `spec/demo-voice`
- [ ] Lane C — `lib/services/launcher/` + `lib/services/ai/` — worktree `gusa-wt-launcher`, branch `spec/demo-launcher`
- [ ] Orchestrator — `lib/features/home/` always-on surface + integration adapters
- [ ] Merge three lane branches → `spec/demo-slice-by-4`, wire real implementations
- [ ] Build + install on a physical phone, run Journey A end to end

## Decisions made
- **Scope cut to Journey A + launcher** (above). Rejected: attempting the accessibility
  service today — it is the multi-week item and a fake would misrepresent the product.
- **Lane split by layer, 3 lanes**, matching SPEC §31's 3 developers (TEAM-PLAN's 4-lane
  split is a later reorganisation; Ian confirmed 3 devs today).
- **No API key required.** The AI simplifier falls back to a rule-based no-network
  implementation, so the demo runs offline. A hanging network call would kill a demo.
- **Ambiguity is reportable, not guessed.** `AppResolver` returns a ranked list with a
  confidence signal — a blind-deaf user cannot see that the wrong app opened.

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
Last result: scaffold builds; lane tests pending.

## Git state
Branch `spec/demo-slice-by-4` at `887f201`, not pushed. Three lane worktrees at the same
base. Parent `docs/team-plan` is pushed and carries D-011.

## Resume instruction
Wait for the three lane reports, merge their branches into `spec/demo-slice-by-4`,
replace the placeholder ports in `lib/features/home/` with the real implementations,
then `flutter run` on a connected phone and walk SPEC §5 Journey A.
