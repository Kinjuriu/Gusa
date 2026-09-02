# Gusa — Screen wireframes (MVP v2)

Text wireframes for the five MVP screens plus onboarding-lite. These are the App lane's (Ian's) spec. Every screen must be usable with eyes closed and ears off: the layout is a touch map first and a visual second. Large text mirrors everything for low-vision users and for sighted helpers.

Conventions: `[ ]` touch zone · `≡` large-text mirror · `📳` haptic code (see SPEC-T §Codes) · gesture legend under each screen.

---

## 0. Onboarding-lite (first launch only, SPEC §35 steps 1, 2, 5)

```
┌────────────────────────────────────┐   ┌────────────────────────────────────┐   ┌────────────────────────────────────┐
│ 1 / 3                              │   │ 2 / 3                              │   │ 3 / 3                              │
│                                    │   │                                    │   │                                    │
│  HOW DO YOU RECEIVE?               │   │  HOW DO YOU REPLY?                 │   │  PRACTICE                          │
│                                    │   │                                    │   │                                    │
│ ┌──────────────┐ ┌──────────────┐  │   │ ┌──────────────┐ ┌──────────────┐  │   │  Feel this. It is the letter A.    │
│ │  VIBRATION   │ │   LARGE      │  │   │ │   BRAILLE    │ │    QUICK     │  │   │                                    │
│ │  + BRAILLE   │ │   TEXT       │  │   │ │   TAPS       │ │   REPLIES    │  │   │        📳  ·  ·  ·  ·  ·           │
│ └──────────────┘ └──────────────┘  │   │ └──────────────┘ └──────────────┘  │   │                                    │
│ ┌──────────────┐ ┌──────────────┐  │   │ ┌──────────────┐ ┌──────────────┐  │   │  [ LONG PRESS = REPEAT ]           │
│ │   VOICE      │ │  SCREEN      │  │   │ │   VOICE      │ │  KEYBOARD    │  │   │  [ DOUBLE TAP = NEXT ]             │
│ │              │ │  READER      │  │   │ │              │ │              │  │   │                                    │
│ └──────────────┘ └──────────────┘  │   │ └──────────────┘ └──────────────┘  │   │  3 letters, then HOME              │
└────────────────────────────────────┘   └────────────────────────────────────┘   └────────────────────────────────────┘
 four quadrants · tap = preview 📳       four quadrants · tap = preview 📳        plays A, B, C at Beginner speed
 double tap = choose · swipe = next      double tap = choose · swipe = next       skips if the user double-taps twice
```

Choices are stored in Settings. A sighted helper can do this screen for the user; the app says so in the large text.

---

## 1. Home (the always-on surface)

```
┌────────────────────────────────────┐
│ GUSA                    📳 READY   │  ← status line, large text
├─────────────────┬──────────────────┤
│                 │                  │
│     LISTEN      │      TYPE        │  top-left = Conversation (Listen first)
│   (someone      │   (Braille       │  top-right = Braille Mode
│    speaks)      │    keyboard)     │
│                 │                  │
├─────────────────┼──────────────────┤
│                 │                  │
│    PRACTICE     │    SETTINGS      │  bottom-left = Practice
│                 │                  │  bottom-right = Settings
│                 │                  │
└─────────────────┴──────────────────┘
 tap a quadrant = 📳 its code (1, 2, 3, 4 pulses) + large-text name
 double tap = open · long press = repeat the last message · two-finger tap = pause anything playing
```

Four quadrants, fixed positions, never rearranged. The user learns them by touch in a minute. No scrolling, no lists.

---

## 2. Conversation (SPEC §5–6, the hero loop)

One screen, five states. The whole screen is one touch zone in every state.

```
 READY                      LISTENING                   FEELING
┌──────────────────────┐   ┌──────────────────────┐   ┌──────────────────────┐
│ ≡ READY              │   │ ≡ LISTENING …        │   │ ≡ EVENT TOMORROW.    │
│                      │   │                      │   │ ≡ ATTEND?            │
│                      │   │   ◉  (pulse 📳)      │   │                      │
│   DOUBLE TAP         │   │                      │   │   📳📳📳 cell by cell │
│   TO LISTEN          │   │   partial text ≡     │   │   ▮▮▮▮▮▯▯▯  progress │
│                      │   │                      │   │                      │
│                      │   │  two-finger tap=stop │   │  long press = repeat │
└──────────────────────┘   └──────────────────────┘   └──────────────────────┘

 REPLY                                                 SPEAKING
┌──────────────────────┐   ┌──────────────────────┐   ┌──────────────────────┐
│ ≡ REPLY?             │   │ (TYPE chosen →       │   │ ≡ "YES"              │
│                      │   │  Braille Mode opens  │   │                      │
│  1  YES              │   │  with SEND enabled)  │   │   🔊 speaking …      │
│  2  NO               │   │                      │   │                      │
│  3  ASK TIME         │   │                      │   │   📳 short-short     │
│  4  TYPE             │   │                      │   │   when done → READY  │
│                      │   │                      │   │                      │
│  N taps = option N   │   │                      │   │                      │
└──────────────────────┘   └──────────────────────┘   └──────────────────────┘
```

