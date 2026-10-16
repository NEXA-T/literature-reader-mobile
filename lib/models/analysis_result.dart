/// Ответ бэкенда на разбор фрагмента (US-04, AC 4.2–4.4).
/// Имена JSON-полей совпадают с API-контрактом.
class AnalysisResult {
  const AnalysisResult({
    required this.translation,
    required this.contextMeaning,
    this.slangOrEtymology,
    this.imagePrompt,
  });

  /// Контекстный перевод.
  final String translation;

  /// Скрытый смысл / метафора в контексте произведения.
  final String contextMeaning;

  /// Этимология или сленг. `null` — блок в шторке скрывается (AC 4.3).
  final String? slangOrEtymology;

  /// Промпт для будущей иллюстрации сцены (AC 4.4).
  final String? imagePrompt;

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    String? clean(Object? v) {
      final s = (v as String?)?.trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    return AnalysisResult(
      translation: clean(json['translation']) ?? '',
      contextMeaning: clean(json['context_meaning']) ?? '',
      slangOrEtymology: clean(json['slang_or_etymology']),
      imagePrompt: clean(json['image_prompt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'translation': translation,
        'context_meaning': contextMeaning,
        'slang_or_etymology': slangOrEtymology,
        'image_prompt': imagePrompt,
      };
}

/// Почему не удалось получить разбор — от этого зависит текст ошибки.
enum AnalysisFailureKind {
  /// Нет интернета (AC 3.5).
  offline,

  /// Сбой бэкенда или таймаут нейросети (AC 4.5).
  server,
}

class AnalysisException implements Exception {
  const AnalysisException(this.kind);

  final AnalysisFailureKind kind;

  @override
  String toString() => 'AnalysisException($kind)';
}
