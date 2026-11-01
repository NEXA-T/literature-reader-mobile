import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:literature_reader/reader/epub_parser.dart';
import 'package:literature_reader/reader/paginator.dart';
import 'package:literature_reader/screens/reader_screen.dart';
import 'package:literature_reader/theme/app_colors.dart';
import 'package:literature_reader/theme/app_theme.dart';

/// Регрессионный тест для #19: нижняя строка страницы не должна обрезаться.
///
/// Страницы считает paginate() (TextPainter), а рисует их SelectableText.
/// Если они видят текст по-разному (другой стиль, другая ширина), строк
/// на экране выходит больше, чем насчитано, и низ страницы обрезается.
/// Тест раскладывает книгу ровно как экран чтения — тем же стилем
/// readerTextStyle() внутри той же темы — и рисует каждую страницу.
void main() {
  // Те же числа, что в reader_screen.dart.
  const caretMargin = 3.0;
  const paragraphSpacing = 12.0;

  const pageWidth = 330.0;
  const pageHeight = 420.0;

  // Слова разной длины — чтобы переносы попадали на разные места строк.
  const words = [
    'Alice', 'was', 'beginning', 'to', 'get', 'very', 'tired', 'of',
    'sitting', 'by', 'her', 'sister', 'on', 'the', 'bank,', 'and',
    'having', 'nothing', 'to', 'do:', 'once', 'or', 'twice', 'she',
    'peeped', 'into', 'the', 'book', 'her', 'sister', 'was', 'reading',
  ];
  String paragraph(int seed, int length) => [
    for (var i = 0; i < length; i++) words[(i * 7 + seed * 3) % words.length],
  ].join(' ');

  final chapters = [
    ReaderChapter('Глава', [
      for (var p = 0; p < 10; p++) paragraph(p, 25 + p * 9),
    ]),
  ];

  /// Страница в тех же условиях, что в приложении: тема и Scaffold
  /// (он задаёт DefaultTextStyle, с которым смешивается стиль текста).
  Widget screen(Widget child) => MaterialApp(
    theme: buildAppTheme(ReaderTheme.light),
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: pageWidth, child: child),
      ),
    ),
  );

  testWidgets('каждая страница помещается в высоту области текста',
      (tester) async {
    // 1. Берём стиль ровно так, как его берёт экран чтения.
    late TextStyle style;
    late TextScaler scaler;
    await tester.pumpWidget(screen(Builder(builder: (context) {
      style = readerTextStyle(context);
      scaler = MediaQuery.textScalerOf(context);
      return const SizedBox();
    })));

    // 2. Раскладываем на страницы, как в _ensurePaginated.
    final pages = paginate(
      chapters,
      maxWidth: pageWidth - caretMargin,
      maxHeight: pageHeight,
      style: style,
      textScaler: scaler,
      paragraphSpacing: paragraphSpacing,
    );
    expect(pages.length, greaterThan(2));

    // 3. Рисуем каждую страницу настоящим SelectableText.
    final paragraphs = chapters.single.paragraphs;
    for (var i = 0; i < pages.length; i++) {
      final page = pages[i];
      final column = GlobalKey();
      await tester.pumpWidget(screen(Builder(builder: (context) {
        final textStyle = readerTextStyle(context);
        return Column(
          key: column,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var f = 0; f < page.fragments.length; f++) ...[
              if (f > 0) const SizedBox(height: paragraphSpacing),
              SelectableText(
                paragraphs[page.fragments[f].paragraphIndex].substring(
                  page.fragments[f].start,
                  page.fragments[f].end,
                ),
                style: textStyle,
              ),
            ],
          ],
        );
      })));

      final height = tester.getSize(find.byKey(column)).height;
      expect(
        height,
        lessThanOrEqualTo(pageHeight),
        reason: 'страница ${i + 1} из ${pages.length} выше области текста',
      );
    }
  });

  testWidgets('стиль текста книги без разрядки из темы', (tester) async {
    late TextStyle style;
    await tester.pumpWidget(screen(Builder(builder: (context) {
      style = readerTextStyle(context);
      return const SizedBox();
    })));
    expect(style.letterSpacing, 0);
    expect(style.fontSize, 18);
  });
}
