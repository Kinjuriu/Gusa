import 'package:flutter_test/flutter_test.dart';
import 'package:gusa/services/ai/rule_based_simplifier.dart';

void main() {
  const simplifier = RuleBasedSimplifier();

  test('long sentence is shortened into short lines', () async {
    const input =
        'Your booking scheduled for Wednesday afternoon has unfortunately '
        'been rescheduled to a different time slot next week';

    final result = await simplifier.simplify(input);

    expect(result, isNotEmpty);
    expect(result.length, lessThan(input.length));

    final lines = result.split('\n');
    for (final line in lines) {
      expect(line.length, lessThanOrEqualTo(simplifier.maxLineLength));
    }
  });

  test('a spec-style question is shortened and keeps the question mark',
      () async {
    const input = 'Would you like to attend the event tomorrow?';

    final result = await simplifier.simplify(input);

    expect(result, isNotEmpty);
    expect(result, endsWith('?'));
    expect(result, equals(result.toUpperCase()));
  });

  test('already-short input survives without being mangled', () async {
    final result = await simplifier.simplify('Yes');

    expect(result, isNotEmpty);
    expect(result.toUpperCase(), contains('YES'));
  });

  test('empty input does not throw and returns empty output', () async {
    final result = await simplifier.simplify('');
    expect(result, isEmpty);
  });

  test('whitespace-only input does not throw and returns empty output',
      () async {
    final result = await simplifier.simplify('   ');
    expect(result, isEmpty);
  });

  test('output is uppercase', () async {
    final result = await simplifier.simplify('please call me back later');
    expect(result, equals(result.toUpperCase()));
  });
}
