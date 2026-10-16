import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:literature_reader/models/analysis_result.dart';
import 'package:literature_reader/theme/app_colors.dart';
import 'package:literature_reader/theme/app_theme.dart';
import 'package:literature_reader/widgets/analysis_sheet.dart';

Widget _wrap(AnalysisSheetState state, {VoidCallback? onRetry}) {
  return MaterialApp(
    theme: buildAppTheme(ReaderTheme.light),
    home: Scaffold(
      body: AnalysisSheetView(
        fragment: 'as dead as a door-nail',
        state: state,
        onRetry: onRetry ?? () {},
        onClose: () {},
      ),
    ),
  );
}

void main() {
  test('AnalysisResult читает поля API-контракта', () {
    final r = AnalysisResult.fromJson({
      'translation': 'мертвее мёртвого',
      'context_meaning': 'ирония рассказчика',
      'slang_or_etymology': null,
      'image_prompt': 'door',
    });
    expect(r.translation, 'мертвее мёртвого');
    expect(r.contextMeaning, 'ирония рассказчика');
    expect(r.slangOrEtymology, isNull);
    expect(r.imagePrompt, 'door');
  });

  testWidgets('Normal: все блоки на месте', (tester) async {
    await tester.pumpWidget(_wrap(const AnalysisLoaded(AnalysisResult(
      translation: 'мертвее мёртвого',
      contextMeaning: 'ирония',
      slangOrEtymology: 'XIV век',
    ))));
    await tester.pumpAndSettle();
    expect(find.text('ПЕРЕВОД'), findsOneWidget);
    expect(find.text('СМЫСЛОВОЙ КОНТЕКСТ'), findsOneWidget);
    expect(find.text('ЭТИМОЛОГИЯ / СЛЕНГ'), findsOneWidget);
    expect(find.text('ИЛЛЮСТРАЦИЯ'), findsOneWidget);
  });

  testWidgets('AC 4.3: без сленга блок скрыт', (tester) async {
    await tester.pumpWidget(_wrap(const AnalysisLoaded(AnalysisResult(
      translation: 'перевод',
      contextMeaning: 'смысл',
    ))));
    await tester.pumpAndSettle();
    expect(find.text('ЭТИМОЛОГИЯ / СЛЕНГ'), findsNothing);
  });

  testWidgets('Error: кнопка «Повторить» вызывает onRetry', (tester) async {
    var retried = 0;
    await tester.pumpWidget(_wrap(
      const AnalysisFailed(AnalysisFailureKind.server),
      onRetry: () => retried++,
    ));
    await tester.pumpAndSettle();
    expect(find.text('Не удалось получить разбор'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    expect(retried, 1);
  });

  testWidgets('Loading: показан скелетон', (tester) async {
    await tester.pumpWidget(_wrap(const AnalysisLoading()));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Разбираем фрагмент…'), findsOneWidget);
  });
}
