import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../debug/debug_analysis.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Кнопка выбора темы: светлая / сепия / тёмная.
///
/// В режиме отладки (`flutter run`) в этом же меню есть разделы
/// «Отладка · ответ AI» и «Отладка · иллюстрация»: они подменяют ответ
/// сервера и генерацию картинки, чтобы проверить и заснять все состояния
/// шторки. Пока подмена включена, на иконке горит точка.
/// В релизной сборке этих разделов нет.
class ThemeMenuButton extends StatelessWidget {
  const ThemeMenuButton({super.key});

  static const _names = {
    ReaderTheme.light: 'Светлая',
    ReaderTheme.sepia: 'Сепия',
    ReaderTheme.dark: 'Тёмная',
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([debugAnalysisMode, debugIllustrationMode]),
      builder: (context, _) => _buildMenu(context),
    );
  }

  Widget _buildMenu(BuildContext context) {
    final c = context.colors;
    final debugActive = kDebugMode &&
        (debugAnalysisMode.value != DebugAnalysisMode.off ||
            debugIllustrationMode.value != DebugIllustrationMode.off);

    PopupMenuEntry<Object> header(String text) => PopupMenuItem<Object>(
          enabled: false,
          height: 32,
          child: Text(
            text,
            style: AppText.label.copyWith(color: c.textSecondary),
          ),
        );

    PopupMenuEntry<Object> option(Object value, String label, bool selected) =>
        PopupMenuItem<Object>(
          value: value,
          height: 40,
          child: Row(
            children: [
              SizedBox(
                width: 22,
                child: selected
                    ? Icon(Icons.check_rounded, size: 18, color: c.accent)
                    : null,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(label, style: AppText.body.copyWith(color: c.text)),
              ),
            ],
          ),
        );

    return PopupMenuButton<Object>(
      tooltip: 'Тема',
      icon: Badge(
        isLabelVisible: debugActive,
        smallSize: 8,
        backgroundColor: c.error,
        child: Icon(Icons.palette_outlined, color: c.text),
      ),
      color: c.surface,
      initialValue: readerThemeNotifier.value,
      onSelected: (value) {
        if (value is ReaderTheme) readerThemeNotifier.value = value;
        if (value is DebugAnalysisMode) debugAnalysisMode.value = value;
        if (value is DebugIllustrationMode) {
          debugIllustrationMode.value = value;
        }
      },
      itemBuilder: (_) => [
        for (final t in ReaderTheme.values)
          PopupMenuItem<Object>(
            value: t,
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.of(t).bg,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.divider),
                  ),
                ),
                const SizedBox(width: 12),
                Text(_names[t]!, style: AppText.body.copyWith(color: c.text)),
              ],
            ),
          ),
        if (kDebugMode) ...[
          const PopupMenuDivider(),
          header('ОТЛАДКА · ОТВЕТ AI'),
          for (final mode in DebugAnalysisMode.values)
            option(mode, mode.label, mode == debugAnalysisMode.value),
          const PopupMenuDivider(),
          header('ОТЛАДКА · ИЛЛЮСТРАЦИЯ'),
          for (final mode in DebugIllustrationMode.values)
            option(mode, mode.label, mode == debugIllustrationMode.value),
        ],
      ],
    );
  }
}
