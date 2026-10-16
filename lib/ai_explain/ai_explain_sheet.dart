import 'package:flutter/material.dart';

import '../services/mock_analysis_service.dart';
import '../widgets/analysis_sheet.dart';
import 'ai_explain_request.dart';

/// Пока бэкенд не готов, ответы отдаёт заглушка. Когда появится
/// настоящий API-клиент, заменить нужно только эту строку.
final _analysisService = MockAnalysisService();

/// Точка входа в шторку «Объяснить с AI».
///
/// Экран чтения вызывает только эту функцию, а саму шторку
/// (загрузка → результат / ошибка → «Повторить») рисует
/// переиспользуемый виджет из lib/widgets/analysis_sheet.dart.
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