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

  Future<void> loadApps() async {
    apps = await launcher.installedApps();
    notifyListeners();
  }

  /// The demo's spine. Listen once, shorten it, feel it.
  Future<void> listenAndFeel() async {
    try {
      _set(Phase.listening, msg: 'Listening');
      final text = await voice.listenOnce();
      if (text == null || text.trim().isEmpty) {
        _set(Phase.error, msg: 'Nothing heard');
        return;
      }
      heard = text;

      _set(Phase.simplifying, msg: 'Shortening');
      simplified = await simplifier.simplify(text);

      cells = braille.encode(simplified);
      _set(Phase.feeling, msg: 'Feel it');
      await haptic.render(cells);

      _set(Phase.idle, msg: 'Ready');
    } catch (e) {
      _set(Phase.error, msg: 'Failed: $e');
    }
  }

  /// The blind-deaf user's reply is spoken aloud for the hearing person (§43).
  Future<void> speakReply(String reply) async {
    try {
      _set(Phase.speaking, msg: 'Speaking');
      await voice.speak(reply);
      _set(Phase.idle, msg: 'Ready');
    } catch (e) {
      _set(Phase.error, msg: 'Failed: $e');
    }
  }

  /// Reach an app by SPEECH. Ambiguity is surfaced, never guessed — a
  /// blind-deaf user cannot see that the wrong app opened.
  Future<void> openByVoice() async {
    try {
      _set(Phase.listening, msg: 'Say an app name');
      final phrase = await voice.listenOnce();
      if (phrase == null || phrase.trim().isEmpty) {
        _set(Phase.error, msg: 'Nothing heard');
        return;
      }
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
    }
  }

  /// Reach an app by TAP.
  Future<void> openApp(LaunchableApp app) async {
    candidates = const [];
    await haptic.render(braille.encode(app.name));
    await launcher.launch(app.package);
    _set(Phase.idle, msg: 'Opened ${app.name}');
  }

  Future<void> stopEverything() async {
    await haptic.cancel();
    await voice.stop();
    _set(Phase.idle, msg: 'Stopped');
  }
}
