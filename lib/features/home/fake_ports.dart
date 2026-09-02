import 'dart:async';
import 'ports.dart';

/// Runs the whole surface with no device, no microphone and no network, so the
/// demo is walkable before the lane implementations land.
class FakeBraille implements BraillePort {
  // Grade-1 UEB for the handful of letters the fake needs. The real encoder
  // (lane T) replaces this wholesale.
  static const _map = <String, List<int>>{
    'a': [1], 'b': [1, 2], 'c': [1, 4], 'd': [1, 4, 5], 'e': [1, 5],
    'f': [1, 2, 4], 'g': [1, 2, 4, 5], 'h': [1, 2, 5], 'i': [2, 4],
    'j': [2, 4, 5], 'k': [1, 3], 'l': [1, 2, 3], 'm': [1, 3, 4],
    'n': [1, 3, 4, 5], 'o': [1, 3, 5], 'p': [1, 2, 3, 4], 'q': [1, 2, 3, 4, 5],
    'r': [1, 2, 3, 5], 's': [2, 3, 4], 't': [2, 3, 4, 5], 'u': [1, 3, 6],
    'v': [1, 2, 3, 6], 'w': [2, 4, 5, 6], 'x': [1, 3, 4, 6],
    'y': [1, 3, 4, 5, 6], 'z': [1, 3, 5, 6],
  };

  @override
  List<Cell> encode(String text) => text.toLowerCase().split('').map((ch) {
        if (ch == ' ' || ch == '\n') return Cell.blank;
        final dots = _map[ch];
        if (dots == null) return Cell.blank;
        final on = List<bool>.filled(6, false);
        for (final d in dots) {
          on[d - 1] = true;
        }
        return Cell(on, char: ch);
      }).toList();
}

class FakeHaptic implements HapticPort {
  bool _cancelled = false;
  final List<String> played = [];

  @override
  Future<void> render(List<Cell> cells) async {
    _cancelled = false;
    for (final c in cells) {
      if (_cancelled) return;
      played.add(c.char);
      await Future<void>.delayed(const Duration(milliseconds: 60));
    }
  }

  @override
  Future<void> cancel() async => _cancelled = true;
}

class FakeVoice implements VoicePort {
  FakeVoice({List<String>? script})
      : _script = script ??
            const ['There is an AI meetup tomorrow. Would you like to attend?'];
  final List<String> _script;
  int _i = 0;
  final List<String> spoken = [];

  @override
  Future<String?> listenOnce() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (_script.isEmpty) return null;
    return _script[_i++ % _script.length];
  }

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async {}
}

class FakeSimplifier implements SimplifierPort {
  static const _filler = {
    'there', 'is', 'a', 'an', 'the', 'would', 'you', 'like', 'to', 'do',
    'please', 'could', 'we', 'and', 'of', 'for', 'that', 'this',
  };

  @override
  Future<String> simplify(String spoken) async {
    final question = spoken.contains('?');
    final words = spoken
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && !_filler.contains(w.toLowerCase()))
        .take(4)
        .map((w) => w.toUpperCase())
        .toList();
    if (words.isEmpty) return spoken.toUpperCase();
    final head = words.take(words.length > 2 ? 2 : words.length).join(' ');
    final tail = words.skip(words.length > 2 ? 2 : words.length).join(' ');
    final b = StringBuffer('$head.');
    if (tail.isNotEmpty) b.write('\n$tail${question ? '?' : '.'}');
    return b.toString();
  }
}

class FakeLauncher implements LauncherPort {
  static const _apps = [
    LaunchableApp('WhatsApp', 'com.whatsapp'),
    LaunchableApp('Messages', 'com.google.android.apps.messaging'),
    LaunchableApp('Phone', 'com.android.dialer'),
    LaunchableApp('Chrome', 'com.android.chrome'),
    LaunchableApp('Settings', 'com.android.settings'),
  ];
  final List<String> launched = [];

  @override
  Future<List<LaunchableApp>> installedApps() async => _apps;

  @override
  Resolution resolve(String phrase, List<LaunchableApp> apps) {
    final q = phrase.toLowerCase().trim();
    if (q.isEmpty) return Resolution.none;
    final exact = apps.where((a) => a.name.toLowerCase() == q).toList();
    if (exact.isNotEmpty) {
      return Resolution(exact, needsConfirmation: false);
    }
    final partial = apps
        .where((a) =>
            a.name.toLowerCase().startsWith(q) || a.name.toLowerCase().contains(q))
        .toList();
    return Resolution(partial, needsConfirmation: partial.isNotEmpty);
  }

  @override
  Future<void> launch(String package) async => launched.add(package);
}
