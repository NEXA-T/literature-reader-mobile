import 'analysis_result.dart';

/// Сохранённый AI-разбор фразы (история разобранных цитат, задача #15).
class SavedAnalysis {
  const SavedAnalysis({
    required this.bookId,
    required this.bookTitle,
    required this.chapterIndex,
    required this.selectedText,
    required this.context,
    required this.result,
    required this.savedAt,
  });

  final String bookId;
  final String bookTitle;
  final int chapterIndex;

  /// Исходная фраза
  final String selectedText;

  /// Абзац, из которого её выделили
  final String context;

  /// Перевод, толкование, этимология и образ для иллюстрации (image_prompt)
  final AnalysisResult result;

  final DateTime savedAt;

  /// По этому ключу ищем разбор повторно: та же книга, та же глава,
  /// та же фраза (без учёта регистра, лишних пробелов и знаков по краям).
  String get key => makeKey(bookId, chapterIndex, selectedText);

  static String makeKey(String bookId, int chapterIndex, String text) =>
      '$bookId|$chapterIndex|${normalizePhrase(text)}';

  static String normalizePhrase(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[“”«»„"]'), '"')
      .replaceAll(RegExp(r'[‘’]'), "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'''^[\s"'.,;:!?()—–-]+|[\s"'.,;:!?()—–-]+$'''), '');

  Map<String, dynamic> toJson() => {
    'bookId': bookId,
    'bookTitle': bookTitle,
    'chapterIndex': chapterIndex,
    'selectedText': selectedText,
    'context': context,
    'result': result.toJson(),
    'savedAt': savedAt.toIso8601String(),
  };

  factory SavedAnalysis.fromJson(Map<String, dynamic> json) => SavedAnalysis(
    bookId: json['bookId'] as String,
    bookTitle: json['bookTitle'] as String,
    chapterIndex: json['chapterIndex'] as int,
    selectedText: json['selectedText'] as String,
    context: json['context'] as String,
    result: AnalysisResult.fromJson(json['result'] as Map<String, dynamic>),
    savedAt: DateTime.parse(json['savedAt'] as String),
  );
}