State machine:

```
READY --double tap--> LISTENING --final text--> (simplify) --> FEELING --message ends--> REPLY
  ^                      |  timeout / error 📳 long                                       |
  |                      +--------------------------> READY                    N taps / TYPE
  |                                                                                       v
  +---------------------------- 📳 short-short <------ SPEAKING <------ text ------ (typed or picked)
```

- FEELING plays `SimplifiedMessage.short` through `HapticPort.render`; large text shows the same lines.
- REPLY lists `SimplifiedMessage.replies` (≤ 3) plus TYPE. Tap-count selection is primary here (gesture scoping rule); long press repeats the message; swipe up/down moves between options with 📳 count.
- Every transition has a haptic code: listening = pulse, message = short-long, error = long, success = short-short.
- Offline: LISTENING still uses Android recognition; simplify is rule-based; SPEAKING uses Android voice. The screen never mentions the network.

---

## 3. Braille Mode (six-dot keyboard, SPEC §6)

```
┌────────────────────────────────────┐
│ ≡ YES_                             │  ← typed text mirror, large, top 12 %
├─────────────────┬──────────────────┤
│                 │                  │
│      [1]        │       [4]        │
│                 │                  │
├─────────────────┼──────────────────┤
│                 │                  │
│      [2]        │       [5]        │  six equal zones, phone held portrait
│                 │                  │  chord = touch any set at once, lift all
├─────────────────┼──────────────────┤
│                 │                  │
│      [3]        │       [6]        │
│                 │                  │
└─────────────────┴──────────────────┘
 chord (taps, no movement) = one cell · 📳 short echo
 swipe right = SPACE · swipe left = BACKSPACE · long press = repeat typed text
 double tap = SEND (speak it) · two-finger tap = cancel / back to Home
```

Zone borders are raised in the visual design (thick rules) and the phone gives a different 📳 for left-column and right-column touches during practice only.

---

## 4. Settings

```
┌────────────────────────────────────┐
│ ≡ SETTINGS                         │
├────────────────────────────────────┤
│  HAPTIC SPEED     ◀  NORMAL  ▶     │  swipe left/right changes; plays a sample 📳
├────────────────────────────────────┤
│  INTENSITY        ◀  ▮▮▮▯▯   ▶     │
├────────────────────────────────────┤
│  VOICE RATE       ◀  NORMAL  ▶     │  speaks a sample
├────────────────────────────────────┤
│  CELL ECHO        ◀  SHORT   ▶     │  SHORT pulse or FULL cell after each chord
├────────────────────────────────────┤
│  CLOUD            ◀  ON      ▶     │  reply suggestions + natural voice when online
└────────────────────────────────────┘
 swipe up/down = row (📳 count) · swipe left/right = change · double tap = back
```

Five rows, fixed order. Each row announces itself with N pulses and large text.

---

## 5. Practice (SPEC §41 data)

```
┌────────────────────────────────────┐
│ ≡ PRACTICE · LETTERS · 7 / 20      │
├────────────────────────────────────┤
│                                    │
│   feel it …  📳 · · · · ·          │
│                                    │
│   then type it on the six dots     │
│                                    │
│ ┌────────┬────────┐                │
│ │  [1]   │  [4]   │                │
│ ├────────┼────────┤   ≡ result:    │
│ │  [2]   │  [5]   │   ✓ B  (1.9 s) │
│ ├────────┼────────┤                │
│ │  [3]   │  [6]   │                │
│ └────────┴────────┘                │
└────────────────────────────────────┘
 long press = replay · double tap = skip · two-finger tap = end session (exports CSV)
 sets: LETTERS (20) · WORDS (10, 3–5 letters) · MESSAGE (one 5-word line)
```

Logs per item: truth, answer, correct, time to answer, replays. Session summary in large text and CSV (SPEC-T §Practice).

---

## Cross-screen rules

1. Everything that can be felt can be read: the `≡` mirror is always on.
2. No screen scrolls. If it does not fit, it is two screens.
3. Every state change gives a haptic code before it gives text.
4. The back gesture (two-finger tap) works everywhere and never asks "are you sure".
5. Fonts at 24 sp minimum on the mirror line, 20 sp elsewhere; contrast ≥ 7:1.
