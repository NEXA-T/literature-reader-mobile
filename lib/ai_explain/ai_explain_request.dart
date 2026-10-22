/// Данные, которые экран чтения передаёт в шторку «Объяснить с AI» (US-03, AC 3.3).
class AiExplainRequest {
  const AiExplainRequest({
    required this.selectedText,
    required this.context,
    required this.bookTitle,
    required this.bookId,
    required this.chapterIndex,
  });

  /// Выделенная фраза
  final String selectedText;

  /// Абзац, в котором сделано выделение (целиком, даже если он разрезан
  /// между страницами)
  final String context;

  final String bookTitle;

  /// Книга и глава — чтобы найти сохранённый разбор той же фразы (#15).
  /// На бэкенд не отправляются.
  final String bookId;
  final int chapterIndex;

  /// Тело запроса к бэкенду
  Map<String, dynamic> toJson() => {
    'selected_text': selectedText,
    'context': context,
    'book_title': bookTitle,
  };
}
