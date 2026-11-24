import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:literature_reader/theme/app_colors.dart';
import 'package:literature_reader/theme/app_theme.dart';
import 'package:literature_reader/widgets/book_widgets.dart';

/// Тесты к #29: автор виден во всех режимах, длинное название
/// не режется пополам, а сокращается многоточием.
const _longTitle = 'The Strange Case of Dr Jekyll and Mr Hyde, '
    'with Other Fables and a Very Long Subtitle Indeed';
const _longAuthor = 'Robert Louis Balfour Stevenson and Many Co-Authors';

Widget _app(Widget child) => MaterialApp(
      theme: buildAppTheme(ReaderTheme.light),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Align(alignment: Alignment.topLeft, child: child),
        ),
      ),
    );

/// Тексты, нарисованные внутри обложки.
Iterable<Text> _coverTexts(WidgetTester tester) => tester.widgetList<Text>(
      find.descendant(
        of: find.byType(BookCover),
        matching: find.byType(Text),
      ),
    );

void main() {
  group('Сгенерированная обложка', () {
    // Размеры из приложения: список, «Продолжить чтение», сетка на разных
    // телефонах — и с запасом.
    const sizes = [
      Size(56, 80),
      Size(80, 120),
      Size(104, 156),
      Size(118, 177),
      Size(160, 240),
    ];

    for (final s in sizes) {
      testWidgets('${s.width.toInt()}×${s.height.toInt()}: '
          'длинный текст помещается целыми строками', (tester) async {
        await tester.pumpWidget(_app(BookCover(
          title: _longTitle,
          author: _longAuthor,
          width: s.width,
          height: s.height,
        )));
        // Если строки не помещаются, Flutter сообщает о переполнении.
        expect(tester.takeException(), isNull);

        final title = _coverTexts(tester).first;
        expect(title.overflow, TextOverflow.ellipsis);
        expect(title.maxLines, isNotNull);
      });
    }

    testWidgets('автор на крупной обложке есть, на мелкой — нет',
        (tester) async {
      await tester.pumpWidget(_app(const BookCover(
        title: 'Alice',
        author: 'Lewis Carroll',
        width: 80,
        height: 120,
      )));
      expect(find.text('Lewis Carroll'), findsOneWidget);

      await tester.pumpWidget(_app(const BookCover(
        title: 'Alice',
        author: 'Lewis Carroll',
        width: 56,
        height: 80,
      )));
      expect(find.text('Lewis Carroll'), findsNothing);
    });
  });

  group('Автор виден во всех режимах', () {
    testWidgets('сетка', (tester) async {
      await tester.pumpWidget(_app(const SizedBox(
        width: 114,
        child: BookGridCard(
          title: _longTitle,
          author: 'Lewis Carroll',
          progress: 0.42,
        ),
      )));
      expect(tester.takeException(), isNull);
      // На обложке и под названием.
      expect(find.text('Lewis Carroll'), findsNWidgets(2));
      expect(find.text('42%'), findsOneWidget);
    });

    testWidgets('список', (tester) async {
      await tester.pumpWidget(_app(const SizedBox(
        width: 360,
        child: BookListTile(title: _longTitle, author: 'Lewis Carroll'),
      )));
      expect(tester.takeException(), isNull);
      expect(find.text('Lewis Carroll'), findsOneWidget);
    });

    testWidgets('«Продолжить чтение»', (tester) async {
      await tester.pumpWidget(_app(const SizedBox(
        width: 372,
        child: ContinueReadingCard(
          title: _longTitle,
          author: 'Lewis Carroll',
          progress: 0.5,
        ),
      )));
      expect(tester.takeException(), isNull);
      // На обложке и рядом с ней.
      expect(find.text('Lewis Carroll'), findsNWidgets(2));
    });
  });
}
