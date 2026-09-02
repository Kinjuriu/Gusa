// Local haptic renderer: turns Braille cells into vibration (SPEC.md §8).
//
// D-009: dot-by-dot encoding in order 1..6, with present/absent slots.
// A present dot is a longer pulse; an absent dot is a short silent
// gap-marker so the user still feels the slot "pass" without a buzz.

import 'dart:async' show unawaited;

import 'package:vibration/vibration.dart';

import '../braille/braille_encoder.dart';

/// --- Timings (ms) ---------------------------------------------------
/// All named and grouped here so they are easy to tune on-device without
/// hunting through the render loop. Keep them realistic for a phone
/// vibration motor: too short and dots blur together, too long and
/// playback feels sluggish.

/// Duration of a vibration pulse for a raised (present) dot.
const int dotOnDurationMs = 120;

/// Duration of the silent gap that marks an absent (not-raised) dot slot.
/// Intentionally shorter than [dotOnDurationMs] so present vs. absent is
/// unambiguous by feel.
const int dotOffDurationMs = 60;

/// Short pause after a present dot's pulse finishes, before the next dot
/// slot starts. Prevents consecutive raised dots from blurring into one
/// continuous buzz.
const int interDotPauseMs = 40;

/// Pause between Braille cells (characters) within the same word.
const int interCellPauseMs = 300;

/// Pause between words. Longer than [interCellPauseMs] so a word boundary
/// is clearly distinguishable from a character boundary.
const int interWordPauseMs = 700;

/// Abstraction over the device vibrator so [HapticEngine] can be unit
/// tested without a real Android device.
abstract class Vibrator {
  /// Fires a single vibration pulse lasting [durationMs].
  Future<void> vibrate(int durationMs);

  /// Stops any vibration currently in progress.
  Future<void> cancel();
}

/// Real device implementation, backed by the `vibration` plugin.
class DeviceVibrator implements Vibrator {
  const DeviceVibrator();

  @override
  Future<void> vibrate(int durationMs) => Vibration.vibrate(duration: durationMs);

  @override
  Future<void> cancel() => Vibration.cancel();
}

/// A single recorded call made against a [FakeVibrator], for assertions.
class VibratorCall {
  const VibratorCall.vibrate(this.durationMs) : isCancel = false;
  const VibratorCall.cancel() : durationMs = null, isCancel = true;

  final int? durationMs;
  final bool isCancel;

  @override
  String toString() =>
      isCancel ? 'VibratorCall.cancel()' : 'VibratorCall.vibrate($durationMs)';

  @override
  bool operator ==(Object other) =>
      other is VibratorCall &&
      other.durationMs == durationMs &&
      other.isCancel == isCancel;

  @override
  int get hashCode => Object.hash(durationMs, isCancel);
}

/// In-memory [Vibrator] that records every call instead of touching real
/// hardware. Used by unit tests and safe to use anywhere a device is
/// unavailable.
class FakeVibrator implements Vibrator {
  final List<VibratorCall> calls = <VibratorCall>[];

  @override
  Future<void> vibrate(int durationMs) async {
    calls.add(VibratorCall.vibrate(durationMs));
  }

  @override
  Future<void> cancel() async {
    calls.add(const VibratorCall.cancel());
  }
}

/// Function used to wait between pulses. Injectable so unit tests can run
/// instantly instead of waiting on real wall-clock delays.
typedef DelayFn = Future<void> Function(Duration duration);

Future<void> _defaultDelay(Duration duration) => Future.delayed(duration);

/// Renders a list of [BrailleCell]s as vibration, dot-by-dot, in order
/// 1..6 (D-009).
class HapticEngine {
  HapticEngine(this._vibrator, {DelayFn delay = _defaultDelay}) : _delay = delay;

  final Vibrator _vibrator;
  final DelayFn _delay;

  bool _cancelled = false;

  /// Stops rendering as soon as possible. Safe to call at any time,
  /// including before [render] has started or after it has finished.
  void cancel() {
    _cancelled = true;
    unawaited(_vibrator.cancel());
  }

  /// Renders [cells] as vibration: each cell's raised dots are pulsed in
  /// order 1..6, with a pause between cells and a longer pause between
  /// words (cells where [BrailleCell.isSpace] is true).
  ///
  /// Returns early if [cancel] is called while rendering is in progress.
  Future<void> render(List<BrailleCell> cells) async {
    _cancelled = false;

    for (var i = 0; i < cells.length; i++) {
      if (_cancelled) return;
      final cell = cells[i];

      if (cell.isSpace) {
        // Word boundaries carry no dots of their own; the pause after the
        // previous cell already accounts for them (see below).
        continue;
      }

      await _renderCellDots(cell);
      if (_cancelled) return;

      final isLastCell = i == cells.length - 1;
      if (isLastCell) continue;

      final nextIsSpace = cells[i + 1].isSpace;
      await _delay(
        Duration(milliseconds: nextIsSpace ? interWordPauseMs : interCellPauseMs),
      );
    }
  }

  Future<void> _renderCellDots(BrailleCell cell) async {
    final dots = cell.dots;
    for (var slot = 0; slot < dots.length; slot++) {
      if (_cancelled) return;

      if (dots[slot]) {
        await _vibrator.vibrate(dotOnDurationMs);
        if (_cancelled) return;
        await _delay(Duration(milliseconds: dotOnDurationMs));
        if (_cancelled) return;
        await _delay(Duration(milliseconds: interDotPauseMs));
      } else {
        await _delay(Duration(milliseconds: dotOffDurationMs));
      }
    }
  }
}
