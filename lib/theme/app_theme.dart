import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Текстовые стили из макета Figma (Design System → «Типографика»).
/// Цвет здесь не задаётся — он приходит из темы или указывается на месте.
abstract final class AppText {
  static const bookBody = TextStyle(
    fontFamily: 'Literata',
    fontSize: 18,
    height: 1.6,
  );
  static const bookQuote = TextStyle(
    fontFamily: 'Literata',
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 1.35,
  );
  static const title = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 20,
    height: 1.3,
  );
  static const body = TextStyle(fontFamily: 'Inter', fontSize: 15, height: 1.5);
  static const bodyStrong = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 1.5,
  );
  static const label = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 12,
    height: 1.4,
    letterSpacing: 0.5,
  );
  static const button = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 1.4,
  );
  static const caption = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    height: 1.4,
  );
}

ThemeData buildAppTheme(ReaderTheme readerTheme) {
  final c = AppColors.of(readerTheme);
  final brightness =
      readerTheme == ReaderTheme.dark ? Brightness.dark : Brightness.light;

  final scheme = ColorScheme.fromSeed(
    seedColor: c.accentStrong,
    brightness: brightness,
  ).copyWith(
    primary: c.accentStrong,
    onPrimary: c.onAccent,
    surface: c.bg,
    onSurface: c.text,
    onSurfaceVariant: c.textSecondary,
    error: c.error,
    outlineVariant: c.divider,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: c.bg,
    extensions: [c],
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: AppText.title.copyWith(color: c.text),
    ),
    dividerTheme: DividerThemeData(color: c.divider, space: 1, thickness: 1),
    textSelectionTheme: TextSelectionThemeData(
      selectionColor: c.highlight,
      selectionHandleColor: c.accentStrong,
      cursorColor: c.accentStrong,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: c.accentStrong,
      foregroundColor: c.onAccent,
      extendedTextStyle: AppText.button,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.text,
      contentTextStyle: AppText.body.copyWith(color: c.bg),
    ),
  );
}

/// Текущая тема читалки на всё приложение. Позже её можно будет
/// сохранять в настройках (shared_preferences).
final readerThemeNotifier = ValueNotifier<ReaderTheme>(ReaderTheme.light);
