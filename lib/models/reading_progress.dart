/// Позиция чтения (задача #15).
///
/// Главное — место в тексте (глава, абзац, символ): номера страниц
/// меняются при повороте экрана или смене размера шрифта, а место
/// в тексте — нет. По нему книга и открывается.
/// [currentPage] и [totalPages] сохраняются для процента и отображения.
class ReadingProgress {
  const ReadingProgress({
    required this.chapterIndex,
    required this.paragraphIndex,
    required this.charOffset,
    required this.percent,
    required this.updatedAt,
    this.currentPage = 0,
    this.totalPages = 0,
  });

  final int chapterIndex;
  final int paragraphIndex;
  final int charOffset;

  /// Номер страницы (с 1) и всего страниц на момент сохранения
  final int currentPage;
  final int totalPages;

  /// От 0 до 1: currentPage / totalPages. Для карточки в библиотеке
  final double percent;

  /// Когда читали в последний раз (last_read_timestamp)
  final DateTime updatedAt;

  /// Локатор позиции в тексте — аналог CFI: «глава:абзац:символ»
  String get locator => '$chapterIndex:$paragraphIndex:$charOffset';

  Map<String, dynamic> toJson() => {
    'chapterIndex': chapterIndex,
    'paragraphIndex': paragraphIndex,
    'charOffset': charOffset,
    'currentPage': currentPage,
    'totalPages': totalPages,
    'percent': percent,
    'locator': locator,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ReadingProgress.fromJson(Map<String, dynamic> json) =>
      ReadingProgress(
        chapterIndex: json['chapterIndex'] as int,
        paragraphIndex: json['paragraphIndex'] as int,
        charOffset: json['charOffset'] as int,
        // В старых записях этих полей нет
        currentPage: (json['currentPage'] as int?) ?? 0,
        totalPages: (json['totalPages'] as int?) ?? 0,
        percent: (json['percent'] as num).toDouble(),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
