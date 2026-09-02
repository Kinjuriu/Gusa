import 'message_simplifier.dart';

/// No-network fallback simplifier.
///
/// This is what the demo runs on when there is no AI key configured, or
/// when [HttpMessageSimplifier] fails/times out, so it has to produce a
/// genuinely usable short form on its own: strip filler words and
/// politeness padding, cap length, split into short lines, and uppercase
/// (matching the tactile style used elsewhere in the app, e.g.
/// `EVENT TOMORROW.\nATTEND?`).
///
/// It cannot fully paraphrase/reorder a sentence the way an LLM can — it is
/// a safety-net fallback, not a replacement for [HttpMessageSimplifier].
class RuleBasedSimplifier implements MessageSimplifier {
  const RuleBasedSimplifier({this.maxWords = 6, this.maxLineLength = 20});

  final int maxWords;
  final int maxLineLength;

  static const List<String> _leadingFillers = [
    'would you like to ',
    'do you want to ',
    'would you mind ',
    'can you please ',
    'could you please ',
    'can you ',
    'could you ',
    'please note that ',
    'i just wanted to let you know that ',
    'i wanted to let you know that ',
    'just so you know, ',
    'just so you know ',
    'i am writing to let you know that ',
    'please ',
  ];

  static const Set<String> _fillerWords = {
    'um',
    'uh',
    'like',
    'basically',
    'actually',
    'literally',
    'just',
    'know',
    'sort',
    'kind',
    'really',
    'very',
    'so',
    'well',
    'the',
    'a',
    'an',
    'is',
    'are',
    'to',
    'that',
    'this',
    'and',
    'but',
    'has',
    'have',
    'been',
    'of',
    'unfortunately',
  };

  @override
  Future<String> simplify(String spokenText) async {
    final trimmed = spokenText.trim();
    if (trimmed.isEmpty) return '';

    final isQuestion = trimmed.endsWith('?');

    var working = trimmed.toLowerCase();
    for (final filler in _leadingFillers) {
      if (working.startsWith(filler)) {
        working = working.substring(filler.length).trim();
        break;
      }
    }

    // Drop trailing punctuation; it is re-added after casing/wrapping.
    working = working.replaceAll(RegExp(r'[?.!,;:]+$'), '').trim();

    final rawWords =
        working.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    var words = rawWords.where((w) => !_fillerWords.contains(w)).toList();

    // If stripping fillers ate everything (e.g. the whole phrase was
    // filler), fall back to the un-filtered words rather than returning
    // nothing.
    if (words.isEmpty) words = rawWords;
    if (words.isEmpty) return '';

    if (words.length > maxWords) {
      words = words.sublist(0, maxWords);
    }

    var core = words.join(' ').toUpperCase();
    core = isQuestion ? '$core?' : '$core.';

    return _wrapLines(core);
  }

  String _wrapLines(String text) {
    final words = text.split(' ').where((w) => w.isNotEmpty).toList();
    final lines = <String>[];
    final current = StringBuffer();

    for (final word in words) {
      if (current.isEmpty) {
        current.write(word);
      } else if (current.length + 1 + word.length <= maxLineLength) {
        current.write(' ');
        current.write(word);
      } else {
        lines.add(current.toString());
        current
          ..clear()
          ..write(word);
      }
    }
    if (current.isNotEmpty) lines.add(current.toString());

    return lines.join('\n');
  }
}
