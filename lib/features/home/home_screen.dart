import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'braille_view.dart';
import 'home_controller.dart';

/// The always-on surface. Everything is reachable by TAP or by SPEECH, with
/// oversized targets and haptic confirmation on every press.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});
  final HomeController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    c.addListener(_onChange);
    c.loadApps();
  }

  @override
  void dispose() {
    c.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  Future<void> _tap(Future<void> Function() action) async {
    await HapticFeedback.mediumImpact();
    await action();
  }

  @override
  Widget build(BuildContext context) {
    final busy = c.phase != Phase.idle && c.phase != Phase.error && c.phase != Phase.choosing;
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatusBanner(phase: c.phase, message: c.message),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (c.heard.isNotEmpty) ...[
                        _Label('HEARD'),
                        Text(c.heard,
                            style: const TextStyle(color: Colors.white70, fontSize: 17)),
                        const SizedBox(height: 16),
                      ],
                      if (c.simplified.isNotEmpty) ...[
                        _Label('SHORTENED'),
                        Text(c.simplified,
                            style: const TextStyle(
                                color: Color(0xFFFFD166),
                                fontSize: 30,
                                height: 1.25,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 18),
                      ],
                      if (c.cells.isNotEmpty) ...[
                        _Label('FELT AS BRAILLE'),
                        BrailleView(cells: c.cells),
                        const SizedBox(height: 18),
                      ],
                      if (c.phase == Phase.choosing) ...[
                        _Label('WHICH ONE?'),
                        for (final a in c.candidates)
                          _BigButton(
                            label: a.name,
                            onTap: () => _tap(() => c.openApp(a)),
                          ),
                        const SizedBox(height: 18),
                      ],
                      _Label('APPS — TAP TO OPEN'),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final a in c.apps)
                            _Tile(label: a.name, onTap: () => _tap(() => c.openApp(a))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _BigButton(
                label: busy ? 'STOP' : 'LISTEN',
                primary: true,
                onTap: () => _tap(busy ? c.stopEverything : c.listenAndFeel),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _BigButton(
                      label: 'OPEN BY VOICE',
                      onTap: () => _tap(c.openByVoice),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _BigButton(
                      label: 'SPEAK "YES"',
                      onTap: () => _tap(() => c.speakReply('Yes')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.phase, required this.message});
  final Phase phase;
  final String message;

  @override
  Widget build(BuildContext context) {
    final err = phase == Phase.error;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: err ? const Color(0xFF3A1414) : const Color(0xFF16161D),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: err
                  ? const Color(0xFFFF6B6B)
                  : (phase == Phase.idle
                      ? const Color(0xFF3DDC97)
                      : const Color(0xFFFFD166)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message.isEmpty ? 'Ready' : message,
              style: const TextStyle(
                  color: Colors.white, fontSize: 19, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w700)),
      );
}

class _BigButton extends StatelessWidget {
  const _BigButton({required this.label, required this.onTap, this.primary = false});
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: primary ? const Color(0xFFFFD166) : const Color(0xFF22222B),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: primary ? 96 : 72,
                alignment: Alignment.center,
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: primary ? const Color(0xFF0B0B0F) : Colors.white,
                        fontSize: primary ? 30 : 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8)),
              ),
            ),
          ),
        ),
      );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: Material(
          color: const Color(0xFF22222B),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 150,
              height: 92,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(10),
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      );
}
