/// Thin ports the home surface talks to.
///
/// The three lanes (tactile / voice / launcher+ai) build the real
/// implementations in their own folders. The home surface depends only on these
/// narrow interfaces, so integration is one adapter file rather than a rewrite,
/// and the demo runs today against [FakePorts] with no device and no network.
library;

/// One Braille cell: six dots, numbered 1-6 (D-008 / D-009).
class Cell {
  const Cell(this.dots, {this.char = '?'});
  final List<bool> dots; // length 6, index 0 == dot 1
  final String char;

  static const blank = Cell([false, false, false, false, false, false], char: ' ');
}

abstract class BraillePort {
  List<Cell> encode(String text);
}

abstract class HapticPort {
  /// Renders cells dot-by-dot. Completes when the whole run has played.
  Future<void> render(List<Cell> cells);
  Future<void> cancel();
}

abstract class VoicePort {
  Future<String?> listenOnce();
  Future<void> speak(String text);
  Future<void> stop();
}

abstract class SimplifierPort {
  Future<String> simplify(String spoken);
}

class LaunchableApp {
  const LaunchableApp(this.name, this.package);
  final String name;
  final String package;
}

/// Result of matching a spoken phrase against installed apps.
///
/// [needsConfirmation] is the safety-critical bit: a blind-deaf user cannot see
/// that the wrong app opened, so anything less than a certain match must be
/// confirmed rather than launched.
class Resolution {
  const Resolution(this.candidates, {required this.needsConfirmation});
  final List<LaunchableApp> candidates;
  final bool needsConfirmation;

  static const none = Resolution([], needsConfirmation: false);
  bool get isEmpty => candidates.isEmpty;
}

abstract class LauncherPort {
  Future<List<LaunchableApp>> installedApps();
  Resolution resolve(String phrase, List<LaunchableApp> apps);
  Future<void> launch(String package);
}
