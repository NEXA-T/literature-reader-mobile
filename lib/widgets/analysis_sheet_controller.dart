import 'package:flutter/foundation.dart';

import '../models/analysis_result.dart';

/// Состояние шторки AI-разбора (компонент «BottomSheet / Разбор» в Figma,
/// свойство State: Loading / Normal / Error).
sealed class AnalysisSheetState {
  const AnalysisSheetState();
}

/// Запрос ушёл, ждём ответ — шиммер-скелетоны.
class AnalysisLoading extends AnalysisSheetState {
  const AnalysisLoading();
}

/// Ответ пришёл — перевод, смысл, этимология, иллюстрация.
class AnalysisLoaded extends AnalysisSheetState {
  const AnalysisLoaded(this.result);
  final AnalysisResult result;
}

/// Нет сети, сбой сервера или таймаут — ошибка и «Повторить».
class AnalysisFailed extends AnalysisSheetState {
  const AnalysisFailed(this.kind);
  final AnalysisFailureKind kind;
}

/// Функция, которая делает запрос к бэкенду.
///
/// Договорённость с сетевым слоем: при успехе вернуть [AnalysisResult],
/// при ошибке бросить [AnalysisException] с [AnalysisFailureKind.offline]
/// (нет интернета) или [AnalysisFailureKind.server] (сбой, таймаут).
/// Любое другое исключение шторка покажет как [AnalysisFailureKind.server].
typedef AnalysisFetcher = Future<AnalysisResult> Function();

/// Контроллер трёх состояний шторки: Loading → Success / Error.
///
/// Сам ничего не рисует — только хранит текущее состояние и вызывает
/// [fetch]. Шторка подписывается на него и перерисовывается.
class AnalysisSheetController extends ValueNotifier<AnalysisSheetState> {
  AnalysisSheetController({required this.fetch})
      : super(const AnalysisLoading());

  /// Запрос к бэкенду.
  final AnalysisFetcher fetch;

  /// Номер текущего запроса: ответ на устаревший запрос игнорируется.
  int _requestId = 0;
  bool _disposed = false;

  /// Сколько раз отправлялся запрос (удобно в тестах и логах).
  int get attempts => _requestId;

  bool get isLoading => value is AnalysisLoading;

  /// Отправляет запрос и переключает состояние: сначала Loading,
  /// потом Success или Error.
  Future<void> load() async {
    final id = ++_requestId;
    value = const AnalysisLoading();

    AnalysisSheetState next;
    try {
      next = AnalysisLoaded(await fetch());
    } on AnalysisException catch (e) {
      next = AnalysisFailed(e.kind);
    } catch (e, stack) {
      debugPrint('AI-разбор: непредвиденная ошибка $e\n$stack');
      next = const AnalysisFailed(AnalysisFailureKind.server);
    }

    // Шторку закрыли, пока шёл запрос, или уже отправлен новый запрос.
    if (_disposed || id != _requestId) return;
    value = next;
  }

  /// Коллбэк кнопки «Повторить»: повторно отправляет тот же запрос.
  /// Пока запрос уже идёт, второй не отправляем.
  Future<void> retry() async {
    if (isLoading && _requestId > 0) return;
    await load();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}