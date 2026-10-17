import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../models/book.dart';
import '../models/reading_progress.dart';
import '../services/book_storage_service.dart';
import '../services/reading_progress_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/book_widgets.dart';
import '../widgets/theme_menu_button.dart';
import 'reader_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _storage = BookStorageService();
  final _progressService = ReadingProgressService();
  List<Book> _books = [];
  Map<String, ReadingProgress> _progress = {};
  String? _booksDirPath;
  bool _loading = true;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final books = await _storage.loadBooks();
    final dir = await _storage.booksDir();
    final progress = await _loadProgress(books);
    if (!mounted) return;
    setState(() {
      _books = books;
      _booksDirPath = dir.path;
      _progress = progress;
      _loading = false;
    });
  }

  Future<Map<String, ReadingProgress>> _loadProgress(List<Book> books) async {
    final result = <String, ReadingProgress>{};
    for (final book in books) {
      final progress = await _progressService.load(book.id);
      if (progress != null) result[book.id] = progress;
    }
    return result;
  }

  /// AC 2.1: по нажатию на карточку открывается экран чтения
  Future<void> _openBook(Book book) async {
    final dirPath = _booksDirPath ?? (await _storage.booksDir()).path;
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReaderScreen(
          book: book,
          filePath: p.join(dirPath, book.fileName),
        ),
      ),
    );
    // Обновляем процент прочитанного на карточках
    final progress = await _loadProgress(_books);
    if (mounted) setState(() => _progress = progress);
  }

  Future<void> _addBook() async {
    setState(() => _importing = true);
    try {
      final book = await _storage.pickAndImportBook();
      if (book == null || !mounted) return;
      setState(() => _books.add(book));
      _showMessage('Книга «${book.title}» добавлена');
    } on BookImportException catch (e) {
      _showMessage(e.message, isError: true);
    } catch (_) {
      _showMessage('Что-то пошло не так. Попробуйте ещё раз', isError: true);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  void _showMessage(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  /// Книга, которую читали последней, — для блока «Продолжить чтение».
  Book? get _lastRead {
    Book? best;
    DateTime? bestTime;
    for (final book in _books) {
      final t = _progress[book.id]?.updatedAt;
      if (t != null && (bestTime == null || t.isAfter(bestTime))) {
        best = book;
        bestTime = t;
      }
    }
    return best;
  }

  ImageProvider? _coverOf(Book book) {
    final dir = _booksDirPath;
    final name = book.coverFileName;
    if (dir == null || name == null) return null;
    return FileImage(File(p.join(dir, name)));
  }

  @override
  Widget build(BuildContext context) {
    final lastRead = _lastRead;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Моя библиотека'),
        actions: const [ThemeMenuButton(), SizedBox(width: 4)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _importing ? null : _addBook,
        icon: _importing
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.colors.onAccent,
                ),
              )
            : const Icon(Icons.add_rounded),
        label: const Text('Добавить книгу'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _books.isEmpty
          ? const _EmptyLibrary()
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (lastRead != null) ...[
                          const _SectionTitle('Продолжить чтение'),
                          const SizedBox(height: 10),
                          ContinueReadingCard(
                            title: lastRead.title,
                            author: lastRead.author,
                            progress: _progress[lastRead.id]?.percent,
                            cover: _coverOf(lastRead),
                            onTap: () => _openBook(lastRead),
                          ),
                          const SizedBox(height: 28),
                        ],
                        _SectionTitle('Все книги · ${_books.length}'),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
                SliverList.separated(
                  itemCount: _books.length,
                  itemBuilder: (context, i) {
                    final book = _books[i];
                    return BookListTile(
                      title: book.title,
                      author: book.author,
                      progress: _progress[book.id]?.percent,
                      cover: _coverOf(book),
                      onTap: () => _openBook(book),
                    );
                  },
                  separatorBuilder: (_, _) =>
                      const Divider(indent: 90, endIndent: 20),
                ),
                // Отступ, чтобы последняя книга не пряталась под кнопкой.
                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppText.label.copyWith(color: context.colors.textSecondary),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_stories_outlined, size: 56, color: c.accent),
            const SizedBox(height: 16),
            Text(
              'Здесь пока пусто',
              style: AppText.title.copyWith(color: c.text),
            ),
            const SizedBox(height: 6),
            Text(
              'Загрузите первую книгу в формате .epub',
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
