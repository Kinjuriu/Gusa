import 'dart:async';
import 'dart:collection';

import 'speech_provider.dart';

/// Scriptable [SpeechProvider] test/dev double.
///
/// Queue phrases with [queuePhrase] / [queuePhrases] for [startListening]
/// to "hear"; read [spokenLog] to see everything [speak] was asked to say.
/// Set the `simulate*` flags to force a specific failure state, matching
/// the distinct states [AndroidSpeechProvider] can produce. Lets the rest
/// of the app (and its tests) run with no microphone and no platform
/// channels.
class FakeSpeechProvider implements SpeechProvider {
  final Queue<SpeechResult> _queuedResults = Queue<SpeechResult>();

  /// Every string passed to [speak], in call order — including ones that
  /// failed (e.g. because [simulateTtsUnavailable] was set), so tests can
  /// assert what was ATTEMPTED as well as what actually spoke.
  final List<String> spokenLog = <String>[];

  final StreamController<ListeningState> _listeningStateController =
      StreamController<ListeningState>.broadcast();
  final StreamController<SpeakingState> _speakingStateController =
      StreamController<SpeakingState>.broadcast();
  final StreamController<SpeechResult> _speechResultsController =
      StreamController<SpeechResult>.broadcast();

  ListeningState _listeningState = ListeningState.notListening;
  SpeakingState _speakingState = SpeakingState.idle;

  bool _initialized = false;

  /// True once [initialize] has been called at least once.
  bool get isInitialized => _initialized;

  /// When true, the next [startListening] call fails with
  /// [ListeningState.permissionDenied] instead of listening.
  bool simulatePermissionDenied = false;

  /// When true, the next [startListening] call fails with
  /// [ListeningState.recognizerUnavailable] instead of listening.
  bool simulateRecognizerUnavailable = false;

  /// When true, the next [startListening] call "listens" but times out
  /// with [ListeningState.noSpeechDetected] instead of delivering any
  /// queued result.
  bool simulateNoSpeechDetected = false;

  /// When true, [speak] fails with [SpeakingState.ttsUnavailable] instead
  /// of speaking.
  bool simulateTtsUnavailable = false;

  @override
  ListeningState get listeningState => _listeningState;

  @override
  Stream<ListeningState> get listeningStateStream =>
      _listeningStateController.stream;

  @override
  SpeakingState get speakingState => _speakingState;

  @override
  Stream<SpeakingState> get speakingStateStream =>
      _speakingStateController.stream;

  @override
  Stream<SpeechResult> get speechResults => _speechResultsController.stream;

  void _setListeningState(ListeningState state) {
    _listeningState = state;
    _listeningStateController.add(state);
  }

  void _setSpeakingState(SpeakingState state) {
    _speakingState = state;
    _speakingStateController.add(state);
  }

  /// Queues [phrase] as the next thing this fake "hears" when
  /// [startListening] is called. Delivered as a final result unless
  /// [isFinal] is set to false (useful for testing partial-result
  /// handling).
  void queuePhrase(String phrase, {bool isFinal = true}) {
    _queuedResults.add(SpeechResult(phrase, isFinal: isFinal));
  }

  /// Convenience for queuing several final-result phrases at once, in
  /// order.
  void queuePhrases(List<String> phrases) {
    for (final phrase in phrases) {
      queuePhrase(phrase);
    }
  }

  @override
  Future<bool> initialize() async {
    _initialized = true;
    if (simulatePermissionDenied) {
      _setListeningState(ListeningState.permissionDenied);
    } else if (simulateRecognizerUnavailable) {
      _setListeningState(ListeningState.recognizerUnavailable);
    }
    if (simulateTtsUnavailable) {
      _setSpeakingState(SpeakingState.ttsUnavailable);
    }
    final listeningOk =
        !simulatePermissionDenied && !simulateRecognizerUnavailable;
    final speakingOk = !simulateTtsUnavailable;
    return listeningOk || speakingOk;
  }

  @override
  Future<void> startListening() async {
    if (simulatePermissionDenied) {
      _setListeningState(ListeningState.permissionDenied);
      return;
    }
    if (simulateRecognizerUnavailable) {
      _setListeningState(ListeningState.recognizerUnavailable);
      return;
    }
    _setListeningState(ListeningState.listening);
    if (simulateNoSpeechDetected) {
      _setListeningState(ListeningState.noSpeechDetected);
      return;
    }
    while (_queuedResults.isNotEmpty) {
      _speechResultsController.add(_queuedResults.removeFirst());
    }
    // A real recognizer keeps listening until stopListening() is called
    // (or it decides on its own that it's done); this fake mirrors that by
    // staying in the listening state until stopListening() is called, even
    // once the queue has been drained.
  }

  @override
  Future<void> stopListening() async {
    _setListeningState(ListeningState.notListening);
  }

  @override
  Future<void> speak(String text) async {
    spokenLog.add(text);
    if (simulateTtsUnavailable) {
      _setSpeakingState(SpeakingState.ttsUnavailable);
      return;
    }
    _setSpeakingState(SpeakingState.speaking);
    _setSpeakingState(SpeakingState.idle);
  }

  @override
  Future<void> stopSpeaking() async {
    if (_speakingState != SpeakingState.ttsUnavailable) {
      _setSpeakingState(SpeakingState.idle);
    }
  }

  @override
  Future<void> dispose() async {
    await _listeningStateController.close();
    await _speakingStateController.close();
    await _speechResultsController.close();
  }
}
