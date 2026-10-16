/// Данные, которые экран чтения передаёт в шторку «Объяснить с AI» (US-03, AC 3.3).
class AiExplainRequest {
  const AiExplainRequest({
    required this.selectedText,
    required this.context,
    required this.bookTitle,
  });

  /// Выделенная фраза
  final String selectedText;

  /// Абзац, в котором сделано выделение (целиком, даже если он разрезан
  /// между страницами)
  final String context;

  final String bookTitle;

  /// Тело запроса к бэкенду
  Map<String, dynamic> toJson() => {
    'selected_text': selectedText,
    'context': context,
    'book_title': bookTitle,
  };
}
