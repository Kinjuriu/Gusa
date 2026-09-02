// Tests run against FakeSpeechProvider only: no device, no microphone, no
// platform channel. AndroidSpeechProvider talks to real plugins and is
// exercised manually on-device instead.

import 'package:flutter_test/flutter_test.dart';
import 'package:gusa/services/voice/fake_speech_provider.dart';
import 'package:gusa/services/voice/speech_provider.dart';

void main() {
  group('SpeechResult', () {
    test('equal when text and isFinal match', () {
      expect(
        const SpeechResult('hello', isFinal: true),
        const SpeechResult('hello', isFinal: true),
      );
    });

    test('not equal when isFinal differs', () {
      expect(
        const SpeechResult('hello', isFinal: true),
        isNot(const SpeechResult('hello', isFinal: false)),
      );
    });
  });

  group('FakeSpeechProvider — listening', () {
    test('starts in notListening with no queued phrases spoken', () async {
      final provider = FakeSpeechProvider();
      expect(provider.listeningState, ListeningState.notListening);
      expect(await provider.initialize(), isTrue);
    });

    test('a queued phrase reaches the result listener', () async {
      final provider = FakeSpeechProvider();
      await provider.initialize();
      provider.queuePhrase('hello world');

      final results = <SpeechResult>[];
      provider.speechResults.listen(results.add);

      await provider.startListening();
      await pumpEventQueue();

      expect(results, [const SpeechResult('hello world', isFinal: true)]);
      expect(provider.listeningState, ListeningState.listening);
    });

    test('multiple queued phrases reach the listener in order', () async {
      final provider = FakeSpeechProvider();
      await provider.initialize();
      provider.queuePhrases(['first', 'second', 'third']);

      final results = <SpeechResult>[];
      provider.speechResults.listen(results.add);

      await provider.startListening();
      await pumpEventQueue();

      expect(results.map((r) => r.text), ['first', 'second', 'third']);
    });

    test('a partial (non-final) queued result is delivered as partial', () async {
      final provider = FakeSpeechProvider();
      await provider.initialize();
      provider.queuePhrase('partial phrase', isFinal: false);

      final results = <SpeechResult>[];
      provider.speechResults.listen(results.add);

      await provider.startListening();
      await pumpEventQueue();

      expect(results, [const SpeechResult('partial phrase', isFinal: false)]);
    });

    test('permission denied produces a distinct listening state', () async {
      final provider = FakeSpeechProvider()
        ..simulatePermissionDenied = true;
      await provider.initialize();

      final states = <ListeningState>[];
      provider.listeningStateStream.listen(states.add);

      await provider.startListening();
      await pumpEventQueue();

      expect(provider.listeningState, ListeningState.permissionDenied);
      expect(states, contains(ListeningState.permissionDenied));
      // A permission failure must not silently look like listening.
      expect(states, isNot(contains(ListeningState.listening)));
    });

    test('recognizer unavailable produces a distinct listening state',
        () async {
      final provider = FakeSpeechProvider()
        ..simulateRecognizerUnavailable = true;
      await provider.initialize();

      await provider.startListening();

      expect(provider.listeningState, ListeningState.recognizerUnavailable);
    });

    test('permission denied and recognizer unavailable are distinct states',
        () async {
      final deniedProvider = FakeSpeechProvider()
        ..simulatePermissionDenied = true;
      final unavailableProvider = FakeSpeechProvider()
        ..simulateRecognizerUnavailable = true;

      await deniedProvider.startListening();
      await unavailableProvider.startListening();

      expect(deniedProvider.listeningState, ListeningState.permissionDenied);
      expect(
        unavailableProvider.listeningState,
        ListeningState.recognizerUnavailable,
      );
      expect(
        deniedProvider.listeningState,
        isNot(unavailableProvider.listeningState),
      );
    });

    test('no speech detected produces a distinct listening state, not a '
        'queued result', () async {
      final provider = FakeSpeechProvider()..simulateNoSpeechDetected = true;
      provider.queuePhrase('should not be delivered');

      final results = <SpeechResult>[];
      provider.speechResults.listen(results.add);

      await provider.startListening();
      await pumpEventQueue();

      expect(provider.listeningState, ListeningState.noSpeechDetected);
      expect(results, isEmpty);
    });

    test('stop() while listening leaves a clean not-listening state',
        () async {
      final provider = FakeSpeechProvider();
      provider.queuePhrase('hello');

      await provider.startListening();
      expect(provider.listeningState, ListeningState.listening);

      await provider.stopListening();

      expect(provider.listeningState, ListeningState.notListening);
    });

    test('stop() when never started is still a clean not-listening state',
        () async {
      final provider = FakeSpeechProvider();
      await provider.stopListening();
      expect(provider.listeningState, ListeningState.notListening);
    });
  });

  group('FakeSpeechProvider — speaking', () {
    test('speak() is recorded in spokenLog and completes', () async {
      final provider = FakeSpeechProvider();
      await provider.initialize();

      await provider.speak('hello there');

      expect(provider.spokenLog, ['hello there']);
      expect(provider.speakingState, SpeakingState.idle);
    });

    test('multiple speak() calls are recorded in order', () async {
      final provider = FakeSpeechProvider();
      await provider.speak('one');
      await provider.speak('two');

      expect(provider.spokenLog, ['one', 'two']);
    });

    test('speaking state transitions through speaking before idle',
        () async {
      final provider = FakeSpeechProvider();
      final states = <SpeakingState>[];
      provider.speakingStateStream.listen(states.add);

      await provider.speak('hello');
      await pumpEventQueue();

      expect(states, [SpeakingState.speaking, SpeakingState.idle]);
    });

    test('tts unavailable produces a distinct speaking state and still '
        'logs the attempt', () async {
      final provider = FakeSpeechProvider()..simulateTtsUnavailable = true;

      await provider.speak('hello');

      expect(provider.speakingState, SpeakingState.ttsUnavailable);
      expect(provider.spokenLog, ['hello']);
    });

    test('stopSpeaking() leaves a clean idle state', () async {
      final provider = FakeSpeechProvider();
      await provider.speak('hello');
      await provider.stopSpeaking();
      expect(provider.speakingState, SpeakingState.idle);
    });
  });

  group('FakeSpeechProvider — initialize', () {
    test('isInitialized flips to true after initialize()', () async {
      final provider = FakeSpeechProvider();
      expect(provider.isInitialized, isFalse);
      await provider.initialize();
      expect(provider.isInitialized, isTrue);
    });

    test('initialize() returns false when both directions are unavailable',
        () async {
      final provider = FakeSpeechProvider()
        ..simulateRecognizerUnavailable = true
        ..simulateTtsUnavailable = true;

      expect(await provider.initialize(), isFalse);
    });

    test(
        'initialize() returns true when only one direction is unavailable',
        () async {
      final provider = FakeSpeechProvider()..simulateTtsUnavailable = true;
      expect(await provider.initialize(), isTrue);
    });
  });
}
