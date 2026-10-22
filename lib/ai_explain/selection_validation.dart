import '../config/api_config.dart';

/// Результат проверки выделения перед отправкой на анализ.
enum SelectionCheck {
  /// Можно отправлять.
  ok,

  /// Пустое выделение или одни пробелы — кнопку «Объяснить с AI» не показываем.
  empty,

  /// Длиннее [ApiConfig.maxSelectionLength] символов — запрос не отправляем.
  tooLong,
}

const selectionTooLongMessage =
    'Фрагмент слишком длинный (максимум 200 символов). '
    'Выделите отдельную фразу или идиому';

SelectionCheck checkSelection(String selected) {
  final text = selected.trim();
  if (text.isEmpty) return SelectionCheck.empty;
  if (text.length > ApiConfig.maxSelectionLength) return SelectionCheck.tooLong;
  return SelectionCheck.ok;
}

/// Обрезает абзац до [maxLength] символов так, чтобы выделенная фраза
/// оказалась примерно посередине окна. Короткий абзац возвращается как есть.
String trimContext(
  String paragraph,
  String selected, {
  int maxLength = ApiConfig.maxContextLength,
}) {
  final text = paragraph.trim();
  if (text.length <= maxLength) return text;

  final at = text.indexOf(selected.trim());
  if (at == -1) return text.substring(0, maxLength);

  final center = at + selected.trim().length ~/ 2;
  var start = center - maxLength ~/ 2;
  if (start < 0) start = 0;
  if (start + maxLength > text.length) start = text.length - maxLength;

  return text.substring(start, start + maxLength).trim();
}
