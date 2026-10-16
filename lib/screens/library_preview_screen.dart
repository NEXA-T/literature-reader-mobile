import 'package:flutter/material.dart';

import '../mock/mock_books.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/book_widgets.dart';
import '../widgets/theme_menu_button.dart';
import 'reader_demo_screen.dart';

/// Вёрстка экрана «Библиотека» по макету Figma со статичными тестовыми
/// данными. Логика загрузки EPUB живёт в ветке feature/file-storage —
/// после её слияния сюда подставляется настоящий список книг.
class LibraryPreviewScreen extends StatelessWidget {
  const LibraryPreviewScreen({super.key, this.books = mockBooks});

  final List<LibraryBookPreview> books;

  void _openBook(BuildContext context, LibraryBookPreview book) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ReaderDemoScreen(book: book)),
    );
  }

  void _addBook(BuildContext context) {
    // AC 1.1: кнопка есть и видна. Выбор файла (AC 1.2) подключится
    // вместе с BookStorageService из feature/file-storage.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Здесь откроется выбор файла .epub')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Моя библиотека'),
        actions: [
          IconButton(
            tooltip: 'Поиск',
            onPressed: () {},
            icon: Icon(Icons.search_rounded, color: c.text),
          ),
          const ThemeMenuButton(),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addBook(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Добавить книгу'),
      ),
      body: books.isEmpty
          ? const _EmptyLibrary()
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SectionTitle('Продолжить чтение'),
                        const SizedBox(height: 10),
                        ContinueReadingCard(
                          book: books.first,
                          onTap: () => _openBook(context, books.first),
                        ),
                        const SizedBox(height: 28),
                        _SectionTitle('Все книги · ${books.length}'),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
                SliverList.separated(
                  itemCount: books.length,
                  itemBuilder: (context, i) => BookListTile(
                    book: books[i],
                    onTap: () => _openBook(context, books[i]),
                  ),
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
      text,
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
