// UEB Grade 1 (uncontracted) English Braille encoder.
//
// D-008: English Grade 1 UEB uncontracted. Capital sign and number sign
// supported. No LLM / no contractions — deterministic table lookups only.
//
// Deliberately free of Flutter imports (plain Dart) so this file unit-tests
// fast, without pulling in the Flutter test harness.

/// A single six-dot Braille cell.
///
/// Dots are numbered in the standard Braille layout:
/// ```
/// 1  4
/// 2  5
/// 3  6
/// ```
class BrailleCell {
  const BrailleCell({
    required this.dot1,
    required this.dot2,
    required this.dot3,
    required this.dot4,
    required this.dot5,
    required this.dot6,
    required this.char,
    this.isSpace = false,
    this.isUnknown = false,
  });

  /// Blank cell representing a word boundary (a space in the source text).
  const BrailleCell.space()
    : dot1 = false,
      dot2 = false,
      dot3 = false,
      dot4 = false,
      dot5 = false,
      dot6 = false,
      char = ' ',
      isSpace = true,
      isUnknown = false;

  /// Explicit "unknown character" cell. Blank dots so it never crashes
  /// downstream renderers, but flagged via [isUnknown] so callers can show
  /// or log it distinctly.
  const BrailleCell.unknown(String sourceChar)
    : dot1 = false,
      dot2 = false,
      dot3 = false,
      dot4 = false,
      dot5 = false,
      dot6 = false,
      char = sourceChar,
      isSpace = false,
      isUnknown = true;

  /// Capital sign (dot 6). Precedes a capitalised letter.
  const BrailleCell.capitalSign()
    : dot1 = false,
      dot2 = false,
      dot3 = false,
      dot4 = false,
      dot5 = false,
      dot6 = true,
      char = '^',
      isSpace = false,
      isUnknown = false;

  /// Number sign (dots 3-4-5-6). Precedes a run of digits, once per run.
  const BrailleCell.numberSign()
    : dot1 = false,
      dot2 = false,
      dot3 = true,
      dot4 = true,
      dot5 = true,
      dot6 = true,
      char = '#',
      isSpace = false,
      isUnknown = false;

  /// Builds a cell from the set of dot numbers (1-6) that are raised.
  factory BrailleCell.fromDots(List<int> raisedDots, String char) {
    return BrailleCell(
      dot1: raisedDots.contains(1),
      dot2: raisedDots.contains(2),
      dot3: raisedDots.contains(3),
      dot4: raisedDots.contains(4),
      dot5: raisedDots.contains(5),
      dot6: raisedDots.contains(6),
      char: char,
    );
  }

  final bool dot1;
  final bool dot2;
  final bool dot3;
  final bool dot4;
  final bool dot5;
  final bool dot6;

  /// The source character this cell represents (debugging / UI display
  /// only). Signal cells use a marker character ('^' capital, '#' number).
  final String char;

  /// True for the blank cell inserted at a word boundary (space).
  final bool isSpace;

  /// True when [char] could not be mapped to a known Braille pattern.
  final bool isUnknown;

  /// Dots 1..6 in reading order — this is what the haptic engine renders.
  List<bool> get dots => <bool>[dot1, dot2, dot3, dot4, dot5, dot6];

  @override
  String toString() {
    final raised = <int>[
      if (dot1) 1,
      if (dot2) 2,
      if (dot3) 3,
      if (dot4) 4,
      if (dot5) 5,
      if (dot6) 6,
    ];
    return 'BrailleCell(char: "$char", dots: $raised'
        '${isSpace ? ', space' : ''}${isUnknown ? ', unknown' : ''})';
  }

  @override
  bool operator ==(Object other) {
    return other is BrailleCell &&
        other.dot1 == dot1 &&
        other.dot2 == dot2 &&
        other.dot3 == dot3 &&
        other.dot4 == dot4 &&
        other.dot5 == dot5 &&
        other.dot6 == dot6 &&
        other.char == char &&
        other.isSpace == isSpace &&
        other.isUnknown == isUnknown;
  }

  @override
  int get hashCode => Object.hash(
    dot1,
    dot2,
    dot3,
    dot4,
    dot5,
    dot6,
    char,
    isSpace,
    isUnknown,
  );
}

