import 'package:flutter_test/flutter_test.dart';
import 'package:literature_reader/ai_explain/selection_validation.dart';

void main() {
  group('checkSelection', () {
    test('пустое выделение и одни пробелы', () {
      expect(checkSelection(''), SelectionCheck.empty);
      expect(checkSelection('   \n '), SelectionCheck.empty);
    });

    test('обычная фраза', () {
      expect(checkSelection('dead as a door-nail'), SelectionCheck.ok);
    });

    test('ровно 200 символов можно, 201 — нельзя', () {
      expect(checkSelection('a' * 200), SelectionCheck.ok);
      expect(checkSelection('a' * 201), SelectionCheck.tooLong);
    });

    test('пробелы по краям не считаются', () {
      expect(checkSelection('  ${'a' * 200}  '), SelectionCheck.ok);
    });
  });

  group('trimContext', () {
    test('короткий абзац не меняется', () {
      expect(trimContext('Short paragraph.', 'Short'), 'Short paragraph.');
    });

    test('длинный абзац обрезается до 1000 символов вокруг фразы', () {
      final paragraph = '${'x' * 1500} PHRASE ${'y' * 1500}';
      final result = trimContext(paragraph, 'PHRASE');
      expect(result.length, lessThanOrEqualTo(1000));
      expect(result, contains('PHRASE'));
    });

    test('фраза в самом начале абзаца', () {
      final paragraph = 'PHRASE ${'y' * 2000}';
      final result = trimContext(paragraph, 'PHRASE');
      expect(result.startsWith('PHRASE'), isTrue);
      expect(result.length, lessThanOrEqualTo(1000));
    });
  });
}
