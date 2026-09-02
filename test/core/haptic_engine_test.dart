import 'package:flutter_test/flutter_test.dart';
import 'package:gusa/core/braille/braille_encoder.dart';
import 'package:gusa/core/haptics/haptic_engine.dart';

// Delay stub that resolves instantly, so unit tests never wait on real
// wall-clock time, and never need a device.
Future<void> _instantDelay(Duration duration) async {}

void main() {
  group('HapticEngine — dot rendering (D-009)', () {
    test('a known cell produces exactly the expected pulse sequence', () async {
      final fake = FakeVibrator();
      final engine = HapticEngine(fake, delay: _instantDelay);

      // 'b' = dots 1 and 2 raised, dots 3-6 absent.
      final cell = BrailleCell.fromDots([1, 2], 'b');

      await engine.render([cell]);

      expect(fake.calls, [
        const VibratorCall.vibrate(dotOnDurationMs),
        const VibratorCall.vibrate(dotOnDurationMs),
      ]);
    });

    test('dots are pulsed strictly in order 1..6', () async {
      final fake = FakeVibrator();
      final engine = HapticEngine(fake, delay: _instantDelay);

      // 'z' = dots 1, 3, 5, 6 raised — checks ordering, not just count.
      final cell = BrailleCell.fromDots([1, 3, 5, 6], 'z');

      await engine.render([cell]);

      expect(fake.calls.length, 4);
      expect(
        fake.calls,
        List.filled(4, const VibratorCall.vibrate(dotOnDurationMs)),
      );
    });

    test('an all-absent cell produces no vibration calls at all', () async {
      final fake = FakeVibrator();
      final engine = HapticEngine(fake, delay: _instantDelay);

      const blank = BrailleCell(
        dot1: false,
        dot2: false,
        dot3: false,
        dot4: false,
        dot5: false,
        dot6: false,
        char: '?',
      );

      await engine.render([blank]);

      expect(fake.calls, isEmpty);
    });
  });

  group('HapticEngine — pauses', () {
    test('an inter-cell pause is inserted between two characters', () async {
      final fake = FakeVibrator();
      final capturedDelays = <Duration>[];
      final engine = HapticEngine(
        fake,
        delay: (d) async {
          capturedDelays.add(d);
        },
      );

      final cells = [
        BrailleCell.fromDots([1], 'a'),
        BrailleCell.fromDots([1, 2], 'b'),
      ];

      await engine.render(cells);

      expect(
        capturedDelays,
        contains(const Duration(milliseconds: interCellPauseMs)),
      );
    });

    test('a word boundary uses the longer inter-word pause, not the '
        'inter-cell pause', () async {
      final fake = FakeVibrator();
      final capturedDelays = <Duration>[];
      final engine = HapticEngine(
        fake,
        delay: (d) async {
          capturedDelays.add(d);
        },
      );

      final cells = [
        BrailleCell.fromDots([1], 'a'),
        const BrailleCell.space(),
        BrailleCell.fromDots([1, 2], 'b'),
      ];

      await engine.render(cells);

      expect(
        capturedDelays,
        contains(const Duration(milliseconds: interWordPauseMs)),
      );
      expect(
        capturedDelays,
        isNot(contains(const Duration(milliseconds: interCellPauseMs))),
      );
    });
  });

  group('HapticEngine — cancel', () {
    test('cancel mid-render stops further pulses', () async {
      final fake = FakeVibrator();
      late HapticEngine engine;
      var delayCalls = 0;

      // Cancel partway through the very first cell's dot loop, right after
      // its first raised dot has already pulsed once.
      Future<void> cancellingDelay(Duration d) async {
        delayCalls++;
        if (delayCalls == 1) {
          engine.cancel();
        }
      }

      engine = HapticEngine(fake, delay: cancellingDelay);

      // Three fully-raised cells: if cancellation did nothing, this would
      // produce 18 vibrate() calls (3 cells x 6 dots).
      final cells = List.generate(
        3,
        (_) => BrailleCell.fromDots([1, 2, 3, 4, 5, 6], 'x'),
      );

      await engine.render(cells);

      expect(fake.calls.length, lessThan(18));
      // The engine also tells the vibrator to stop.
      expect(fake.calls, contains(const VibratorCall.cancel()));
    });
  });
}
