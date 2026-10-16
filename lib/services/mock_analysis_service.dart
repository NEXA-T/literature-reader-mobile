import '../models/analysis_result.dart';

/// Сценарий ответа заглушки — переключается на демо-экране,
/// чтобы показать все состояния шторки без настоящего бэкенда.
enum MockScenario { success, successNoSlang, offline, serverError }

/// Временная замена запроса к FastAPI. Когда бэкенд будет готов,
/// её заменит настоящий сервис с тем же методом [analyze].
class MockAnalysisService {
  MockAnalysisService({this.delay = const Duration(milliseconds: 1800)});

  final Duration delay;
  MockScenario scenario = MockScenario.success;

  Future<AnalysisResult> analyze({
    required String selectedText,
    required String context,
    required String bookTitle,
    MockScenario? override,
  }) async {
    await Future<void>.delayed(delay);
    switch (override ?? scenario) {
      case MockScenario.offline:
        throw const AnalysisException(AnalysisFailureKind.offline);
      case MockScenario.serverError:
        throw const AnalysisException(AnalysisFailureKind.server);
      case MockScenario.successNoSlang:
        return AnalysisResult.fromJson({
          'translation': 'Регистрационную запись о его похоронах подписали',
          'context_meaning':
              'Рассказчик перечисляет всех, кто удостоверил смерть Марли, '
                  'будто составляет юридический документ. Так Диккенс заранее '
                  'снимает любые сомнения: это важно для появления призрака.',
          'slang_or_etymology': null,
          'image_prompt': 'Victorian clerk signing a burial register',
        });
      case MockScenario.success:
        return AnalysisResult.fromJson(_doorNail);
    }
  }
}

/// Пример ответа в формате API-контракта (захардкоженный JSON).
const Map<String, dynamic> _doorNail = {
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
