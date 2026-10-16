import 'package:flutter/material.dart';

/// Три темы читалки из макета Figma (страница Design System → «Палитра»).
enum ReaderTheme { light, sepia, dark }

/// Цвета приложения. Названия совпадают с переменными в Figma
/// (light/bg, light/surface, …), чтобы дизайн и код говорили на одном языке.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.text,
    required this.textSecondary,
    required this.accent,
    required this.accentStrong,
    required this.onAccent,
    required this.highlight,
    required this.divider,
    required this.skeleton,
    required this.error,
    required this.errorBg,
    required this.chipText,
    required this.controlBg,
  });

  final Color bg;
  final Color surface;
  final Color text;
  final Color textSecondary;
  final Color accent;
  final Color accentStrong;
  final Color onAccent;
  final Color highlight;
  final Color divider;
  final Color skeleton;
  final Color error;
  final Color errorBg;
  final Color chipText;
  final Color controlBg;

  static const light = AppColors(
    bg: Color(0xFFF5F8F7),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF1F2E36),
    textSecondary: Color(0xFF5B6B70),
    accent: Color(0xFF7FA396),
    accentStrong: Color(0xFF4F7A6C),
    onAccent: Color(0xFFFFFFFF),
    highlight: Color(0xFFCFE3DA),
    divider: Color(0xFFDCE3E1),
    skeleton: Color(0xFFE6ECEA),
    error: Color(0xFFB3463C),
    errorBg: Color(0xFFF6E3E0),
    chipText: Color(0xFF2F5447),
    controlBg: Color(0xFFEEF2F1),
  );

  static const sepia = AppColors(
    bg: Color(0xFFF4ECD8),
    surface: Color(0xFFFBF6EA),
    text: Color(0xFF3B3226),
    textSecondary: Color(0xFF7A6A55),
    accent: Color(0xFF8FA38A),
    accentStrong: Color(0xFF5E7A62),
    onAccent: Color(0xFFFBF6EA),
    highlight: Color(0xFFE2D3AE),
    divider: Color(0xFFE3D6BA),
    skeleton: Color(0xFFEADFC6),
    error: Color(0xFFA9473A),
    errorBg: Color(0xFFF1DDD3),
    chipText: Color(0xFF4A5C45),
    controlBg: Color(0xFFEFE5CF),
  );

  static const dark = AppColors(
    bg: Color(0xFF1C2326),
    surface: Color(0xFF2A3337),
    text: Color(0xFFD3DBD8),
    textSecondary: Color(0xFF8E9C98),
    accent: Color(0xFF8FB5A7),
    accentStrong: Color(0xFF8FB5A7),
    onAccent: Color(0xFF1C2326),
    highlight: Color(0xFF33493F),
    divider: Color(0xFF36423F),
    skeleton: Color(0xFF36423F),
    error: Color(0xFFE08A80),
    errorBg: Color(0xFF4A2E2B),
    chipText: Color(0xFFB5D2C7),
    controlBg: Color(0xFF222B2E),
  );

  static AppColors of(ReaderTheme theme) => switch (theme) {
        ReaderTheme.light => light,
        ReaderTheme.sepia => sepia,
        ReaderTheme.dark => dark,
      };

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? text,
    Color? textSecondary,
    Color? accent,
    Color? accentStrong,
    Color? onAccent,
    Color? highlight,
    Color? divider,
    Color? skeleton,
    Color? error,
    Color? errorBg,
    Color? chipText,
    Color? controlBg,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      accent: accent ?? this.accent,
      accentStrong: accentStrong ?? this.accentStrong,
      onAccent: onAccent ?? this.onAccent,
      highlight: highlight ?? this.highlight,
      divider: divider ?? this.divider,
      skeleton: skeleton ?? this.skeleton,
      error: error ?? this.error,
      errorBg: errorBg ?? this.errorBg,
      chipText: chipText ?? this.chipText,
      controlBg: controlBg ?? this.controlBg,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      text: l(text, other.text),
      textSecondary: l(textSecondary, other.textSecondary),
      accent: l(accent, other.accent),
      accentStrong: l(accentStrong, other.accentStrong),
      onAccent: l(onAccent, other.onAccent),
      highlight: l(highlight, other.highlight),
      divider: l(divider, other.divider),
      skeleton: l(skeleton, other.skeleton),
      error: l(error, other.error),
      errorBg: l(errorBg, other.errorBg),
      chipText: l(chipText, other.chipText),
      controlBg: l(controlBg, other.controlBg),
    );
  }
}

/// Короткий доступ к цветам: `context.colors.text`.
extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
