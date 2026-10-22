import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_analysis.dart';

/// Локальная история AI-разборов (задача #15).
///
/// Хранится в shared_preferences — там же, где библиотека и прогресс.
/// Работает без интернета, поэтому сохранённый разбор открывается
/// мгновенно и офлайн.
class AnalysisCacheService {
  static const _prefsKey = 'saved_analyses';

  /// Чтобы хранилище не росло бесконечно, старые разборы вытесняются
  static const maxEntries = 500;

  Future<List<SavedAnalysis>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? const <String>[];
    final result = <SavedAnalysis>[];
    for (final s in raw) {
      try {
        result.add(SavedAnalysis.fromJson(jsonDecode(s) as Map<String, dynamic>));
      } catch (e) {
        debugPrint('[AI cache] пропущена повреждённая запись: $e');
      }
    }
    return result;
  }

  /// Готовый разбор той же фразы в той же главе той же книги, если есть.
  Future<SavedAnalysis?> find({
    required String bookId,
    required int chapterIndex,
    required String selectedText,
  }) async {
    final key = SavedAnalysis.makeKey(bookId, chapterIndex, selectedText);
    for (final item in await loadAll()) {
      if (item.key == key) return item;
    }
    return null;
  }

  /// Сохраняет разбор; если такой уже был — заменяет и поднимает наверх.
  Future<void> save(SavedAnalysis entry) async {
    final items = await loadAll()
      ..removeWhere((e) => e.key == entry.key)
      ..insert(0, entry);
    if (items.length > maxEntries) items.removeRange(maxEntries, items.length);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      items.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }
}
