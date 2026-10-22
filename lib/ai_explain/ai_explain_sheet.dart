import 'package:flutter/material.dart';

import '../services/ai_api_client.dart';
import '../widgets/analysis_sheet.dart';
import 'ai_explain_request.dart';

/// Запросы к бэкенду (POST /api/v1/explain). Для демо без сервера можно
/// временно вернуть MockAnalysisService() — у него тот же метод analyze.
final _analysisService = AiApiClient();

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
    fetch: () => _analysisService.analyze(
      selectedText: request.selectedText,
      context: request.context,
      bookTitle: request.bookTitle,
    ),
  );
}
