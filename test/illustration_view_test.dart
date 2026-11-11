import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:literature_reader/models/analysis_result.dart';
import 'package:literature_reader/theme/app_colors.dart';
import 'package:literature_reader/theme/app_theme.dart';
import 'package:literature_reader/widgets/illustration_view.dart';

/// Прозрачная картинка 1×1.
final _pixel = MemoryImage(Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, //
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0xDA, 0x63, 0x60, 0x60, 0x60, 0x60, //
  0x00, 0x00, 0x00, 0x05, 0x00, 0x01, 0x7A, 0xA8, 0x57, 0x50, 0x00, 0x00, //
  0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82, //
]));

/// Картинка, которая не открывается (как ссылка, отдавшая 404).
class _BrokenImage extends ImageProvider<_BrokenImage> {
  const _BrokenImage();

  @override
  Future<_BrokenImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(_BrokenImage key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(
        Future<ImageInfo>.error(Exception('404 Not Found')),
      );
}

/// Загрузчик, которым управляет тест: каждый вызов — новый Completer.
class _FakeLoader {
  final calls = <Completer<ImageProvider>>[];

  Future<ImageProvider> call(String imagePrompt) {
    final c = Completer<ImageProvider>();
    calls.add(c);
    return c.future;
  }
}

Widget _app(IllustrationLoader load) {
  return MaterialApp(
    theme: buildAppTheme(ReaderTheme.light),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 320,
          child: IllustrationView(prompt: 'a foggy street', load: load),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('генерация → картинка, размер блока не меняется',
      (tester) async {
    final gen = _FakeLoader();
    await tester.pumpWidget(_app(gen.call));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Генерируем иллюстрацию сцены…'), findsOneWidget);
    expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
    final loadingSize = tester.getSize(find.byType(IllustrationView));
    expect(loadingSize.width / loadingSize.height,
        closeTo(illustrationAspectRatio, 0.01));

    gen.calls.single.complete(_pixel);
    await tester.pumpAndSettle();

    expect(find.text('Генерируем иллюстрацию сцены…'), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    expect(tester.getSize(find.byType(IllustrationView)), loadingSize);
  });

  testWidgets('ошибка → «Повторить генерацию» → картинка', (tester) async {
    final gen = _FakeLoader();
    await tester.pumpWidget(_app(gen.call));
    await tester.pump();
    final size = tester.getSize(find.byType(IllustrationView));

    gen.calls.single.completeError(
      const AnalysisException(AnalysisFailureKind.offline),
    );
    await tester.pumpAndSettle();
    expect(find.text('Не удалось создать иллюстрацию'), findsOneWidget);
    expect(tester.getSize(find.byType(IllustrationView)), size);

    await tester.tap(find.text('Повторить генерацию'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(gen.calls, hasLength(2));
    expect(find.text('Генерируем иллюстрацию сцены…'), findsOneWidget);

    gen.calls.last.complete(_pixel);
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('тап по картинке открывает и закрывает полный экран',
      (tester) async {
    await tester.pumpWidget(
      _app((imagePrompt) async => _pixel),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(IllustrationView));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);

    await tester.tap(find.byTooltip('Закрыть'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
  });

  testWidgets('картинка не открылась → «Повторить генерацию»', (tester) async {
    var calls = 0;
    await tester.pumpWidget(_app((imagePrompt) async {
      calls++;
      return calls == 1 ? const _BrokenImage() : _pixel;
    }));
    await tester.pumpAndSettle();
    expect(find.text('Не удалось создать иллюстрацию'), findsOneWidget);

    await tester.tap(find.text('Повторить генерацию'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Не удалось создать иллюстрацию'), findsNothing);
  });

  testWidgets('долгая генерация: через 8 с появляется подсказка',
      (tester) async {
    final gen = _FakeLoader();
    await tester.pumpWidget(_app(gen.call));
    await tester.pump();
    final size = tester.getSize(find.byType(IllustrationView));

    double hintOpacity() => tester
        .widget<AnimatedOpacity>(find.ancestor(
          of: find.text('Обычно это занимает до 40 секунд'),
          matching: find.byType(AnimatedOpacity),
        ))
        .opacity;

    expect(hintOpacity(), 0);
    await tester.pump(const Duration(seconds: 9));
    expect(hintOpacity(), 1);
    // Подсказка не сдвигает блок: место под неё зарезервировано заранее.
    expect(tester.getSize(find.byType(IllustrationView)), size);

    gen.calls.single.complete(_pixel);
    await tester.pumpAndSettle();
    expect(find.text('Обычно это занимает до 40 секунд'), findsNothing);
  });

  testWidgets('SVG-заглушка от сервера сразу даёт «Повторить генерацию»',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(_app((imagePrompt) async {
      calls++;
      return calls == 1
          ? NetworkImage('https://example.ngrok-free.app/static/'
              'generated_images/img_1.svg')
          : _pixel;
    }));
    await tester.pumpAndSettle();
    expect(find.text('Не удалось создать иллюстрацию'), findsOneWidget);

    await tester.tap(find.text('Повторить генерацию'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('ответ после закрытия не роняет виджет', (tester) async {
    final gen = _FakeLoader();
    await tester.pumpWidget(_app(gen.call));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    gen.calls.single.complete(_pixel);
    await tester.pump();
  });
}
