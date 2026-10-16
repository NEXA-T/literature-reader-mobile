/// Позиция чтения. Храним не номер страницы, а место в тексте
/// (глава, абзац, символ): номера страниц меняются при повороте экрана
/// или смене размера шрифта, а место в тексте — нет.
class ReadingProgress {
  const ReadingProgress({
    required this.chapterIndex,
    required this.paragraphIndex,
    required this.charOffset,
    required this.percent,
    required this.updatedAt,
  });

  final int chapterIndex;
  final int paragraphIndex;
  final int charOffset;

  /// От 0 до 1 — для индикатора на карточке в библиотеке
  final double percent;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'chapterIndex': chapterIndex,
    'paragraphIndex': paragraphIndex,
    'charOffset': charOffset,
    'percent': percent,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ReadingProgress.fromJson(Map<String, dynamic> json) =>
      ReadingProgress(
        chapterIndex: json['chapterIndex'] as int,
        paragraphIndex: json['paragraphIndex'] as int,
        charOffset: json['charOffset'] as int,
        percent: (json['percent'] as num).toDouble(),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
