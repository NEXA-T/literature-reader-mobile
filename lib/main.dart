import 'package:flutter/material.dart';

import 'screens/library_screen.dart';

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
      home: const LibraryScreen(),
    );
  }
}
