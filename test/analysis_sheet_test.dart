import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:literature_reader/models/analysis_result.dart';
import 'package:literature_reader/theme/app_colors.dart';
import 'package:literature_reader/theme/app_theme.dart';
import 'package:literature_reader/widgets/analysis_sheet.dart';
import 'package:literature_reader/widgets/illustration_view.dart';
import 'package:literature_reader/widgets/shimmer.dart';

const _full = AnalysisResult(
  translation: 'мертвее мёртвого',
  contextMeaning: 'ирония рассказчика',
  slangOrEtymology: 'XIV век',
  imagePrompt: 'an old wooden door with a bent nail',
);

/// Прозрачная картинка 1×1 — подменяет генерацию в тестах.
final _pixel = MemoryImage(Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, //
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0xDA, 0x63, 0x60, 0x60, 0x60, 0x60, //
  0x00, 0x00, 0x00, 0x05, 0x00, 0x01, 0x7A, 0xA8, 0x57, 0x50, 0x00, 0x00, //
  0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82, //
]));

/// Загрузчик иллюстраций для тестов: мгновенно отдаёт картинку.
Future<ImageProvider> _instantImage(String imagePrompt) async => _pixel;

const _noSlang = AnalysisResult(
  translation: 'перевод',
  contextMeaning: 'смысл',
  imagePrompt: 'a clerk signing a register',
);

const _noPrompt = AnalysisResult(
  translation: 'перевод',
  contextMeaning: 'смысл',
  slangOrEtymology: 'сленг',
);

Widget _view(AnalysisSheetState state, {VoidCallback? onRetry}) {
  return MaterialApp(
    theme: buildAppTheme(ReaderTheme.light),
    home: Scaffold(
      body: AnalysisSheetView(
        fragment: 'as dead as a door-nail',
        state: state,
        loadIllustration: _instantImage,
        onRetry: onRetry ?? () {},
        onClose: () {},
      ),
    ),
  );
}

