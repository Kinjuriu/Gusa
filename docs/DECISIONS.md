# Gusa — Decisions

One line per decision. Status is OPEN until the owner writes the outcome and the date. Defaults are what we build if nobody objects by the due date.

| ID | Decision | Default | Owner | Due | Status |
|---|---|---|---|---|---|
| D-001 | **Overlay surface.** How does the user feel output and type Braille while another app (Chrome) is in front? Options: (a) native six-dot surface drawn by the accessibility service with `TYPE_ACCESSIBILITY_OVERLAY`; (b) "ping-pong": Gusa launches the app, acts, then brings its own screen back; (c) Flutter engine inside the overlay (add-to-app) — hardest. | Stage 1 = (b). Lane N runs spike W0.7 on (a). If the spike works on two phones, Stage 2 uses (a). | Lane N | End of Week 1 | OPEN |
| D-002 | **TalkBack coexistence.** Only one accessibility service can own touch exploration, and SPEC §9 gestures are TalkBack's gestures. | Gusa gestures work only inside Gusa's own screens (and the overlay if D-001 = a). Gusa does not request touch exploration in MVP. TalkBack may stay on. Revisit after user testing. | Lane T + N | Week 0 | OPEN |
| D-003 | **Voice provider.** | Android `SpeechRecognizer` + `TextToSpeech` only. ElevenLabs removed from MVP. Dart `SpeechProvider` interface so a cloud provider can be added later. | Ian | — | **DECIDED 2026-09-02** |
| D-004 | **Serverless platform.** | Cloudflare Workers (spec recommendation). Supabase Edge Functions is the fallback if Workers blocks on something. | Lane C | Week 0 | OPEN |
| D-005 | **Native bridge.** | Pigeon from day 1, not MethodChannel first. Typed contracts matter more with four machines. | Lane N | Week 0 | OPEN |
| D-006 | **Proxy authentication.** No user accounts exist. | Shared secret header per build, rotated per release; per-key rate limit; small monthly spend cap on the OpenAI key; Play Integrity attestation in Phase 2. | Lane C | Week 0 | OPEN |
| D-007 | **Test event page.** | Own page on GitHub Pages with proper `<label for>` markup. Real third-party pages only from Stage 3 (N3.1). | Lane C | Week 0 | OPEN |
| D-008 | **Braille standard.** | English Grade 1, UEB uncontracted. Capital sign and number sign supported. Kiswahili in Phase 2. | Lane T | Week 0 | OPEN |
| D-009 | **Haptic encoding of a cell.** Dot-by-dot in order 1–6 with present/absent slots, or row-by-row, or long/short pulses. | Start dot-by-dot (simplest to explain). Practice-mode data at the Stage 1 checkpoint decides. | Lane T | Stage 1 checkpoint | OPEN |
| D-010 | **Go / pivot after Stage 1.** See TEAM-PLAN §8. | Go if ≥70 % character recognition and ≥5 wpm with three testers. | Ian | Stage 1 exit | OPEN |

## Log

- 2026-09-02 — D-003 decided by Ian: no ElevenLabs. Voice is Android native only.
