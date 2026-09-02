import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'speech_provider.dart';

/// Real [SpeechProvider] implementation over Android's on-device
/// `SpeechRecognizer` (via `speech_to_text`) and `TextToSpeech` (via
/// `flutter_tts`).
///
/// Locked by D-003 (docs/DECISIONS.md): no cloud voice provider ships in
/// the MVP. This class is the only production implementation of
/// [SpeechProvider].
///
/// Not covered by unit tests: it talks to real platform channels, which
/// need a device/emulator. See `test/services/voice/` for tests against
/// `FakeSpeechProvider` instead, which exercises the same interface.
class AndroidSpeechProvider implements SpeechProvider {
  AndroidSpeechProvider({SpeechToText? speechToText, FlutterTts? flutterTts})
      : _speechToText = speechToText ?? SpeechToText(),
        _flutterTts = flutterTts ?? FlutterTts();

  final SpeechToText _speechToText;
  final FlutterTts _flutterTts;

  final StreamController<ListeningState> _listeningStateController =
      StreamController<ListeningState>.broadcast();
  final StreamController<SpeakingState> _speakingStateController =
      StreamController<SpeakingState>.broadcast();
  final StreamController<SpeechResult> _speechResultsController =
      StreamController<SpeechResult>.broadcast();

  ListeningState _listeningState = ListeningState.notListening;
  SpeakingState _speakingState = SpeakingState.idle;

  bool _sttInitialized = false;
  Completer<void>? _speakCompleter;

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
    if (_listeningStateController.isClosed) {
      return;
    }
    _listeningState = state;
    _listeningStateController.add(state);
  }

  void _setSpeakingState(SpeakingState state) {
    if (_speakingStateController.isClosed) {
      return;
    }
    _speakingState = state;
    _speakingStateController.add(state);
  }

  @override
  Future<bool> initialize() async {
    var listeningReady = false;
    try {
      _sttInitialized = await _speechToText.initialize(
        onError: _onSpeechError,
        onStatus: _onSpeechStatus,
      );
      listeningReady = _sttInitialized;
      if (!_sttInitialized &&
          _listeningState != ListeningState.permissionDenied) {
        _setListeningState(ListeningState.recognizerUnavailable);
      }
    } catch (_) {
      _sttInitialized = false;
      _setListeningState(ListeningState.recognizerUnavailable);
    }

    var speakingReady = false;
    try {
      final dynamic engines = await _flutterTts.getEngines;
      if (engines is List && engines.isEmpty) {
        _setSpeakingState(SpeakingState.ttsUnavailable);
      } else {
        speakingReady = true;
        _configureTtsHandlers();
        // Best-effort: not all platforms support this, ignore failures.
        unawaited(
          _flutterTts.awaitSpeakCompletion(true).catchError((_) => null),
        );
      }
    } catch (_) {
      _setSpeakingState(SpeakingState.ttsUnavailable);
    }

    return listeningReady || speakingReady;
  }

  void _configureTtsHandlers() {
    _flutterTts.setCompletionHandler(() {
      _setSpeakingState(SpeakingState.idle);
      _completeSpeak();
    });
    _flutterTts.setCancelHandler(() {
      _setSpeakingState(SpeakingState.idle);
      _completeSpeak();
    });
    _flutterTts.setErrorHandler((dynamic message) {
      _setSpeakingState(SpeakingState.error);
      _completeSpeak();
    });
  }

  void _completeSpeak() {
    final completer = _speakCompleter;
    _speakCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    final msg = error.errorMsg;
    if (msg.contains('permission')) {
      _setListeningState(ListeningState.permissionDenied);
    } else if (msg.contains('no_match') || msg.contains('speech_timeout')) {
      _setListeningState(ListeningState.noSpeechDetected);
    } else {
      _setListeningState(ListeningState.error);
    }
  }

  void _onSpeechStatus(String status) {
    if (status == SpeechToText.listeningStatus) {
      _setListeningState(ListeningState.listening);
    } else if (status == SpeechToText.notListeningStatus ||
        status == SpeechToText.doneStatus) {
      if (_listeningState == ListeningState.listening) {
        _setListeningState(ListeningState.notListening);
      }
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    _speechResultsController.add(
      SpeechResult(result.recognizedWords, isFinal: result.finalResult),
    );
  }

  @override
  Future<void> startListening() async {
    if (!_sttInitialized) {
      var ok = false;
      try {
        ok = await _speechToText.initialize(
          onError: _onSpeechError,
          onStatus: _onSpeechStatus,
        );
      } catch (_) {
        ok = false;
      }
      _sttInitialized = ok;
      if (!ok) {
        if (_listeningState != ListeningState.permissionDenied) {
          _setListeningState(ListeningState.recognizerUnavailable);
        }
        return;
      }
    }
    try {
      await _speechToText.listen(onResult: _onSpeechResult);
      // The plugin reports actual "listening" via the status callback,
      // which may arrive slightly later; set it here too so callers see an
      // immediate state change on a successful start.
      if (_listeningState != ListeningState.listening) {
        _setListeningState(ListeningState.listening);
      }
    } catch (_) {
      _setListeningState(ListeningState.error);
    }
  }

  @override
  Future<void> stopListening() async {
    try {
      await _speechToText.stop();
    } catch (_) {
      // stop() is best-effort; fall through to a clean not-listening state.
    }
    _setListeningState(ListeningState.notListening);
  }

  @override
  Future<void> speak(String text) async {
    if (_speakingState == SpeakingState.ttsUnavailable) {
      return;
    }
    _completeSpeak();
    final completer = Completer<void>();
    _speakCompleter = completer;
    _setSpeakingState(SpeakingState.speaking);
    try {
      await _flutterTts.speak(text);
    } catch (_) {
      _setSpeakingState(SpeakingState.error);
      _completeSpeak();
      return;
    }
    await completer.future;
  }

  @override
  Future<void> stopSpeaking() async {
    try {
      await _flutterTts.stop();
    } catch (_) {
      // stop() is best-effort; fall through to a clean idle state.
    }
    _completeSpeak();
    if (_speakingState != SpeakingState.ttsUnavailable) {
      _setSpeakingState(SpeakingState.idle);
    }
  }

  @override
  Future<void> dispose() async {
    _completeSpeak();
    await _listeningStateController.close();
    await _speakingStateController.close();
    await _speechResultsController.close();
  }
}
