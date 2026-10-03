import 'package:flutter/material.dart';

import 'poc/epub_reader_page.dart';

void main() {
  runApp(const LiteratureReaderApp());
}

class LiteratureReaderApp extends StatelessWidget {
  const LiteratureReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Literature Reader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const EpubReaderPage(),
    );
  }
}
