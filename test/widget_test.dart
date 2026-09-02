import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gusa/features/home/fake_ports.dart';
import 'package:gusa/features/home/home_controller.dart';
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

  test('unambiguous phrase opens the app', () async {
    final launcher = FakeLauncher();
    final c = buildController(
      voice: FakeVoice(script: const ['whats']),
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
}
