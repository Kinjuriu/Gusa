# SPEC I — Input lane (six-dot keyboard, gestures, quick replies)

**Developer:** Ian (@Ianodad), alongside Lane A · **Branch:** `feat/i/I1.2-gesture-engine` (first task: it has no dependencies; then I1.1, then I1.3) · **Reviewer:** Stephane (@Kinjuriu)
**Owns:** `lib/core/braille_keyboard/`, `lib/core/gestures/`, `lib/core/quick_reply/`, `test/core/braille_keyboard/`, `test/core/gestures/`, `test/core/quick_reply/`
**Reads:** [`TEAM-PLAN.md`](../TEAM-PLAN.md) §3–4, [`DECISIONS.md`](../DECISIONS.md) D-013, [`WIREFRAMES.md`](../WIREFRAMES.md) screens 1–5, [`SPEC.md`](../SPEC.md) §6, §9

Dispute anything here in your PR. The thresholds below are starting points, not facts.

## Goal

Let a person who cannot see the screen type Braille, control the app, and pick a reply, by touch alone, with a vibration answering every touch. Pure Dart widgets and one pointer-event engine. Testable with `WidgetTester`; verified on a phone.

## What you consume

- `Cell` and `BraillePort` from `lib/ports/` (Lane T implements; use `FakeBraille` until then).
- `HapticPort.code(HapticCode)` for every confirmation (Lane T implements; `FakeHaptic` logs).

## I1.2 · GestureEngine (M) — start here

File: `lib/core/gestures/gesture_engine.dart`, scoping in `lib/core/gestures/gesture_scope.dart`.

Input: raw `PointerEvent`s from a `Listener` that covers the screen. Output: a `Stream<GestureEvent>`.

```dart
enum Gesture { doubleTap, longPress, swipeLeft, swipeRight, swipeUp, swipeDown, twoFingerTap, tapCount }
class GestureEvent { final Gesture gesture; final int count; /* tapCount only */ }
```

Thresholds (constants in one place, overridable in tests):

| Gesture | Rule |
|---|---|
| tap | down and up within 250 ms, movement < 24 dp |
| doubleTap | two taps ≤ 300 ms apart, same finger count |
| tapCount | N taps each ≤ 300 ms apart, reported once 600 ms after the last (used by quick replies) |
| longPress | held ≥ 500 ms, movement < 24 dp |
| swipe | movement ≥ 60 dp in one dominant axis, released within 600 ms |
| twoFingerTap | two pointers down within 100 ms of each other, both up within 250 ms |

Scoping (TEAM-PLAN §3 rule): `GestureScope` holds per-screen bindings. A screen registers its own meanings; anything it does not bind falls through to the global vocabulary from SPEC §9 (double tap = confirm, long press = repeat, swipe left/right = previous/next, swipe down = back, swipe up = actions, two-finger tap = pause). The engine emits raw gestures; the scope maps them to actions and asks `HapticPort.code` for the matching code.

Tests (`test/core/gestures/`): synthetic pointer streams for each gesture; a scribble fixture (random jitter) must produce zero gestures; a chord of three simultaneous taps must produce **no** gesture (the keyboard owns chords).

## I1.1 · Six-dot keyboard widget (M)

File: `lib/core/braille_keyboard/six_dot_keyboard.dart`.

Layout (WIREFRAMES screen 3): the widget fills its parent; left column zones 1, 2, 3 top to bottom, right column 4, 5, 6. Zones are equal thirds of the height and halves of the width, drawn with thick rules and large numerals.

Chord rule: a chord starts on the first pointer down and ends when the **last** pointer lifts. The cell is the set of zones touched at any time during the chord. A pointer that moves ≥ 24 dp turns the whole interaction into a gesture and cancels the chord. On chord end: `onCell(Cell)` then `HapticPort.code(success)` (or the full cell if Settings say `cellEcho: full`, via `HapticPort.render([cell])`).

Gestures inside the keyboard (bound through `GestureScope`): swipe right = `onSpace`, swipe left = `onBackspace`, double tap = `onSend`, long press = `onRepeat` (replay typed text), two-finger tap = `onCancel`.

API:

```dart
SixDotKeyboard({
  required ValueChanged<Cell> onCell,
  required VoidCallback onSpace, onBackspace, onSend, onRepeat, onCancel,
  required HapticPort haptics,
  CellEcho echo = CellEcho.short,
})
```

Tests (`test/core/braille_keyboard/`): tapping zones 1 and 4 together yields `Cell([true,false,false,true,false,false])`; a single tap in zone 1 yields the A cell; a moving pointer cancels the chord and emits a swipe; the mirror text (rendered by the parent) is not your concern.

Verify on a phone: type `YES` with the phone flat on a table and again held in one hand; video; count mis-chords out of 20 attempts and put the number in the PR.

## I1.3 · Quick-reply selector (S)

File: `lib/core/quick_reply/quick_reply_selector.dart`.

Takes `List<String> replies` (1–3 items, already uppercase, ≤ 12 chars) and always appends `TYPE`. Shows them as numbered large-text rows (WIREFRAMES screen 2, REPLY state).

Selection, in this scope only (gesture scoping rule): `tapCount` N selects option N (1–3; 4 = TYPE); swipe up/down moves a highlight and plays `HapticPort.code` N times for option N; double tap selects the highlighted option; long press replays the message (`onRepeat`). Double tap does **not** mean "option 2" here, and two taps that are ≤ 300 ms apart are a double tap, not a count of two, so the count mode announces itself by waiting 600 ms.

API: `QuickReplySelector({required List<String> replies, required ValueChanged<String> onPick, required VoidCallback onType, onRepeat, required HapticPort haptics})`.

Tests: 1, 2 and 3 replies render N + 1 rows; tap-count 2 picks the second; tap-count 4 calls `onType`; swipe down twice then double tap picks the third.

## Stage 2: I2.1 accuracy pass (M)

Tune the chord window and add palm rejection (ignore pointers with contact size above a threshold, and pointers that start within 8 dp of the screen edge). Verify-by: chord error rate ≤ 5 % on the 500-word list typed by two developers, numbers in the PR.

## Definition of done, every PR

- [ ] Task ID in the PR title, one task per PR, target `develop`
- [ ] `flutter analyze` clean, `flutter test` green, widget tests for every widget
- [ ] Phone video for I1.1 and I1.3; mis-chord count in the PR
- [ ] Thresholds live in one constants file, not scattered

## How to start

```bash
git fetch && git checkout feat/i/I1.2-gesture-engine    # created for you from develop
flutter pub get && flutter test
flutter run --dart-define=GUSA_USE_FAKES=true
```

## Report format at each PR

Five lines: done / diverged / blocked · what you changed from this spec and why · phone tested on · anything the Tactile or App lane must know.
