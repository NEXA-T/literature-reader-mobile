import 'package:flutter/material.dart';

/// Кусок абзаца с поддержкой выделения текста.
class SelectableParagraph extends StatelessWidget {
  const SelectableParagraph({
    super.key,
    required this.text,
    required this.style,
    required this.onSelectionChanged,
  });

  final String text;
  final TextStyle style;
  final ValueChanged<String> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      text,
      style: style,
      onSelectionChanged: (selection, _) {
        if (!selection.isValid || selection.isCollapsed) {
          onSelectionChanged('');
          return;
        }

        onSelectionChanged(selection.textInside(text).trim());
      },
    );
  }
}
