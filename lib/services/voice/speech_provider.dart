import 'dart:async';

/// State of the listening (speech-to-text) side of a [SpeechProvider].
///
/// Every failure mode gets its own named state on purpose. SPEC.md §21
/// requires a fallback path when speech is unavailable, so a failure must
/// never be indistinguishable from plain silence — callers branch on this
/// enum, not on absence of results.
enum ListeningState {
  /// Not currently listening. The provider is ready to start.
  notListening,

  /// Actively listening for speech.
  listening,

  /// The user (or the OS) denied microphone / speech-recognition
  /// permission.
  permissionDenied,

  /// No speech recognizer is available on this device, or it failed to
  /// initialize for a reason other than permission.
  recognizerUnavailable,

  /// Listening started but timed out with no speech detected.
  noSpeechDetected,

  /// An unexpected error occurred while listening.
  error,
}

/// State of the speaking (text-to-speech) side of a [SpeechProvider].
enum SpeakingState {
  /// Not currently speaking. The provider is ready to speak.
  idle,

  /// Actively speaking.
  speaking,

  /// No TTS engine is available on this device.
  ttsUnavailable,

  /// An unexpected error occurred while speaking.
  error,
}

/// A single speech-to-text result.
class SpeechResult {
  const SpeechResult(this.text, {required this.isFinal});

  /// The recognised text so far.
  final String text;

  /// True when this is the final transcript for the current listening
  /// session; false when it is an interim/partial result.
  final bool isFinal;

  @override
  String toString() => 'SpeechResult("$text", isFinal: $isFinal)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SpeechResult &&
          text == other.text &&
          isFinal == other.isFinal);

  @override
  int get hashCode => Object.hash(text, isFinal);
}

/// Boundary between Gusa's voice-consuming code (Conversation Mode, the
/// speak-this-for-me flow, etc.) and whatever actually listens and speaks.
///
/// Locked by D-003 (docs/DECISIONS.md): the only concrete implementation
/// shipped in the MVP is [AndroidSpeechProvider], wrapping Android's
/// on-device `SpeechRecognizer` + `TextToSpeech`. Cloud voice providers
/// (e.g. ElevenLabs, per SPEC.md §20) are explicitly out of the MVP, but a
/// future implementation of this interface could add one without touching
/// any caller — that is the entire point of the interface existing.
///
/// [FakeSpeechProvider] is a scriptable test/dev double: it lets the rest
/// of the app run with no microphone and no platform channels.
abstract class SpeechProvider {
  /// Prepares the provider for use: initializes underlying plugins/engines
  /// and (for listening) requests permission if needed. Must be called
  /// once before [startListening] or [speak]; safe to call more than once.
  ///
  /// Returns true if AT LEAST ONE direction (listening or speaking) is
  /// usable. The two directions can fail independently — always check
  /// [listeningState] / [speakingState] rather than assuming both work
  /// just because this returned true.
  Future<bool> initialize();

  // ---------------------------------------------------------------------
  // Listening (speech-to-text)
  // ---------------------------------------------------------------------

  /// The current listening state. Mirrors the latest value emitted on
  /// [listeningStateStream].
  ListeningState get listeningState;

  /// Broadcast stream of listening-state changes.
  Stream<ListeningState> get listeningStateStream;

  /// Broadcast stream of recognised speech. Emits partial results as they
  /// arrive (if the underlying engine supports them cheaply), followed by
  /// one final result ([SpeechResult.isFinal] == true) per successful
  /// [startListening] session.
  Stream<SpeechResult> get speechResults;

  /// Starts listening for speech. Moves [listeningState] to
  /// [ListeningState.listening] on success, or to a distinct failure state
  /// ([ListeningState.permissionDenied],
  /// [ListeningState.recognizerUnavailable], ...) on failure. Does not
  /// throw for expected failure modes — check [listeningState] after it
  /// completes (or listen on [listeningStateStream]).
  Future<void> startListening();

  /// Stops listening. Always leaves [listeningState] as
  /// [ListeningState.notListening] (or an existing terminal error state),
  /// never mid-listen.
  Future<void> stopListening();

  // ---------------------------------------------------------------------
  // Speaking (text-to-speech)
  // ---------------------------------------------------------------------

  /// The current speaking state. Mirrors the latest value emitted on
  /// [speakingStateStream].
  SpeakingState get speakingState;

  /// Broadcast stream of speaking-state changes.
  Stream<SpeakingState> get speakingStateStream;

  /// Speaks [text] aloud. The returned future completes once playback of
  /// [text] finishes, or once the provider fails to speak it. Does not
  /// throw for expected failure modes such as a missing TTS engine — check
  /// [speakingState] after it completes.
  Future<void> speak(String text);

  /// Stops any speech in progress. Leaves [speakingState] as
  /// [SpeakingState.idle] (or an existing terminal error/unavailable
  /// state).
  Future<void> stopSpeaking();

  /// Releases resources held by the provider (stream controllers, plugin
  /// listeners). Safe to call more than once.
  Future<void> dispose();
}
