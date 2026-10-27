import 'package:flutter_test/flutter_test.dart';
import 'package:literature_reader/models/analysis_result.dart';
import 'package:literature_reader/models/reading_progress.dart';
import 'package:literature_reader/models/saved_analysis.dart';
import 'package:literature_reader/services/analysis_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

SavedAnalysis _entry(String text, {int chapter = 0, String book = 'b1'}) =>
    SavedAnalysis(
      bookId: book,
      bookTitle: 'Alice',
      chapterIndex: chapter,
      selectedText: text,
      context: 'Some paragraph with $text inside.',
      result: const AnalysisResult(
        translation: 'перевод',
        contextMeaning: 'смысл',
        imagePrompt: 'a girl',
      ),
      savedAt: DateTime(2026, 10, 22),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('фраза нормализуется: регистр, пробелы, знаки по краям', () {
    expect(
      SavedAnalysis.normalizePhrase('  «Dead   as a Door-Nail.» '),
      'dead as a door-nail',
    );
  });

  test('сохранённый разбор находится по той же фразе в той же главе', () async {
    final cache = AnalysisCacheService();
    await cache.save(_entry('Dead as a door-nail'));

    final found = await cache.find(
      bookId: 'b1',
      chapterIndex: 0,
      selectedText: 'dead as a door-nail.',
    );
    expect(found, isNotNull);
    expect(found!.result.translation, 'перевод');
    expect(found.result.imagePrompt, 'a girl');
  });

  test('другая глава или книга — разбора нет', () async {
    final cache = AnalysisCacheService();
    await cache.save(_entry('phrase'));

    expect(
      await cache.find(bookId: 'b1', chapterIndex: 1, selectedText: 'phrase'),
      isNull,
    );
    expect(
      await cache.find(bookId: 'b2', chapterIndex: 0, selectedText: 'phrase'),
      isNull,
    );
  });

  test('повторное сохранение не дублирует запись', () async {
    final cache = AnalysisCacheService();
    await cache.save(_entry('phrase'));
    await cache.save(_entry('Phrase'));
    expect((await cache.loadAll()).length, 1);
  });

  test('прогресс: старые записи без номера страницы читаются', () {
    final p = ReadingProgress.fromJson({
      'chapterIndex': 2,
      'paragraphIndex': 5,
      'charOffset': 10,
      'percent': 0.4,
      'updatedAt': '2026-10-22T10:00:00.000',
    });
    expect(p.currentPage, 0);
    expect(p.locator, '2:5:10');
  });
}
