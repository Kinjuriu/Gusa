import 'launcher_app.dart';

/// How confident [AppResolver] is that a given [AppMatch] is what the user
/// meant.
enum AppMatchConfidence {
  /// Phrase and app name are identical once normalized (case/punctuation
  /// insensitive). Safe to act on without asking the user to confirm.
  exact,

  /// Phrase is a prefix of the app name, or the app name is a prefix of the
  /// phrase (e.g. "whats" -> "WhatsApp").
  high,

  /// The app name contains the phrase as a substring, but not as a prefix.
  medium,

  /// Every word in the phrase appears (as a substring) somewhere in the app
  /// name, but not contiguously.
  low,
}

/// A single candidate app for a spoken/typed phrase, ranked by [score].
class AppMatch {
  const AppMatch({
    required this.app,
    required this.confidence,
    required this.score,
  });

  final LauncherApp app;
  final AppMatchConfidence confidence;

  /// 0.0-1.0 ranking score. Higher is a better match. Used only for sorting
  /// and for detecting near-ties (ambiguity); callers should key launch
  /// decisions off [confidence], not raw score.
  final double score;

  @override
  String toString() =>
      'AppMatch(${app.name}, $confidence, ${score.toStringAsFixed(2)})';
}

/// Result of resolving a spoken/typed phrase against the installed-app list.
///
/// Deliberately exposes a ranked list rather than a single guess: a
/// blind/deafblind user cannot see that the wrong app opened, so any
/// ambiguity must be surfaced to the caller instead of silently resolved.
class AppResolution {
  const AppResolution({required this.query, required this.matches});

  /// The original, un-normalized phrase that was resolved.
  final String query;

  /// Candidate apps, best match first. Empty when nothing matched at all.
  final List<AppMatch> matches;

  bool get hasMatch => matches.isNotEmpty;

  /// The top-ranked candidate, or `null` if there were no matches.
  AppMatch? get bestMatch => matches.isNotEmpty ? matches.first : null;

  /// Whether the caller should ask the user to confirm before launching,
  /// rather than launching automatically.
  ///
  /// Only a single, exact, unambiguous match is safe to auto-launch. Any of
  /// the following requires confirmation:
  /// - no match at all (nothing to confirm, but nothing to launch either),
  /// - more than one candidate (genuinely ambiguous),
  /// - a single candidate that is not an exact match (a guess).
  bool get requiresConfirmation {
    if (matches.isEmpty) return false;
    if (matches.length == 1 && matches.first.confidence == AppMatchConfidence.exact) {
      return false;
    }
    return true;
  }
}

/// Pure logic (no plugins, no I/O) that maps a spoken/typed phrase like
/// "open whats" to the best-matching installed app(s).
class AppResolver {
  const AppResolver();

  static const List<String> _leadingCommandWords = [
    'open ',
    'launch ',
    'start ',
    'go to ',
    'activate ',
  ];

  /// Resolves [phrase] against [apps], returning a ranked [AppResolution].
  AppResolution resolve(String phrase, List<LauncherApp> apps) {
    final normalizedPhrase = _normalize(phrase);
    if (normalizedPhrase.isEmpty || apps.isEmpty) {
      return AppResolution(query: phrase, matches: const []);
    }

    final matches = <AppMatch>[];
    for (final app in apps) {
      final match = _scoreApp(normalizedPhrase, app);
      if (match != null) matches.add(match);
    }

    matches.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.app.name.toLowerCase().compareTo(b.app.name.toLowerCase());
    });

    return AppResolution(query: phrase, matches: matches);
  }

  AppMatch? _scoreApp(String normalizedPhrase, LauncherApp app) {
    final name = _normalize(app.name);
    if (name.isEmpty) return null;

    if (normalizedPhrase == name) {
      return AppMatch(
        app: app,
        confidence: AppMatchConfidence.exact,
        score: 1.0,
      );
    }

    if (name.startsWith(normalizedPhrase) || normalizedPhrase.startsWith(name)) {
      final shorter = normalizedPhrase.length < name.length
          ? normalizedPhrase.length
          : name.length;
      final longer = normalizedPhrase.length > name.length
          ? normalizedPhrase.length
          : name.length;
      final ratio = shorter / longer;
      return AppMatch(
        app: app,
        confidence: AppMatchConfidence.high,
        score: 0.6 + 0.3 * ratio,
      );
    }

    if (name.contains(normalizedPhrase)) {
      final ratio = normalizedPhrase.length / name.length;
      return AppMatch(
        app: app,
        confidence: AppMatchConfidence.medium,
        score: 0.3 + 0.2 * ratio,
      );
    }

    if (_allWordsFound(normalizedPhrase, name)) {
      return AppMatch(
        app: app,
        confidence: AppMatchConfidence.low,
        score: 0.15,
      );
    }

    return null;
  }

  bool _allWordsFound(String phrase, String name) {
    final phraseWords =
        phrase.split(' ').where((w) => w.isNotEmpty).toList();
    if (phraseWords.isEmpty) return false;
    return phraseWords.every((w) => name.contains(w));
  }

  String _normalize(String input) {
    var normalized = input.toLowerCase().trim();
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9\s]'), '');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    for (final prefix in _leadingCommandWords) {
      if (normalized.startsWith(prefix)) {
        normalized = normalized.substring(prefix.length).trim();
        break;
      }
    }
    return normalized;
  }
}
