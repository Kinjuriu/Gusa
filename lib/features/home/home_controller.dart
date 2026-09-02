import 'package:flutter/foundation.dart';
import 'ports.dart';

enum Phase { idle, listening, simplifying, feeling, speaking, choosing, error }

/// Journey A (SPEC §5): person speaks -> text -> AI simplification -> Braille ->
/// haptics -> user feels it. Plus the always-on launcher: reach an app by tap or
/// by speech.
///
/// Pure orchestration over [ports.dart]; no Flutter widgets, no plugins, so it
/// is unit-testable without a device.
class HomeController extends ChangeNotifier {
  HomeController({
    required this.voice,
    required this.braille,
    required this.haptic,
    required this.simplifier,
    required this.launcher,
  });

  final VoicePort voice;
  final BraillePort braille;
  final HapticPort haptic;
  final SimplifierPort simplifier;
  final LauncherPort launcher;

  /// Guards against a second voice operation starting while one is live: the
  /// recogniser is a single shared session, and a concurrent start loses the
  /// first one's result.
  bool _busy = false;
  bool get busy => _busy;

  Phase phase = Phase.idle;
  String heard = '';
  String simplified = '';
  List<Cell> cells = const [];
  String message = '';
  List<LaunchableApp> apps = const [];
  List<LaunchableApp> candidates = const [];

  void _set(Phase p, {String? msg}) {
    phase = p;
    if (msg != null) message = msg;
    notifyListeners();
  }

  static String _describe(VoiceFailure f) => switch (f) {
        VoiceFailure.permissionDenied => 'Microphone permission denied',
        VoiceFailure.recognizerUnavailable => 'Speech recogniser unavailable',
        VoiceFailure.noSpeech => 'Nothing heard',
        VoiceFailure.timeout => 'Timed out before any speech',
        VoiceFailure.cancelled => 'Stopped',
        VoiceFailure.error => 'Voice failed',
      };

  Future<void> loadApps() async {
    apps = await launcher.installedApps();
    notifyListeners();
  }

  /// The demo's spine. Listen once, shorten it, feel it.
  Future<void> listenAndFeel() async {
    if (_busy) return;
    _busy = true;
    try {
      _set(Phase.listening, msg: 'Listening');
      final result = await voice.listenOnce();
      if (!result.ok) {
        final f = result.failure ?? VoiceFailure.noSpeech;
        // Cancelling is not an error — the user asked for it.
        _set(f == VoiceFailure.cancelled ? Phase.idle : Phase.error,
            msg: _describe(f));
        return;
      }
      heard = result.text!;

      _set(Phase.simplifying, msg: 'Shortening');
      simplified = await simplifier.simplify(heard);

      cells = braille.encode(simplified);
      _set(Phase.feeling, msg: 'Feel it');
      await haptic.render(cells);

      _set(Phase.idle, msg: 'Ready');
    } catch (e) {
      _set(Phase.error, msg: 'Failed: $e');
    } finally {
      _busy = false;
    }
  }

  /// The blind-deaf user's reply is spoken aloud for the hearing person (§43).
  Future<void> speakReply(String reply) async {
    if (_busy) return;
    _busy = true;
    try {
      _set(Phase.speaking, msg: 'Speaking');
      await voice.speak(reply);
      _set(Phase.idle, msg: 'Ready');
    } catch (e) {
      _set(Phase.error, msg: 'Failed: $e');
    } finally {
      _busy = false;
    }
  }

  /// Reach an app by SPEECH. Ambiguity is surfaced, never guessed — a
  /// blind-deaf user cannot see that the wrong app opened.
  Future<void> openByVoice() async {
    if (_busy) return;
    _busy = true;
    try {
      _set(Phase.listening, msg: 'Say an app name');
      final result = await voice.listenOnce();
      if (!result.ok) {
        final f = result.failure ?? VoiceFailure.noSpeech;
        _set(f == VoiceFailure.cancelled ? Phase.idle : Phase.error,
            msg: _describe(f));
        return;
      }
      final phrase = result.text!;
      if (apps.isEmpty) await loadApps();
      final found = launcher.resolve(phrase, apps);
      if (found.isEmpty) {
        candidates = const [];
        _set(Phase.error, msg: 'No app matches "$phrase"');
        return;
      }
      // Only a certain, single match opens straight away. Anything else is
      // offered for confirmation — never guessed.
      if (found.needsConfirmation || found.candidates.length > 1) {
        candidates = found.candidates;
        _set(Phase.choosing, msg: 'Which one?');
        return;
      }
      await openApp(found.candidates.first);
    } catch (e) {
      _set(Phase.error, msg: 'Failed: $e');
    } finally {
      _busy = false;
    }
  }

  /// Reach an app by TAP.
  Future<void> openApp(LaunchableApp app) async {
    candidates = const [];
    await haptic.render(braille.encode(app.name));
    final started = await launcher.launch(app.package);
    // Never claim success when the app did not actually start — the user
    // cannot see an empty screen.
    _set(started ? Phase.idle : Phase.error,
        msg: started ? 'Opened ${app.name}' : 'Could not open ${app.name}');
  }

  Future<void> stopEverything() async {
    await haptic.cancel();
    // voice.stop() resolves any in-flight listenOnce() with `cancelled`, so the
    // parked operation cannot overwrite the screen seconds later.
    await voice.stop();
    _busy = false;
    _set(Phase.idle, msg: 'Stopped');
  }
}
