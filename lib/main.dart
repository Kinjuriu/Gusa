import 'package:flutter/material.dart';
import 'features/home/fake_ports.dart';
import 'features/home/home_controller.dart';
import 'features/home/home_screen.dart';

void main() {
  // Fakes today so the surface is walkable with no device and no network.
  // Integration swaps these for the lane implementations; nothing else changes.
  final controller = HomeController(
    voice: FakeVoice(),
    braille: FakeBraille(),
    haptic: FakeHaptic(),
    simplifier: FakeSimplifier(),
    launcher: FakeLauncher(),
  );
  runApp(GusaApp(controller: controller));
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
