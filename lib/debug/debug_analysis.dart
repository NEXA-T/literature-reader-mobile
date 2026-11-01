import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../models/analysis_result.dart';
import '../widgets/analysis_sheet_controller.dart';
import '../widgets/illustration_view.dart';

/// Отладочная подмена ответа AI — чтобы проверить и заснять все
/// состояния шторки без бэкенда и без отключения интернета.
///
/// Работает только в режиме отладки (`flutter run`). В релизной сборке
/// [kDebugMode] равен false, и подмена никогда не срабатывает.
enum DebugAnalysisMode {
  /// Обычный запрос — как в приложении для пользователей.
  off('Как в приложении'),
  success('Успех'),
  successNoSlang('Успех без сленга'),
  offline('Ошибка: нет сети'),
  server('Ошибка: сбой сервера'),
  errorThenSuccess('Ошибка → «Повторить» → успех');

  const DebugAnalysisMode(this.label);

  final String label;
}

/// Текущий режим. Переключается в меню темы (иконка палитры).
final debugAnalysisMode = ValueNotifier<DebugAnalysisMode>(
  DebugAnalysisMode.off,
);

/// Задержка ответа в отладке — чтобы успеть увидеть шиммер.
const _debugDelay = Duration(milliseconds: 1800);

/// Если включена отладочная подмена, возвращает поддельный запрос,
/// иначе — настоящий [fetch] без изменений.
AnalysisFetcher applyDebugAnalysisMode(AnalysisFetcher fetch) {
  if (!kDebugMode) return fetch;
  final mode = debugAnalysisMode.value;
  if (mode == DebugAnalysisMode.off) return fetch;

  var attempt = 0;
  return () async {
    attempt++;
    await Future<void>.delayed(_debugDelay);
    switch (mode) {
      case DebugAnalysisMode.offline:
        throw const AnalysisException(AnalysisFailureKind.offline);
      case DebugAnalysisMode.server:
        throw const AnalysisException(AnalysisFailureKind.server);
      case DebugAnalysisMode.errorThenSuccess:
        if (attempt == 1) {
          throw const AnalysisException(AnalysisFailureKind.offline);
        }
        return AnalysisResult.fromJson(_withSlang);
      case DebugAnalysisMode.successNoSlang:
        return AnalysisResult.fromJson(_withoutSlang);
      case DebugAnalysisMode.success:
      case DebugAnalysisMode.off:
        return AnalysisResult.fromJson(_withSlang);
    }
  };
}

/// Отладочная подмена генерации иллюстрации — по тем же правилам,
/// что и [DebugAnalysisMode]: только в `flutter run`.
enum DebugIllustrationMode {
  off('Как в приложении'),
  sample('Пример картинки'),
  failed('Ошибка генерации'),
  failThenSample('Ошибка → «Повторить» → картинка');

  const DebugIllustrationMode(this.label);

  final String label;
}

final debugIllustrationMode = ValueNotifier<DebugIllustrationMode>(
  DebugIllustrationMode.off,
);

/// Картинка-пример, лежит в assets/debug/. Это настоящая иллюстрация
/// GigaChat к «dead as a door-nail» из бэкенда (docs/demo-assets/07_door_nail.jpg).
const debugIllustrationAsset = 'assets/debug/illustration_sample.jpg';

/// Задержка «генерации» в отладке — чтобы успеть увидеть шиммер.
const _illustrationDelay = Duration(milliseconds: 2500);

/// Работает, даже если настоящий загрузчик ещё не подключён (`null`),
/// — так все состояния блока можно проверить заранее.
IllustrationLoader? applyDebugIllustrationMode(IllustrationLoader? load) {
  if (!kDebugMode) return load;
  final mode = debugIllustrationMode.value;
  if (mode == DebugIllustrationMode.off) return load;

  var attempt = 0;
  return (prompt) async {
    attempt++;
    await Future<void>.delayed(_illustrationDelay);
    final fail = mode == DebugIllustrationMode.failed ||
        (mode == DebugIllustrationMode.failThenSample && attempt == 1);
    if (fail) {
      throw const AnalysisException(AnalysisFailureKind.server);
    }
    return const AssetImage(debugIllustrationAsset);
  };
}

/// Пример ответа в формате API-контракта.
const Map<String, dynamic> _withSlang = {
  'translation': 'мертвее мёртвого; окончательно и бесповоротно мёртв',
  'context_meaning':
      'Рассказчик с иронией подчёркивает, что Марли умер окончательно. '
          'Это важно: дальше в повести появится его призрак, и читатель '
          'не должен сомневаться, что перед Скруджем именно дух.',
  'slang_or_etymology':
      'Устойчивое выражение известно с XIV века. По одной из версий, '
          'гвоздь, загнутый с обратной стороны двери, уже нельзя было '
          'вытащить и использовать снова — он «мёртв».',
  'image_prompt': 'An old wooden door with a bent iron nail, foggy London',
};

/// Тот же ответ, но без сленга: блок этимологии должен исчезнуть.
const Map<String, dynamic> _withoutSlang = {
  'translation': 'Регистрационную запись о его похоронах подписали',
  'context_meaning':
      'Рассказчик перечисляет всех, кто удостоверил смерть Марли, '
          'будто составляет юридический документ. Так Диккенс заранее '
          'снимает любые сомнения: это важно для появления призрака.',
  'slang_or_etymology': null,
  'image_prompt': 'Victorian clerk signing a burial register',
};
