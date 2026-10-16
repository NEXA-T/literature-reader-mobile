import 'dart:isolate';
import 'dart:typed_data';

import 'package:epubx/epubx.dart';
import 'package:html/parser.dart' as html_parser;

/// Глава книги в виде простого списка абзацев (без HTML).
class ReaderChapter {
  const ReaderChapter(this.title, this.paragraphs);

  final String title;
  final List<String> paragraphs;
}

/// Разбирает EPUB в отдельном изоляте, чтобы не подвешивать интерфейс
/// на больших книгах.
Future<List<ReaderChapter>> parseEpubInBackground(Uint8List bytes) =>
    Isolate.run(() => parseEpub(bytes));

/// Читает главы в порядке spine (порядок чтения из OPF), поэтому в книгу
/// попадают и разделы, которых нет в оглавлении. Названия берутся из
/// оглавления, если раздел там есть.
Future<List<ReaderChapter>> parseEpub(Uint8List bytes) async {
  final book = await EpubReader.readBook(bytes);

  // Название главы по имени файла (без #якоря) — из оглавления
  final titles = <String, String>{};
  void collectTitles(List<EpubChapter>? list) {
    for (final ch in list ?? const <EpubChapter>[]) {
      final file = _stripAnchor(ch.ContentFileName);
      final title = _clean(ch.Title ?? '');
      if (file != null && title.isNotEmpty) titles.putIfAbsent(file, () => title);
      collectTitles(ch.SubChapters);
    }
  }

  collectTitles(book.Chapters);

  final html = book.Content?.Html ?? {};
  final manifest = <String, String>{};
  for (final item in book.Schema?.Package?.Manifest?.Items ?? []) {
    if (item.Id != null && item.Href != null) manifest[item.Id!] = item.Href!;
  }

  final chapters = <ReaderChapter>[];
  for (final ref in book.Schema?.Package?.Spine?.Items ?? []) {
    final href = manifest[ref.IdRef];
    if (href == null) continue;
    final decoded = _safeDecode(href);
    final content = (html[href] ?? html[decoded])?.Content;
    if (content == null) continue;

    final chapter = _toChapter(
      content,
      titles[href] ?? titles[decoded],
      chapters.length,
    );
    if (chapter != null) chapters.add(chapter);
  }

  // Запасной вариант, если spine пустой или нестандартный — как в PoC
  if (chapters.isEmpty) {
    final seen = <String>{};
    void walk(List<EpubChapter>? list) {
      for (final ch in list ?? const <EpubChapter>[]) {
        if (seen.add(ch.ContentFileName ?? '')) {
          final chapter = _toChapter(
            ch.HtmlContent ?? '',
            _clean(ch.Title ?? ''),
            chapters.length,
          );
          if (chapter != null) chapters.add(chapter);
        }
        walk(ch.SubChapters);
      }
    }

    walk(book.Chapters);
  }

  return chapters;
}

ReaderChapter? _toChapter(String htmlContent, String? title, int index) {
  final doc = html_parser.parse(htmlContent);

  var paragraphs = doc
      .querySelectorAll('p')
      .map((p) => _clean(p.text))
      .where((t) => t.isNotEmpty)
      .toList();

  // Некоторые книги размечают текст через <div>. Страницу оглавления (<nav>)
  // не превращаем в текст.
  if (paragraphs.isEmpty && doc.querySelector('nav') == null) {
    paragraphs = (doc.body?.text ?? '')
        .split('\n')
        .map(_clean)
        .where((t) => t.isNotEmpty)
        .toList();
  }
  if (paragraphs.isEmpty) return null;

  final heading = doc.querySelector('h1, h2, h3');
  final headingText = heading == null ? '' : _clean(heading.text);
  final resolvedTitle = (title != null && title.isNotEmpty)
      ? title
      : headingText.isNotEmpty
      ? headingText
      : 'Глава ${index + 1}';

  return ReaderChapter(resolvedTitle, paragraphs);
}

String _clean(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

String? _stripAnchor(String? fileName) {
  if (fileName == null || fileName.isEmpty) return null;
  final i = fileName.indexOf('#');
  return i == -1 ? fileName : fileName.substring(0, i);
}

String _safeDecode(String s) {
  try {
    return Uri.decodeFull(s);
  } catch (_) {
    return s;
  }
}
