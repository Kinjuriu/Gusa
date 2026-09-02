import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gusa/features/home/fake_ports.dart';
import 'package:gusa/features/home/home_controller.dart';
import 'package:gusa/features/home/ports.dart';
import 'package:gusa/features/home/home_screen.dart';

HomeController buildController({FakeVoice? voice, FakeLauncher? launcher}) =>
    HomeController(
      voice: voice ?? FakeVoice(),
      braille: FakeBraille(),
      haptic: FakeHaptic(),
      simplifier: FakeSimplifier(),
      launcher: launcher ?? FakeLauncher(),
    );

void main() {
  testWidgets('always-on surface shows LISTEN and the app tiles', (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: HomeScreen(controller: buildController())));
    await tester.pumpAndSettle();

    expect(find.text('LISTEN'), findsOneWidget);
    expect(find.text('OPEN BY VOICE'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
  });

  test('Journey A: heard -> shortened -> braille cells (SPEC 5)', () async {
    final c = buildController();
    await c.listenAndFeel();

    expect(c.heard, isNotEmpty);
    expect(c.simplified, isNotEmpty);
    expect(c.cells, isNotEmpty);
    expect(c.phase, Phase.idle);
  });

  testWidgets('surface renders heard / shortened / braille once the journey ran',
      (tester) async {
    final c = buildController();
    // runAsync uses the real clock; the fake ports await real Durations, which
    // never elapse inside the widget tester's fake-async zone.
    await tester.runAsync(() => c.listenAndFeel());

    await tester.pumpWidget(MaterialApp(home: HomeScreen(controller: c)));
    await tester.pumpAndSettle();

    expect(find.text('HEARD'), findsOneWidget);
    expect(find.text('SHORTENED'), findsOneWidget);
    expect(find.text('FELT AS BRAILLE'), findsOneWidget);
  });

  test('simplifier shortens a spoken sentence and keeps the question', () async {
    final out = await FakeSimplifier()
        .simplify('There is an AI meetup tomorrow. Would you like to attend?');
    expect(out.length, lessThan(40));
    expect(out, contains('?'));
    expect(out, equals(out.toUpperCase()));
  });

  test('ambiguous app phrase surfaces candidates instead of guessing', () async {
    final launcher = FakeLauncher();
    final c = buildController(
      voice: FakeVoice(script: const ['me']),
      launcher: launcher,
    );
    await c.loadApps();
    await c.openByVoice();

    expect(c.phase, Phase.choosing);
    expect(c.candidates.length, greaterThan(1));
    expect(launcher.launched, isEmpty, reason: 'must not open an app while ambiguous');
  });

  test('a partial phrase asks for confirmation instead of opening', () async {
    final launcher = FakeLauncher();
    final c = buildController(
      voice: FakeVoice(script: const ['whats']),
      launcher: launcher,
    );
    await c.loadApps();
    await c.openByVoice();

    expect(c.phase, Phase.choosing);
    expect(launcher.launched, isEmpty,
        reason: 'a partial match must be confirmed, not guessed');
  });

  test('an exact app name opens straight away', () async {
    final launcher = FakeLauncher();
    final c = buildController(
      voice: FakeVoice(script: const ['WhatsApp']),
      launcher: launcher,
    );
    await c.loadApps();
    await c.openByVoice();

    expect(launcher.launched, ['com.whatsapp']);
  });

  test('silence is reported, not swallowed', () async {
    final c = buildController(voice: FakeVoice(script: const ['']));
    await c.listenAndFeel();
    expect(c.phase, Phase.error);
    expect(c.message, contains('Nothing heard'));
  });

  // SPEC 21: a failure must never be indistinguishable from silence.
  test('each voice failure gets its own message, not "Nothing heard"', () async {
    final cases = {
      VoiceFailure.permissionDenied: 'Microphone permission denied',
      VoiceFailure.recognizerUnavailable: 'Speech recogniser unavailable',
      VoiceFailure.timeout: 'Timed out before any speech',
      VoiceFailure.error: 'Voice failed',
    };
    for (final entry in cases.entries) {
      final c = buildController(voice: FakeVoice(failWith: entry.key));
      await c.listenAndFeel();
      expect(c.phase, Phase.error, reason: '${entry.key}');
      expect(c.message, entry.value, reason: '${entry.key}');
    }
  });

  test('a cancelled listen is not an error', () async {
    final c = buildController(
        voice: FakeVoice(failWith: VoiceFailure.cancelled));
    await c.listenAndFeel();
    expect(c.phase, Phase.idle);
  });

  test('a failed app launch is reported, never as success', () async {
    final launcher = FakeLauncher()..launchSucceeds = false;
    final c = buildController(launcher: launcher);
    await c.loadApps();
    await c.openApp(const LaunchableApp('WhatsApp', 'com.whatsapp'));

    expect(c.phase, Phase.error);
    expect(c.message, contains('Could not open'));
  });

  test('a second voice operation cannot start while one is live', () async {
    final c = buildController();
    final first = c.listenAndFeel();
    // Same shared recogniser session — the second call must be refused.
    await c.openByVoice();
    expect(c.heard, isEmpty, reason: 'second op must not have run');
    await first;
    expect(c.heard, isNotEmpty);
  });
}
