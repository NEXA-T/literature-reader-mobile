import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../debug/debug_analysis.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Кнопка выбора темы: светлая / сепия / тёмная.
///
/// В режиме отладки (`flutter run`) в этом же меню есть раздел
/// «Отладка · ответ AI»: он подменяет ответ сервера, чтобы проверить
/// и заснять все состояния шторки. Пока подмена включена, на иконке
/// горит точка. В релизной сборке раздела нет.
class ThemeMenuButton extends StatelessWidget {
  const ThemeMenuButton({super.key});

  static const _names = {
    ReaderTheme.light: 'Светлая',
    ReaderTheme.sepia: 'Сепия',
    ReaderTheme.dark: 'Тёмная',
  };

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DebugAnalysisMode>(
      valueListenable: debugAnalysisMode,
      builder: (context, debugMode, _) => _buildMenu(context, debugMode),
    );
  }

  Widget _buildMenu(BuildContext context, DebugAnalysisMode debugMode) {
    final c = context.colors;
    final debugActive = kDebugMode && debugMode != DebugAnalysisMode.off;

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
          PopupMenuItem<Object>(
            enabled: false,
            height: 32,
            child: Text(
              'ОТЛАДКА · ОТВЕТ AI',
              style: AppText.label.copyWith(color: c.textSecondary),
            ),
          ),
          for (final mode in DebugAnalysisMode.values)
            PopupMenuItem<Object>(
              value: mode,
              height: 40,
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: mode == debugMode
                        ? Icon(Icons.check_rounded, size: 18, color: c.accent)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      mode.label,
                      style: AppText.body.copyWith(color: c.text),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
