import 'package:flutter/material.dart';

import 'core/haptics/haptic_engine.dart';
import 'features/home/fake_ports.dart';
import 'features/home/home_controller.dart';
import 'features/home/home_screen.dart';
import 'features/home/real_ports.dart';
import 'services/ai/ai_simplifier_config.dart';
import 'services/ai/http_message_simplifier.dart';
import 'services/ai/rule_based_simplifier.dart';
import 'services/launcher/android_app_launcher.dart';
import 'services/voice/android_speech_provider.dart';

/// Run the surface on fakes instead of the device:
///   flutter run --dart-define=GUSA_FAKE=true
const _useFakes = bool.fromEnvironment('GUSA_FAKE');

void main() {
  runApp(GusaApp(controller: _useFakes ? _fakeController() : _deviceController()));
}

HomeController _fakeController() => HomeController(
      voice: FakeVoice(),
      braille: FakeBraille(),
      haptic: FakeHaptic(),
      simplifier: FakeSimplifier(),
      launcher: FakeLauncher(),
    );

HomeController _deviceController() {
  // No API key configured -> HttpMessageSimplifier falls back to the rule-based
  // one, so the demo still runs with no network. A demo must never hang on a
  // network call.
  const config = AiSimplifierConfig();
  return HomeController(
    voice: RealVoice(AndroidSpeechProvider()),
    braille: const RealBraille(),
    haptic: RealHaptic(HapticEngine(const DeviceVibrator())),
    simplifier: RealSimplifier(
      HttpMessageSimplifier(
        config: config,
        fallback: const RuleBasedSimplifier(),
      ),
    ),
    launcher: const RealLauncher(AndroidAppLauncher()),
  );
}

class GusaApp extends StatelessWidget {
  const GusaApp({super.key, required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Gusa',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
        home: HomeScreen(controller: controller),
      );
}
