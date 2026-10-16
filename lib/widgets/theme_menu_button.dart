import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Кнопка выбора темы: светлая / сепия / тёмная.
class ThemeMenuButton extends StatelessWidget {
  const ThemeMenuButton({super.key});

  static const _names = {
    ReaderTheme.light: 'Светлая',
    ReaderTheme.sepia: 'Сепия',
    ReaderTheme.dark: 'Тёмная',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PopupMenuButton<ReaderTheme>(
      tooltip: 'Тема',
      icon: Icon(Icons.palette_outlined, color: c.text),
      color: c.surface,
      initialValue: readerThemeNotifier.value,
      onSelected: (t) => readerThemeNotifier.value = t,
      itemBuilder: (_) => [
        for (final t in ReaderTheme.values)
          PopupMenuItem(
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
      ],
    );
  }
}
