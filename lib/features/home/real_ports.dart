import 'dart:async';

import 'package:gusa/core/braille/braille_encoder.dart' as bl;
import 'package:gusa/core/haptics/haptic_engine.dart' as hp;
import 'package:gusa/services/ai/message_simplifier.dart' as ai;
import 'package:gusa/services/launcher/app_launcher.dart' as lz;
import 'package:gusa/services/launcher/app_resolver.dart' as lz;
import 'package:gusa/services/launcher/launcher_app.dart' as lz;
import 'package:gusa/services/voice/speech_provider.dart' as vp;

import 'ports.dart';

/// Adapters from the three lanes' interfaces onto the narrow ports the home
/// surface uses. Keeping the seam here means the surface never changes when a
/// lane's internals do.

class RealBraille implements BraillePort {
  const RealBraille([this._encoder = const bl.BrailleEncoder()]);
  final bl.BrailleEncoder _encoder;

  @override
  List<Cell> encode(String text) =>
      _encoder.encode(text).map((c) => Cell(c.dots, char: c.char)).toList();
}

class RealHaptic implements HapticPort {
  RealHaptic(this._engine);
  final hp.HapticEngine _engine;

  @override
  Future<void> render(List<Cell> cells) => _engine.render(cells
      .map((c) => bl.BrailleCell.fromDots(
            [for (var i = 0; i < c.dots.length; i++) if (c.dots[i]) i + 1],
            c.char,
          ))
      .toList());

  @override
  Future<void> cancel() async => _engine.cancel();
}

class RealVoice implements VoicePort {
  RealVoice(this._provider, {this.listenTimeout = const Duration(seconds: 12)});
  final vp.SpeechProvider _provider;
  final Duration listenTimeout;
  bool _ready = false;

  /// The in-flight listen, so stop() can resolve it instead of leaving it
  /// parked until the timeout fires and overwrites the screen later.
  Completer<Heard>? _active;

  Future<void> _ensureReady() async {
    if (_ready) return;
    _ready = await _provider.initialize();
  }

  /// Listens until the recogniser returns a final result, then stops. Every
  /// non-result outcome carries its own reason (SPEC §21) so the caller can
  /// tell a denied microphone apart from actual silence.
  @override
  Future<Heard> listenOnce() async {
    await _ensureReady();
    if (!_ready) return const Heard.failed(VoiceFailure.recognizerUnavailable);

    final done = Completer<Heard>();
    _active = done;
    late StreamSubscription<vp.SpeechResult> results;
    late StreamSubscription<vp.ListeningState> states;

    void finish(Heard value) {
      if (!done.isCompleted) done.complete(value);
    }

    results = _provider.speechResults.listen((r) {
      if (r.isFinal && r.text.trim().isNotEmpty) finish(Heard.text(r.text));
    });
    states = _provider.listeningStateStream.listen((s) {
      switch (s) {
        case vp.ListeningState.permissionDenied:
          finish(const Heard.failed(VoiceFailure.permissionDenied));
        case vp.ListeningState.recognizerUnavailable:
          finish(const Heard.failed(VoiceFailure.recognizerUnavailable));
        case vp.ListeningState.noSpeechDetected:
          finish(const Heard.failed(VoiceFailure.noSpeech));
        case vp.ListeningState.error:
          finish(const Heard.failed(VoiceFailure.error));
        case vp.ListeningState.listening:
        case vp.ListeningState.notListening:
          break;
      }
    });

    try {
      await _provider.startListening();
      return await done.future.timeout(
        listenTimeout,
        onTimeout: () => const Heard.failed(VoiceFailure.timeout),
      );
    } finally {
      _active = null;
      await results.cancel();
      await states.cancel();
      await _provider.stopListening();
    }
  }

  @override
  Future<void> speak(String text) async {
    await _ensureReady();
    await _provider.speak(text);
  }

  @override
  Future<void> stop() async {
    // Resolve the parked listen first, so it cannot surface an error banner
    // seconds after the user pressed Stop.
    final active = _active;
    if (active != null && !active.isCompleted) {
      active.complete(const Heard.failed(VoiceFailure.cancelled));
    }
    await _provider.stopListening();
    await _provider.stopSpeaking();
  }
}

class RealSimplifier implements SimplifierPort {
  const RealSimplifier(this._inner);
  final ai.MessageSimplifier _inner;

  @override
  Future<String> simplify(String spoken) => _inner.simplify(spoken);
}

class RealLauncher implements LauncherPort {
  const RealLauncher(this._launcher, [this._resolver = const lz.AppResolver()]);
  final lz.AppLauncher _launcher;
  final lz.AppResolver _resolver;

  @override
  Future<List<LaunchableApp>> installedApps() async {
    final apps = await _launcher.getInstalledApps();
    return apps.map((a) => LaunchableApp(a.name, a.packageName)).toList();
  }

  @override
  Resolution resolve(String phrase, List<LaunchableApp> apps) {
    final res = _resolver.resolve(
      phrase,
      apps.map((a) => lz.LauncherApp(name: a.name, packageName: a.package)).toList(),
    );
    if (!res.hasMatch) return Resolution.none;
    return Resolution(
      res.matches.map((m) => LaunchableApp(m.app.name, m.app.packageName)).toList(),
      needsConfirmation: res.requiresConfirmation,
    );
  }

  @override
  Future<bool> launch(String package) => _launcher.launchApp(package);
}
