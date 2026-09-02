# Gusa — Decisions

One line per decision. OPEN until the owner writes the outcome and date. Defaults are what gets built if nobody objects by the due date. DEFERRED means Phase 2, not the MVP.

| ID | Decision | Default / outcome | Owner | Due | Status |
|---|---|---|---|---|---|
| D-001 | **Overlay surface.** How does the user type Braille while another app is in front? | Not needed: the MVP has no screen reading, so the user is always inside Gusa. Revisit with the accessibility service. | Lane N (Phase 2) | — | DEFERRED |
| D-002 | **TalkBack coexistence.** | Gusa is a normal app in the MVP; TalkBack users can run it. Gusa gestures apply only inside Gusa screens. Touch-exploration conflicts belong to Phase 2. | — | — | DEFERRED |
| D-003 | **Voice provider.** | Android speech only via `speech_to_text` and `flutter_tts`. ElevenLabs removed. `VoicePort` keeps a cloud provider swappable. | Ian | — | **DECIDED 2026-09-02** |
| D-004 | **Serverless platform.** | Only exists if D-014's flag is on. Cloudflare Workers if so. | Lane V | when D-014 flips | DEFERRED |
| D-005 | **Native bridge.** | None. No Pigeon, no MethodChannel. Dart ports + plugins. | Ian | — | **DECIDED 2026-09-02** |
| D-006 | **Proxy authentication.** | Follows D-004. Shared secret + spend cap if a proxy exists. | Lane V | with D-004 | DEFERRED |
| D-007 | **Test event page.** | No forms in the MVP. | — | — | DEFERRED |
| D-008 | **Braille standard.** | English Grade 1, UEB uncontracted, capital and number signs. Kiswahili Phase 2. | Lane T | Week 0 | OPEN |
| D-009 | **Haptic encoding of a cell.** Dot-by-dot (six slots, present / absent), row-by-row, or long / short pulses. | Start dot-by-dot. Practice-mode data at the Stage 1 checkpoint decides. Timing table in `docs/HAPTICS.md`. | Lane T | Week 0 (W0.3) | OPEN |
| D-010 | **Go / pivot after Stage 1.** | Go if ≥ 70 % character recognition and ≥ 5 wpm with three testers (TEAM-PLAN §7). | Ian | Stage 1 exit | OPEN |
| D-011 | **App authentication (user-facing).** Does the MVP have any sign-in at all? | **None. The MVP is a demo: no password, no OTP, no login, no user account.** The app opens straight into the experience. Everything stays on-device. Not the same as D-006 (proxy secret) and not the same as SPEC §37 redaction. Cloud user accounts stay out of scope. | Ian | — | **DECIDED 2026-09-02** |
| D-012 | **MVP scope.** | **Communication loop only:** speech in → Braille haptics out → tap-tap reply → speech out, plus quick replies and touch gestures. Accessibility service, screen reading, form filling, and the §43 event-registration demo move to Phase 2. App launcher is a stretch. | Ian | — | **DECIDED 2026-09-02** |
| D-013 | **Flutter only, no Kotlin.** | Native behaviour comes from plugins: `speech_to_text` 7.4, `flutter_tts` 4.2, `vibration` 3.2, `installed_apps` 2.1, `android_intent_plus`. `android/` holds manifest and Gradle config only. If a plugin gap ever forces native code, fork the plugin in its own repo; this repo stays Dart. Known for Phase 2: `flutter_accessibility_service` 1.2 exposes the event node, not the full tree, so screen reading will need native work later. | Ian | — | **DECIDED 2026-09-02** |
| D-014 | **AI is minimal.** | Simplifier is rule-based and offline by default. An OpenAI simplifier exists behind `GUSA_AI=on`, off in the demo, on only if someone owns a key and a proxy. | Ian | — | **DECIDED 2026-09-02** |

## Log

- 2026-09-02 — D-003 decided by Ian: no ElevenLabs, Android speech only.
- 2026-09-02 — D-011 decided by Ian: no user-facing auth in the MVP; it opens straight into the experience.
- 2026-09-02 — D-012, D-013, D-014 decided by Ian: communication-loop scope, Flutter only, minimal AI. D-001, D-002, D-004, D-006, D-007 deferred to Phase 2 as a consequence. D-005 closed: no native bridge.
