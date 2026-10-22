import 'package:flutter/material.dart';

import '../models/analysis_result.dart';
import '../models/saved_analysis.dart';
import '../services/ai_api_client.dart';
import '../services/analysis_cache_service.dart';
import '../widgets/analysis_sheet.dart';
import 'ai_explain_request.dart';

/// Запросы к бэкенду (POST /api/v1/explain). Для демо без сервера можно
/// временно вернуть MockAnalysisService() — у него тот же метод analyze.
final _analysisService = AiApiClient();

/// История разобранных фраз на устройстве (#15)
final _cache = AnalysisCacheService();

/// Точка входа в шторку «Объяснить с AI».
///
/// Экран чтения вызывает только эту функцию, а саму шторку
/// (загрузка → результат / ошибка → «Повторить») рисует
/// переиспользуемый виджет из lib/widgets/analysis_sheet.dart.
/// «Повторить» снова вызывает fetch, то есть отправляет запрос заново.
Future<void> showAiExplainSheet(
  BuildContext context,
  AiExplainRequest request,
) {
  return showAnalysisSheet(
    context,
    fragment: request.selectedText,
    fetch: () => _fetchWithCache(request),
  );
}

/// Сначала ищем готовый разбор на устройстве (работает и без интернета),
/// и только если его нет — идём на бэкенд и сохраняем ответ.
Future<AnalysisResult> _fetchWithCache(AiExplainRequest request) async {
  try {
    final saved = await _cache.find(
      bookId: request.bookId,
      chapterIndex: request.chapterIndex,
      selectedText: request.selectedText,
    );
    if (saved != null) {
      debugPrint('[AI cache] разбор взят из памяти: «${request.selectedText}»');
      return saved.result;
    }
  } catch (e) {
    debugPrint('[AI cache] не удалось прочитать историю: $e');
  }

  final result = await _analysisService.analyze(
    selectedText: request.selectedText,
    context: request.context,
    bookTitle: request.bookTitle,
  );

  try {
    await _cache.save(
      SavedAnalysis(
        bookId: request.bookId,
        bookTitle: request.bookTitle,
        chapterIndex: request.chapterIndex,
        selectedText: request.selectedText,
        context: request.context,
        result: result,
        savedAt: DateTime.now(),
      ),
    );
    debugPrint('[AI cache] разбор сохранён: «${request.selectedText}»');
  } catch (e) {
    // Не смогли сохранить — не страшно, разбор всё равно показываем
    debugPrint('[AI cache] не удалось сохранить разбор: $e');
  }
  return result;
}

/// Загрузка иллюстрации по image_prompt — для блока картинки в шторке (#14).
/// Вероника передаст её в виджет иллюстрации; шторка вызывает её уже после
/// показа текста, поэтому текст разбора не ждёт тяжёлую картинку.
Future<ImageProvider> loadIllustration(String imagePrompt) =>
    _analysisService.generateImage(imagePrompt);
