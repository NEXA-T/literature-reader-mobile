import 'package:flutter/material.dart';

/// Карточка книги для вёрстки библиотеки. Пока это статичные тестовые данные;
/// когда влетит ветка feature/file-storage, сюда придут поля модели Book
/// (title, author, обложка) + прогресс чтения из локальной базы.
class LibraryBookPreview {
  const LibraryBookPreview({
    required this.title,
    required this.author,
    required this.progress,
    required this.coverColor,
    this.cover,
  });

  final String title;
  final String author;

  /// 0.0 — книга не начата, 1.0 — прочитана.
  final double progress;

  /// Цвет сгенерированной обложки, если в EPUB своей нет.
  final Color coverColor;

  /// Настоящая обложка из EPUB (позже — FileImage).
  final ImageProvider? cover;
}

const mockBooks = <LibraryBookPreview>[
  LibraryBookPreview(
    title: 'A Christmas Carol',
    author: 'Charles Dickens',
    progress: 0.5,
    coverColor: Color(0xFF4F7A6C),
  ),
  LibraryBookPreview(
    title: 'Pride and Prejudice',
    author: 'Jane Austen',
    progress: 0.12,
    coverColor: Color(0xFF9A6A55),
  ),
  LibraryBookPreview(
    title: "Alice's Adventures in Wonderland",
    author: 'Lewis Carroll',
    progress: 0.83,
    coverColor: Color(0xFF5A6F93),
  ),
  LibraryBookPreview(
    title: 'The Picture of Dorian Gray',
    author: 'Oscar Wilde',
    progress: 0,
    coverColor: Color(0xFF7A5A7E),
  ),
  LibraryBookPreview(
    title: 'The Hound of the Baskervilles',
    author: 'Arthur Conan Doyle',
    progress: 0.3,
    coverColor: Color(0xFF3E4F55),
  ),
  LibraryBookPreview(
    title: 'The Adventures of Tom Sawyer',
    author: 'Mark Twain',
    progress: 1,
    coverColor: Color(0xFFA4863F),
  ),
];