/// Экран с кнопкой, которая открывает настоящую шторку.
Widget _host(AnalysisFetcher fetch) {
  return MaterialApp(
    theme: buildAppTheme(ReaderTheme.light),
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => showAnalysisSheet(
              context,
              fragment: 'as dead as a door-nail',
              fetch: fetch,
              loadIllustration: _instantImage,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('AnalysisResult', () {
    test('читает поля API-контракта', () {
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

    test('пустая строка в slang_or_etymology считается как null', () {
      final r = AnalysisResult.fromJson({
        'translation': 'a',
        'context_meaning': 'b',
        'slang_or_etymology': '  ',
      });
      expect(r.slangOrEtymology, isNull);
    });
  });

  group('AnalysisSheetController', () {
    test('Loading → Success', () async {
      final c = AnalysisSheetController(fetch: () async => _full);
      expect(c.value, isA<AnalysisLoading>());
      await c.load();
      expect(c.value, isA<AnalysisLoaded>());
      c.dispose();
    });

    test('Loading → Error с видом ошибки', () async {
      final c = AnalysisSheetController(
        fetch: () async =>
            throw const AnalysisException(AnalysisFailureKind.offline),
      );
      await c.load();
      expect(c.value, isA<AnalysisFailed>());
      expect((c.value as AnalysisFailed).kind, AnalysisFailureKind.offline);
      c.dispose();
    });

    test('неизвестная ошибка показывается как сбой сервера', () async {
      final c = AnalysisSheetController(
        fetch: () async => throw TimeoutException('10s'),
      );
      await c.load();
      expect((c.value as AnalysisFailed).kind, AnalysisFailureKind.server);
      c.dispose();
    });

    test('retry повторно вызывает запрос', () async {
      var calls = 0;
      final c = AnalysisSheetController(
        fetch: () async {
          calls++;
          if (calls == 1) {
            throw const AnalysisException(AnalysisFailureKind.server);
          }
          return _full;
        },
      );
      await c.load();
      expect(c.value, isA<AnalysisFailed>());
      await c.retry();
      expect(calls, 2);
      expect(c.value, isA<AnalysisLoaded>());
      c.dispose();
    });

    test('ответ после закрытия шторки не роняет приложение', () async {
      final completer = Completer<AnalysisResult>();
      final c = AnalysisSheetController(fetch: () => completer.future);
      final pending = c.load();
      c.dispose();
      completer.complete(_full);
      await pending;
    });
  });

  group('Шторка: состояния', () {
    testWidgets('Loading: шиммер и «Разбираем фрагмент…»', (tester) async {
      await tester.pumpWidget(_view(const AnalysisLoading()));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Разбираем фрагмент…'), findsOneWidget);
      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.byType(SkeletonBox), findsWidgets);
      // Подписи блоков видны и во время загрузки.
      expect(find.text('ПЕРЕВОД'), findsOneWidget);
    });

    testWidgets('Success: все блоки и иллюстрация',
        (tester) async {
      await tester.pumpWidget(_view(const AnalysisLoaded(_full)));
      await tester.pumpAndSettle();
      expect(find.text('ПЕРЕВОД'), findsOneWidget);
      expect(find.text('СМЫСЛОВОЙ КОНТЕКСТ'), findsOneWidget);
      expect(find.text('ЭТИМОЛОГИЯ / СЛЕНГ'), findsOneWidget);
      expect(find.text('ИЛЛЮСТРАЦИЯ'), findsOneWidget);
      expect(find.byType(IllustrationView), findsOneWidget);
    });

    testWidgets('slang_or_etymology = null: блока нет в дереве',
        (tester) async {
      await tester.pumpWidget(_view(const AnalysisLoaded(_noSlang)));
      await tester.pumpAndSettle();
      expect(find.text('ЭТИМОЛОГИЯ / СЛЕНГ'), findsNothing);
      expect(find.text('XIV век'), findsNothing);
      expect(find.text('ИЛЛЮСТРАЦИЯ'), findsOneWidget);
    });

    testWidgets('загрузчик не подключён: пунктирная заглушка', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: buildAppTheme(ReaderTheme.light),
        home: Scaffold(
          body: AnalysisSheetView(
            fragment: 'as dead as a door-nail',
            state: const AnalysisLoaded(_full),
            onRetry: () {},
            onClose: () {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(IllustrationPlaceholder), findsOneWidget);
      expect(find.text('Здесь появится иллюстрация'), findsOneWidget);
      expect(find.byType(IllustrationView), findsNothing);
    });

    testWidgets('image_prompt = null: блока иллюстрации нет', (tester) async {
      await tester.pumpWidget(_view(const AnalysisLoaded(_noPrompt)));
      await tester.pumpAndSettle();
      expect(find.text('ИЛЛЮСТРАЦИЯ'), findsNothing);
      expect(find.byType(IllustrationView), findsNothing);
      expect(find.text('ЭТИМОЛОГИЯ / СЛЕНГ'), findsOneWidget);
    });

    testWidgets('Error: текст из задачи и «Повторить» вызывает коллбэк',
        (tester) async {
      var retried = 0;
      await tester.pumpWidget(_view(
        const AnalysisFailed(AnalysisFailureKind.offline),
        onRetry: () => retried++,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Не удалось получить разбор'), findsOneWidget);
      expect(
        find.text('Проверьте подключение к интернету и попробуйте ещё раз'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      await tester.tap(find.text('Повторить'));
      expect(retried, 1);
    });

    testWidgets('в шапке выделенный текст в кавычках', (tester) async {
      await tester.pumpWidget(_view(const AnalysisLoading()));
      await tester.pump();
      expect(find.text('«as dead as a door-nail»'), findsOneWidget);
    });
  });

  group('Шторка поверх экрана', () {
    testWidgets('Loading → Success, крестик закрывает', (tester) async {
      final completer = Completer<AnalysisResult>();
      await tester.pumpWidget(_host(() => completer.future));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Разбираем фрагмент…'), findsOneWidget);

      completer.complete(_full);
      await tester.pumpAndSettle();
      expect(find.text('мертвее мёртвого'), findsOneWidget);

      await tester.tap(find.byTooltip('Закрыть'));
      await tester.pumpAndSettle();
      expect(find.text('мертвее мёртвого'), findsNothing);
    });

    testWidgets('Loading → Error → «Повторить» → Success', (tester) async {
      var calls = 0;
      await tester.pumpWidget(_host(() async {
        calls++;
        if (calls == 1) {
          throw const AnalysisException(AnalysisFailureKind.offline);
        }
        return _full;
      }));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Не удалось получить разбор'), findsOneWidget);

      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.text('мертвее мёртвого'), findsOneWidget);
    });
  });
}
