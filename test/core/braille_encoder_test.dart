import 'package:flutter_test/flutter_test.dart';
import 'package:gusa/core/braille/braille_encoder.dart';

void main() {
  const encoder = BrailleEncoder();

  group('BrailleEncoder — letters', () {
    test('encodes a lowercase word with no signal cells', () {
      final cells = encoder.encode('cab');

      expect(cells.length, 3);
      expect(cells[0], BrailleCell.fromDots([1, 4], 'c'));
      expect(cells[1], BrailleCell.fromDots([1], 'a'));
      expect(cells[2], BrailleCell.fromDots([1, 2], 'b'));
      expect(cells.any((c) => c.isUnknown), isFalse);
    });

    test('capitalised letters emit a capital sign before each one', () {
      final cells = encoder.encode('Cab');

      // Capital sign (dot 6) precedes the capitalised C.
      expect(cells[0], const BrailleCell.capitalSign());
      expect(cells[1], BrailleCell.fromDots([1, 4], 'C'));
      // Lowercase letters that follow are not preceded by a capital sign.
      expect(cells[2], BrailleCell.fromDots([1], 'a'));
      expect(cells[3], BrailleCell.fromDots([1, 2], 'b'));
    });

    test('a fully capitalised word gets a capital sign per letter', () {
      final cells = encoder.encode('AB');

      expect(cells, [
        const BrailleCell.capitalSign(),
        BrailleCell.fromDots([1], 'A'),
        const BrailleCell.capitalSign(),
        BrailleCell.fromDots([1, 2], 'B'),
      ]);
    });
  });

  group('BrailleEncoder — numbers', () {
    test('a run of digits emits the number sign exactly once', () {
      final cells = encoder.encode('123');

      expect(cells.length, 4); // 1 number sign + 3 digit cells.
      expect(cells[0], const BrailleCell.numberSign());
      expect(cells[1], BrailleCell.fromDots([1], '1')); // reuses 'a'.
      expect(cells[2], BrailleCell.fromDots([1, 2], '2')); // reuses 'b'.
      expect(cells[3], BrailleCell.fromDots([1, 4], '3')); // reuses 'c'.

      // Only one number-sign cell for the whole run.
      expect(cells.where((c) => c == const BrailleCell.numberSign()).length, 1);
    });

    test('a new number sign is emitted after the run is broken by a letter', () {
      final cells = encoder.encode('1a2');

      expect(
        cells.where((c) => c == const BrailleCell.numberSign()).length,
        2,
      );
    });

    test('0 reuses the letter j pattern', () {
      final cells = encoder.encode('0');

      expect(cells[0], const BrailleCell.numberSign());
      expect(cells[1], BrailleCell.fromDots([2, 4, 5], '0'));
    });
  });

  group('BrailleEncoder — punctuation and spaces', () {
    test('encodes supported punctuation', () {
      final cells = encoder.encode(".,?!'-");

      expect(cells, [
        BrailleCell.fromDots([2, 5, 6], '.'),
        BrailleCell.fromDots([2], ','),
        BrailleCell.fromDots([2, 3, 6], '?'),
        BrailleCell.fromDots([2, 3, 5], '!'),
        BrailleCell.fromDots([3], "'"),
        BrailleCell.fromDots([3, 6], '-'),
      ]);
    });

    test('a space becomes a dedicated blank space cell', () {
      final cells = encoder.encode('a b');

      expect(cells.length, 3);
      expect(cells[1].isSpace, isTrue);
      expect(cells[1].dots, [false, false, false, false, false, false]);
    });
  });

  group('BrailleEncoder — unknown characters', () {
    test('an unknown character does not throw and encoding continues', () {
      expect(() => encoder.encode('a@b'), returnsNormally);

      final cells = encoder.encode('a@b');
      expect(cells.length, 3);
      expect(cells[0], BrailleCell.fromDots([1], 'a'));
      expect(cells[1].isUnknown, isTrue);
      expect(cells[1].char, '@');
      expect(cells[1].dots, [false, false, false, false, false, false]);
      expect(cells[2], BrailleCell.fromDots([1, 2], 'b'));
    });

    test('an empty string encodes to an empty list', () {
      expect(encoder.encode(''), isEmpty);
    });
  });
}
