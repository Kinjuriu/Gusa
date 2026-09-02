# SPEC T — Tactile lane (Braille engine, haptic engine, practice)

**Developer:** *assign* · **Branch:** `feat/t/T1.1-braille-engine` (first task; one branch per task ID after that) · **Reviewer:** Ian
**Owns:** `lib/core/braille/`, `lib/core/haptics/`, `lib/core/practice/`, `test/core/braille/`, `test/core/haptics/`, `test/core/practice/`
**Reads:** [`TEAM-PLAN.md`](../TEAM-PLAN.md) §3–4, [`DECISIONS.md`](../DECISIONS.md) D-008 D-009 D-013, [`WIREFRAMES.md`](../WIREFRAMES.md) screens 2, 3, 5, [`SPEC.md`](../SPEC.md) §6–8, §41

You are invited to dispute anything here. If a default below is wrong on a real phone, say so in the PR and propose the change; do not silently work around it.

## Goal

Turn text into Braille cells and Braille cells into vibrations a person can read, and back. Pure Dart. No UI except what practice mode needs. Everything unit-testable without a phone; everything *verified* on a phone.

## Ports you implement

Copy these signatures exactly; they live in `lib/ports/` (Lane A owns the file, you own the implementation). If the demo slice's `lib/features/home/ports.dart` differs, the versions here win and Lane A updates the port file.

```dart
class Cell {
  const Cell(this.dots, {this.char = '?'});
  final List<bool> dots;   // length 6, dots[0] == dot 1 … dots[5] == dot 6
  final String char;       // the character this cell came from, for the mirror
  static const blank = Cell([false, false, false, false, false, false], char: ' ');
}

abstract class BraillePort {
  List<Cell> encode(String text);
  String decode(List<Cell> cells);
  bool validate(Cell cell);
}

enum HapticCode { success, error, listening, message, confirm }

abstract class HapticPort {
  Future<void> render(List<Cell> cells);   // plays a whole message; resolves when done or cancelled
  Future<void> code(HapticCode code);
  Future<void> pause();
  Future<void> resume();
  Future<void> cancel();
  Stream<int> get progress;                // index of the cell being played, for the progress bar
}
```

## T1.1 · BrailleEngine (M)

File: `lib/core/braille/braille_engine.dart`, table in `lib/core/braille/grade1_table.dart`.

Standard: English Grade 1, UEB uncontracted (D-008).

| Input | Cells |
|---|---|
| a–z | the letter cell (a=1, b=12, c=14, d=145, e=15, f=124, g=1245, h=125, i=24, j=245, k=13, l=123, m=134, n=1345, o=135, p=1234, q=12345, r=1235, s=234, t=2345, u=136, v=1236, w=2456, x=1346, y=13456, z=1356) |
| A–Z | capital indicator (dot 6) then the letter |
| a run of digits | number indicator (3456) once, then digits as a–j (1=a … 0=j); a letter after the run resets |
| space | blank cell (word boundary; the haptic engine turns it into a word pause) |
| . , ? ! ' - : ; | 256, 2, 236, 235, 3, 36, 25, 23 |
| anything else | dropped; `encode` records it in `unsupported` so the mirror can show it |

`decode` mirrors `encode`, honours capital and number indicators, and returns `?` for a cell that is not in the table. `validate` returns false for a list that is not length 6.

`normalizeText` (private): trim, collapse whitespace, Unicode NFKC, curly quotes to straight.

Tests (`test/core/braille/`): round-trip on `test/fixtures/words_500.txt` (you create it: the 500 most common English words, one per line, mixed case, some with digits and punctuation added); every letter and indicator individually; invalid lengths rejected; unsupported characters reported not thrown.

## T1.2 · HapticEngine (M)

File: `lib/core/haptics/haptic_engine.dart`, timings in `lib/core/haptics/haptic_profile.dart`, plugin adapter in `lib/core/haptics/vibration_adapter.dart` (the only file that imports `vibration`).

Encoding (D-009 default, **dot-by-dot**): for each cell, six slots in order 1 to 6. A raised dot is a pulse of `dotOn` ms at `intensity`; an absent dot is silence of the same length. `slotGap` between slots, `charPause` after the cell, `wordPause` for a blank cell instead of a character pause.

| Profile | dotOn | slotGap | charPause | wordPause | intensity (1–255) |
|---|---|---|---|---|---|
| Beginner | 120 | 120 | 400 | 800 | 220 |
| Normal | 80 | 80 | 250 | 500 | 200 |
| Fast | 50 | 50 | 150 | 300 | 200 |
| Custom | user | user | user | user | user |

Write the table into `docs/HAPTICS.md` in Week 0 (task W0.3) before you code it, and note there any change you make after feeling it on a phone.

Build the whole message as one `pattern` and `intensities` list and hand it to `Vibration.vibrate(pattern: …, intensities: …)`; do not call the plugin per dot (Android drops short back-to-back calls). If `Vibration.hasAmplitudeControl()` is false, send pattern only. `cancel` calls `Vibration.cancel()`. `pause` cancels and remembers the cell index; `resume` rebuilds the pattern from that index. `progress` emits the cell index on a timer derived from the same timings, so the UI's progress bar and the motor agree.

Codes:

| Code | Pattern (ms on / off) |
|---|---|
| success | 60 on, 60 off, 60 on |
| error | 400 on |
| listening | 100 on, 100 off, 100 on, 100 off, 100 on |
| message | 60 on, 60 off, 250 on |
| confirm | 60 on, 60 off, 60 on, 60 off, 60 on |

Tests (`test/core/haptics/`): the pattern for `Cell` A in Normal is exactly `[0, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 250]` in the plugin's on/off form (write the expected lists by hand for A, B, and space); profile switch changes lengths; pause/resume resumes at the right index; no plugin call in unit tests (inject a fake adapter).

Verify on a phone: play `YES` in each profile; record a 20-second video with the mirror visible; note the phone model and `hasAmplitudeControl()` in the PR.

## T1.3 · Practice logger (M)

Files: `lib/core/practice/practice_session.dart`, `lib/core/practice/practice_export.dart`.

A session has a set (`letters`, `words`, `message`), plays an item through `HapticPort.render`, accepts an answer (a `List<Cell>` from the keyboard, decoded with your engine), and records `truth, answer, correct, msToAnswer, replays`. Summary: accuracy %, characters per minute, replays per item. `exportCsv()` returns the CSV text; Lane A writes it to a file and shares it.

Tests: a scripted session of 5 items produces the expected summary and CSV.

## Stage 2 (after the checkpoint): T2.1 tuning

Adjust the profile table from practice CSVs. Verify-by: at least 10 points up on the Stage 1 checkpoint accuracy, or ≥ 70 %.

## Definition of done, every PR

- [ ] Task ID in the PR title, one task per PR, target `develop`
- [ ] `flutter analyze` clean, `flutter test` green, new tests for new code
- [ ] Phone video for anything you can feel; phone model in the PR
- [ ] No import of `vibration` outside `vibration_adapter.dart`
- [ ] `docs/HAPTICS.md` updated if a timing changed

## How to start

```bash
git fetch && git checkout feat/t/T1.1-braille-engine    # created for you from develop
flutter pub get && flutter test
```

Work with the fakes: `flutter run --dart-define=GUSA_USE_FAKES=true`. Your engine replaces `FakeBraille` and `FakeHaptic`; Lane A wires it.

## Report format at each PR

Five lines: done / diverged / blocked · what you changed from this spec and why · phone tested on · anything the Input or App lane must know.
