import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/reading_progress.dart';

class ReadingProgressService {
  static String _key(String bookId) => 'reading_progress_$bookId';

  Future<ReadingProgress?> load(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(bookId));
    if (raw == null) return null;
    try {
      return ReadingProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null; // повреждённая запись — откроем книгу с начала
    }
  }

  Future<void> save(String bookId, ReadingProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(bookId), jsonEncode(progress.toJson()));
  }
}
