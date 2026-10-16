import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter/material.dart';

import '../ai_explain/ai_explain_request.dart';
import '../ai_explain/ai_explain_sheet.dart';
import '../models/book.dart';
import '../models/reading_progress.dart';
import '../reader/epub_parser.dart';
import '../reader/paginator.dart';
import '../reader/selectable_paragraph.dart';
import '../services/reading_progress_service.dart';

/// Экран чтения (US-02): постраничный просмотр книги, сохранение позиции,
/// выделение текста с вызовом шторки «Объяснить с AI» (US-03).
class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.book, required this.filePath});

  final Book book;

  /// Путь к .epub внутри папки приложения
  final String filePath;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderData {
  const _ReaderData(this.chapters, this.progress);

  final List<ReaderChapter> chapters;
  final ReadingProgress? progress;
}

class _ReaderScreenState extends State<ReaderScreen>
    with WidgetsBindingObserver {
  static const _pagePadding = EdgeInsets.fromLTRB(24, 16, 24, 16);
  static const _paragraphSpacing = 12.0;

  /// Доля ширины экрана слева/справа, тап по которой листает страницу
  static const _tapZone = 0.3;

  final _progressService = ReadingProgressService();
  late final Future<_ReaderData> _data = _load();

  List<ReaderChapter> _chapters = const [];
  List<ReaderPage> _pages = const [];
  String? _layoutKey;
  PageController? _pageController;
  int _currentPage = 0;

  // Обработка тапов по краям экрана
  Offset? _downPosition;
  DateTime? _downTime;
  Timer? _tapTimer;
  bool _selectionActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveProgress(); // AC 2.4: закрытие экрана
    _tapTimer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // AC 2.4: сворачивание приложения
    if (state != AppLifecycleState.resumed) _saveProgress();
  }

  Future<_ReaderData> _load() async {
    final bytes = await File(widget.filePath).readAsBytes();
    final chapters = await parseEpubInBackground(bytes);
    final progress = await _progressService.load(widget.book.id);
    return _ReaderData(chapters, progress);
  }

  // ---------------------------------------------------------------- прогресс

  void _saveProgress() {
    if (_pages.isEmpty) return;
    final page = _currentPage.clamp(0, _pages.length - 1);
    final f = _pages[page].first;
    _progressService.save(
      widget.book.id,
      ReadingProgress(
        chapterIndex: f.chapterIndex,
        paragraphIndex: f.paragraphIndex,
        charOffset: f.start,
        percent: (page + 1) / _pages.length,
        updatedAt: DateTime.now(),
      ),
    );
  }

  // ---------------------------------------------------------------- разметка

  TextStyle _textStyle(BuildContext context) => DefaultTextStyle.of(context)
      .style
      .merge(Theme.of(context).textTheme.bodyLarge)
      .copyWith(fontSize: 18, height: 1.5);

  /// Пересчитывает страницы, если поменялся размер области или масштаб шрифта.
  /// Позиция в тексте при этом сохраняется (AC 2.1).
  void _ensurePaginated(
    BuildContext context,
    BoxConstraints constraints,
    _ReaderData data,
  ) {
    final scaler = MediaQuery.textScalerOf(context);
    final width = constraints.maxWidth - _pagePadding.horizontal;
    final height = constraints.maxHeight - _pagePadding.vertical - 4;
    final key = '${width.round()}x${height.round()}@${scaler.scale(18)}';
    if (key == _layoutKey) return;

    // Что сейчас на экране — туда и вернёмся после пересчёта
    int chapter = 0, paragraph = 0, offset = 0;
    if (_pages.isNotEmpty) {
      final f = _pages[_currentPage.clamp(0, _pages.length - 1)].first;
      chapter = f.chapterIndex;
      paragraph = f.paragraphIndex;
      offset = f.start;
    } else if (data.progress != null) {
      chapter = data.progress!.chapterIndex;
      paragraph = data.progress!.paragraphIndex;
      offset = data.progress!.charOffset;
    }

    _chapters = data.chapters;
    _layoutKey = key;
    _pages = paginate(
      _chapters,
      maxWidth: width,
      maxHeight: height,
      style: _textStyle(context),
      textScaler: scaler,
      paragraphSpacing: _paragraphSpacing,
    );
    if (_pages.isEmpty) return;

    final target = pageForPosition(
      _pages,
      chapterIndex: chapter,
      paragraphIndex: paragraph,
      charOffset: offset,
    );
    _currentPage = target;

    if (_pageController == null) {
      _pageController = PageController(initialPage: target);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController?.hasClients ?? false) {
          _pageController!.jumpToPage(target);
        }
      });
    }
  }

  // ---------------------------------------------------------------- навигация

  void _turnPage(int direction) {
    final target = _currentPage + direction;
    if (target < 0 || target >= _pages.length) return;
    _pageController?.animateToPage(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _onPointerDown(PointerDownEvent e) {
    // Второй тап подряд — это двойной тап (выделение слова), не листаем
    _tapTimer?.cancel();
    _downPosition = e.localPosition;
    _downTime = DateTime.now();
  }

  void _onPointerUp(PointerUpEvent e, double width) {
    final down = _downPosition;
    final time = _downTime;
    _downPosition = null;
    if (down == null || time == null) return;

    final isTap =
        (e.localPosition - down).distance < 18 &&
        DateTime.now().difference(time) < const Duration(milliseconds: 250);
    if (!isTap) return; // свайп или долгое нажатие

    // Тап при активном выделении только снимает его
    if (_selectionActive) {
      _selectionActive = false;
      return;
    }

    final x = e.localPosition.dx;
    final direction = x < width * _tapZone
        ? -1
        : x > width * (1 - _tapZone)
        ? 1
        : 0;
    if (direction == 0) return;

    _tapTimer = Timer(kDoubleTapTimeout, () => _turnPage(direction));
  }

  // ---------------------------------------------------------------- AI

  void _explain(String selected, String paragraph) {
    showAiExplainSheet(
      context,
      AiExplainRequest(
        selectedText: selected,
        context: paragraph,
        bookTitle: widget.book.title,
      ),
    );
  }

  // ---------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final chapterTitle = _pages.isEmpty
        ? widget.book.title
        : _chapters[_pages[_currentPage].chapterIndex].title;

    return Scaffold(
      appBar: AppBar(
        title: Text(chapterTitle, overflow: TextOverflow.ellipsis),
      ),
      body: FutureBuilder<_ReaderData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Не удалось открыть книгу: файл повреждён или удалён',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.chapters.isEmpty) {
            return const Center(child: Text('В книге не найден текст'));
          }
          return _buildReader(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildReader(_ReaderData data) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final hadPages = _pages.isNotEmpty;
              _ensurePaginated(context, constraints, data);
              if (!hadPages && _pages.isNotEmpty) {
                // Обновить заголовок главы в AppBar после первой разметки
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() {});
                });
              }
              if (_pages.isEmpty) {
                return const Center(child: Text('В книге не найден текст'));
              }

              return Listener(
                onPointerDown: _onPointerDown,
                onPointerUp: (e) => _onPointerUp(e, constraints.maxWidth),
                onPointerCancel: (_) => _downPosition = null,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (page) {
                    setState(() => _currentPage = page);
                    _selectionActive = false;
                    _saveProgress();
                  },
                  itemBuilder: (context, index) =>
                      _buildPage(context, _pages[index]),
                ),
              );
            },
          ),
        ),
        // Всегда в дереве, чтобы высота области текста не менялась
        _buildProgressBar(context),
      ],
    );
  }

  Widget _buildPage(BuildContext context, ReaderPage page) {
    final chapter = _chapters[page.chapterIndex];
    final style = _textStyle(context);

    return Padding(
      padding: _pagePadding,
      // Скролл отключён: он только страхует от переполнения на пиксель-два
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < page.fragments.length; i++) ...[
              if (i > 0) const SizedBox(height: _paragraphSpacing),
              Builder(
                builder: (context) {
                  final f = page.fragments[i];
                  final paragraph = chapter.paragraphs[f.paragraphIndex];
                  return SelectableParagraph(
                    text: paragraph.substring(f.start, f.end),
                    style: style,
                    onSelectionActive: (active) => _selectionActive = active,
                    onExplain: (selected) => _explain(selected, paragraph),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// AC 2.3: индикатор прогресса
  Widget _buildProgressBar(BuildContext context) {
    final theme = Theme.of(context);
    final total = _pages.isEmpty ? 1 : _pages.length;
    final page = _pages.isEmpty ? 0 : _currentPage + 1;
    final percent = (page / total * 100).round();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: page / total, minHeight: 2),
            const SizedBox(height: 6),
            Text(
              'Стр. $page из $total · $percent%',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
