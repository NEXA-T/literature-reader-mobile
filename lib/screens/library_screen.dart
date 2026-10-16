import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../models/book.dart';
import '../services/book_storage_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _storage = BookStorageService();
  List<Book> _books = [];
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
    if (!mounted) return;
    setState(() {
      _books = books;
      _booksDirPath = dir.path;
      _loading = false;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Библиотека')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _importing ? null : _addBook,
        icon: _importing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add),
        label: const Text('Добавить книгу'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _books.isEmpty
          ? const Center(child: Text('Библиотека пуста. Добавьте .epub-файл'))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: _books.length,
              itemBuilder: (context, i) => _buildBookCard(_books[i]),
            ),
    );
  }

  Widget _buildBookCard(Book book) {
    final coverPath = book.coverFileName != null && _booksDirPath != null
        ? p.join(_booksDirPath!, book.coverFileName!)
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: SizedBox(
          width: 40,
          height: 56,
          child: coverPath != null
              ? Image.file(File(coverPath), fit: BoxFit.cover)
              : const Icon(Icons.menu_book, size: 36),
        ),
        title: Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(book.author),
      ),
    );
  }
}
