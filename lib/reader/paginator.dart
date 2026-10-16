import 'package:flutter/painting.dart';

import 'epub_parser.dart';

/// Кусок абзаца, который попал на страницу: [start, end) — символы абзаца.
/// Длинный абзац может разрезаться на несколько страниц, но в запрос к AI
/// всё равно уходит абзац целиком.
class PageFragment {
  const PageFragment({
    required this.chapterIndex,
    required this.paragraphIndex,
    required this.start,
    required this.end,
  });

  final int chapterIndex;
  final int paragraphIndex;
  final int start;
  final int end;
}

class ReaderPage {
  const ReaderPage(this.chapterIndex, this.fragments);

  final int chapterIndex;
  final List<PageFragment> fragments;

  PageFragment get first => fragments.first;
}

/// Раскладывает книгу на страницы под заданный размер области текста.
/// Каждая глава начинается с новой страницы.
List<ReaderPage> paginate(
  List<ReaderChapter> chapters, {
  required double maxWidth,
  required double maxHeight,
  required TextStyle style,
  required TextScaler textScaler,
  required double paragraphSpacing,
}) {
  final pages = <ReaderPage>[];
  final painter = TextPainter(
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
  );

  for (var c = 0; c < chapters.length; c++) {
    final paragraphs = chapters[c].paragraphs;
    var current = <PageFragment>[];
    var used = 0.0;

    void flush() {
      if (current.isEmpty) return;
      pages.add(ReaderPage(c, current));
      current = <PageFragment>[];
      used = 0;
    }

    for (var p = 0; p < paragraphs.length; p++) {
      final text = paragraphs[p];
      var offset = 0;

      while (offset < text.length) {
        final gap = current.isEmpty ? 0.0 : paragraphSpacing;
        final available = maxHeight - used - gap;

        painter.text = TextSpan(text: text.substring(offset), style: style);
        painter.layout(maxWidth: maxWidth);

        // Остаток абзаца целиком помещается на текущую страницу
        if (painter.height <= available) {
          current.add(
            PageFragment(
              chapterIndex: c,
              paragraphIndex: p,
              start: offset,
              end: text.length,
            ),
          );
          used += gap + painter.height;
          break;
        }

        // Считаем, сколько строк влезает
        final lines = painter.computeLineMetrics();
        var fitHeight = 0.0;
        var fitLines = 0;
        for (final line in lines) {
          if (fitHeight + line.height > available) break;
          fitHeight += line.height;
          fitLines++;
        }

        if (fitLines == 0) {
          if (current.isNotEmpty) {
            flush(); // переносим абзац на следующую страницу
            continue;
          }
          fitLines = 1; // экран меньше одной строки — всё равно ставим строку
          fitHeight = lines.first.height;
        }

        if (fitLines >= lines.length) {
          // Погрешность округления: строки влезли, а общая высота — нет
          current.add(
            PageFragment(
              chapterIndex: c,
              paragraphIndex: p,
              start: offset,
              end: text.length,
            ),
          );
          flush();
          break;
        }

        // Позиция первого символа первой не влезшей строки
        final cut = painter
            .getPositionForOffset(
              Offset(0, fitHeight + lines[fitLines].height / 2),
            )
            .offset;
        var end = offset + cut;
        if (end <= offset) end = offset + 1;

        current.add(
          PageFragment(
            chapterIndex: c,
            paragraphIndex: p,
            start: offset,
            end: end,
          ),
        );
        flush();

        offset = end;
        while (offset < text.length && text.codeUnitAt(offset) == 0x20) {
          offset++;
        }
      }
    }
    flush();
  }

  painter.dispose();
  return pages;
}

/// Индекс страницы, на которой находится позиция (глава, абзац, символ).
int pageForPosition(
  List<ReaderPage> pages, {
  required int chapterIndex,
  required int paragraphIndex,
  required int charOffset,
}) {
  var result = 0;
  for (var i = 0; i < pages.length; i++) {
    final f = pages[i].first;
    final cmp = f.chapterIndex != chapterIndex
        ? f.chapterIndex.compareTo(chapterIndex)
        : f.paragraphIndex != paragraphIndex
        ? f.paragraphIndex.compareTo(paragraphIndex)
        : f.start.compareTo(charOffset);
    if (cmp > 0) break;
    result = i;
  }
  return result;
}
