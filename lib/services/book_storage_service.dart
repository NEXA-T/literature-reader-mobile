import 'dart:convert';
import 'dart:io';

import 'package:epubx/epubx.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/book.dart';

class BookImportException implements Exception {
  final String message;
  BookImportException(this.message);
}

class BookStorageService {
  static const _prefsKey = 'library_books';

  /// Постоянная папка для книг: `documents/books`
  Future<Directory> booksDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'books'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<List<Book>> loadBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    final dir = await booksDir();

    return raw
        .map((s) => Book.fromJson(jsonDecode(s) as Map<String, dynamic>))
        // убираем записи, у которых файл пропал
        .where((b) => File(p.join(dir.path, b.fileName)).existsSync())
        .toList();
  }

  Future<void> _saveBooks(List<Book> books) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      books.map((b) => jsonEncode(b.toJson())).toList(),
    );
  }

  /// Возвращает null, если пользователь закрыл проводник без выбора.
  Future<Book?> pickAndImportBook() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub'],
    );
    if (files.isEmpty) return null; // пользователь закрыл проводник

    final picked = files.first;

    // На некоторых Android фильтр по расширению работает неидеально,
    // поэтому проверяем ещё раз сами
    if (p.extension(picked.name).toLowerCase() != '.epub') {
      throw BookImportException('Можно загрузить только файлы формата .epub');
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final dir = await booksDir();
    final fileName = '$id.epub';
    final dest = File(p.join(dir.path, fileName));
    await dest.writeAsBytes(await picked.readAsBytes());

    try {
      final epub = await EpubReader.readBook(await dest.readAsBytes());

      String? coverFileName;
      final cover = epub.CoverImage;
      if (cover != null) {
        coverFileName = '$id.png';
        await File(p.join(dir.path, coverFileName))
            .writeAsBytes(img.encodePng(cover));
      }

      final title = (epub.Title?.trim().isNotEmpty ?? false)
          ? epub.Title!.trim()
          : p.basenameWithoutExtension(picked.name);
      final author = (epub.Author?.trim().isNotEmpty ?? false)
          ? epub.Author!.trim()
          : 'Неизвестный автор';

      final book = Book(
        id: id,
        title: title,
        author: author,
        fileName: fileName,
        coverFileName: coverFileName,
        addedAt: DateTime.now(),
      );

      final books = await loadBooks();
      books.add(book);
      await _saveBooks(books);
      return book;
    } catch (_) {
      // Файл битый: удаляем копию, чтобы не копился мусор (AC 1.4)
      if (await dest.exists()) await dest.delete();
      throw BookImportException(
        'Не удалось открыть книгу: файл повреждён или не является EPUB',
      );
    }
  }
}
