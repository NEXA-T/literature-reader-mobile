import 'package:epubx/epubx.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:html/parser.dart' as html_parser;

const _bookAsset = 'assets/books/alice.epub';

class ReaderChapter {
  const ReaderChapter(this.title, this.paragraphs);

  final String title;
  final List<String> paragraphs;
}

class SelectionContext {
  const SelectionContext({
    required this.selectedText,
    required this.paragraph,
    required this.chapterTitle,
    required this.paragraphIndex,
  });

  final String selectedText;
  final String paragraph;
  final String chapterTitle;
  final int paragraphIndex;
}

Future<List<ReaderChapter>> loadBook(String assetPath) async {
  final data = await rootBundle.load(assetPath);
  final book = await EpubReader.readBook(data.buffer.asUint8List());

  final chapters = <ReaderChapter>[];
  final seenFiles = <String>{};

  void walk(List<EpubChapter>? list) {
    for (final chapter in list ?? const <EpubChapter>[]) {
      final file = chapter.ContentFileName ?? '';
      if (seenFiles.add(file)) {
        final doc = html_parser.parse(chapter.HtmlContent ?? '');
        final paragraphs = doc
            .querySelectorAll('p')
            .map((p) => p.text.replaceAll(RegExp(r'\s+'), ' ').trim())
            .where((t) => t.isNotEmpty)
            .toList();
        if (paragraphs.isNotEmpty) {
          final title = chapter.Title?.replaceAll('\n', ' ').trim();
          chapters.add(
            ReaderChapter(
              (title == null || title.isEmpty)
                  ? 'Глава ${chapters.length + 1}'
                  : title,
              paragraphs,
            ),
          );
        }
      }
      walk(chapter.SubChapters);
    }
  }

  walk(book.Chapters);
  return chapters;
}

class EpubReaderPage extends StatefulWidget {
  const EpubReaderPage({super.key});

  @override
  State<EpubReaderPage> createState() => _EpubReaderPageState();
}

class _EpubReaderPageState extends State<EpubReaderPage> {
  late final Future<List<ReaderChapter>> _book = loadBook(_bookAsset);
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int page) => _pageController.animateToPage(
    page,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOut,
  );

  void _onSelection(SelectionContext ctx) {
    debugPrint('SELECTED  : ${ctx.selectedText}');
    debugPrint('PARAGRAPH : ${ctx.paragraph}');
    debugPrint(
      'WHERE     : ${ctx.chapterTitle}, абзац ${ctx.paragraphIndex + 1}',
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Выделено', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(
                '«${ctx.selectedText}»',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Контекст: ${ctx.chapterTitle}, абзац ${ctx.paragraphIndex + 1}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(ctx.paragraph),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ReaderChapter>>(
      future: _book,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Ошибка открытия книги:\n${snapshot.error}'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final chapters = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            title: Text(chapters[_page].title, overflow: TextOverflow.ellipsis),
          ),
          body: PageView.builder(
            controller: _pageController,
            itemCount: chapters.length,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, index) {
              final chapter = chapters[index];
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                itemCount: chapter.paragraphs.length,
                itemBuilder: (context, i) => _SelectableParagraph(
                  text: chapter.paragraphs[i],
                  onAsk: (selected) => _onSelection(
                    SelectionContext(
                      selectedText: selected,
                      paragraph: chapter.paragraphs[i],
                      chapterTitle: chapter.title,
                      paragraphIndex: i,
                    ),
                  ),
                ),
              );
            },
          ),
          bottomNavigationBar: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: _page > 0 ? () => _goTo(_page - 1) : null,
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Назад'),
                ),
                Text('${_page + 1} / ${chapters.length}'),
                TextButton.icon(
                  onPressed: _page < chapters.length - 1
                      ? () => _goTo(_page + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Вперёд'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SelectableParagraph extends StatelessWidget {
  const _SelectableParagraph({required this.text, required this.onAsk});

  final String text;
  final ValueChanged<String> onAsk;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SelectableText(
        text,
        style: const TextStyle(fontSize: 17, height: 1.5),
        contextMenuBuilder: (context, editableTextState) {
          final value = editableTextState.textEditingValue;
          final selected = value.selection.textInside(value.text).trim();
          return AdaptiveTextSelectionToolbar.buttonItems(
            anchors: editableTextState.contextMenuAnchors,
            buttonItems: [
              ...editableTextState.contextMenuButtonItems,
              if (selected.isNotEmpty)
                ContextMenuButtonItem(
                  label: 'Спросить ИИ',
                  onPressed: () {
                    editableTextState.hideToolbar();
                    onAsk(selected);
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