/// Deterministic UEB Grade 1 (uncontracted) text -> Braille cell encoder.
///
/// No LLM involved by design (see SPEC.md §7).
class BrailleEncoder {
  const BrailleEncoder();

  /// a-z dot patterns. Digits 1-9 and 0 reuse the a-j patterns (see
  /// [_digitDots]) preceded by a single number sign per digit run.
  static const Map<String, List<int>> _letterDots = <String, List<int>>{
    'a': [1],
    'b': [1, 2],
    'c': [1, 4],
    'd': [1, 4, 5],
    'e': [1, 5],
    'f': [1, 2, 4],
    'g': [1, 2, 4, 5],
    'h': [1, 2, 5],
    'i': [2, 4],
    'j': [2, 4, 5],
    'k': [1, 3],
    'l': [1, 2, 3],
    'm': [1, 3, 4],
    'n': [1, 3, 4, 5],
    'o': [1, 3, 5],
    'p': [1, 2, 3, 4],
    'q': [1, 2, 3, 4, 5],
    'r': [1, 2, 3, 5],
    's': [2, 3, 4],
    't': [2, 3, 4, 5],
    'u': [1, 3, 6],
    'v': [1, 2, 3, 6],
    'w': [2, 4, 5, 6],
    'x': [1, 3, 4, 6],
    'y': [1, 3, 4, 5, 6],
    'z': [1, 3, 5, 6],
  };

  /// Digit -> letter it borrows its pattern from (1=a, 2=b, ... 9=i, 0=j).
  static const Map<String, String> _digitToLetter = <String, String>{
    '1': 'a',
    '2': 'b',
    '3': 'c',
    '4': 'd',
    '5': 'e',
    '6': 'f',
    '7': 'g',
    '8': 'h',
    '9': 'i',
    '0': 'j',
  };

  /// Supported literary punctuation (SPEC.md §7 scope: . , ? ! ' -).
  static const Map<String, List<int>> _punctuationDots = <String, List<int>>{
    '.': [2, 5, 6],
    ',': [2],
    '?': [2, 3, 6],
    '!': [2, 3, 5],
    "'": [3],
    '-': [3, 6],
  };

  /// Encodes [text] into a flat list of [BrailleCell]s, in reading order.
  ///
  /// - Capital sign (dot 6) is emitted before every capitalised letter.
  /// - Number sign (dots 3-4-5-6) is emitted once before a run of digits,
  ///   not before each digit.
  /// - Unknown characters never throw; they become an explicit
  ///   [BrailleCell.unknown] cell so playback can keep going.
  List<BrailleCell> encode(String text) {
    final cells = <BrailleCell>[];
    var inNumberRun = false;

    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      final lower = ch.toLowerCase();

      // Whitespace is a word boundary, not a character. Newlines matter here:
      // the AI simplifier emits multi-line output ("EVENT TOMORROW.\nATTEND?"),
      // so treating \n as an unknown cell would put a meaningless pulse in the
      // middle of nearly every real message.
      if (ch == ' ' || ch == '\n' || ch == '\r' || ch == '\t') {
        inNumberRun = false;
        // Collapse a run of whitespace (e.g. "\r\n") into ONE word boundary.
        if (cells.isNotEmpty && cells.last.isSpace) continue;
        cells.add(const BrailleCell.space());
        continue;
      }

      if (_digitToLetter.containsKey(ch)) {
        if (!inNumberRun) {
          cells.add(const BrailleCell.numberSign());
          inNumberRun = true;
        }
        final letter = _digitToLetter[ch]!;
        cells.add(BrailleCell.fromDots(_letterDots[letter]!, ch));
        continue;
      }

      inNumberRun = false;

      if (_letterDots.containsKey(lower)) {
        final isCapital = ch != lower;
        if (isCapital) {
          cells.add(const BrailleCell.capitalSign());
        }
        cells.add(BrailleCell.fromDots(_letterDots[lower]!, ch));
        continue;
      }

      if (_punctuationDots.containsKey(ch)) {
        cells.add(BrailleCell.fromDots(_punctuationDots[ch]!, ch));
        continue;
      }

      // Unknown character: explicit cell, never throws, playback continues.
      cells.add(BrailleCell.unknown(ch));
    }

    return cells;
  }
}
