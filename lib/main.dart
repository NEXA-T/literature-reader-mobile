import 'package:flutter/material.dart';

import 'screens/library_screen.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const LiteratureReaderApp());
}

class LiteratureReaderApp extends StatelessWidget {
  const LiteratureReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Тема (светлая / сепия / тёмная) из макета Figma, экран — настоящая
    // библиотека с загрузкой EPUB.
    return ValueListenableBuilder<ReaderTheme>(
      valueListenable: readerThemeNotifier,
      builder: (context, readerTheme, _) => MaterialApp(
        title: 'Literature Reader',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(readerTheme),
        home: const LibraryScreen(),
      ),
    );
  }
}