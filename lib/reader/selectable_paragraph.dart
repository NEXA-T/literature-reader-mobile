import 'package:flutter/material.dart';

/// Кусок абзаца с выделением по долгому нажатию (AC 3.1) и пунктом
/// «Объяснить с AI» в контекстном меню (AC 3.2).
class SelectableParagraph extends StatelessWidget {
  const SelectableParagraph({
    super.key,
    required this.text,
    required this.style,
    required this.onExplain,
    required this.onSelectionActive,
  });

  final String text;
  final TextStyle style;

  /// Вызывается с выделенным текстом по нажатию «Объяснить с AI»
  final ValueChanged<String> onExplain;

  /// true — есть выделение, false — выделение снято
  final ValueChanged<bool> onSelectionActive;

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      text,
      style: style,
      onSelectionChanged: (selection, _) =>
          onSelectionActive(!selection.isCollapsed),
      contextMenuBuilder: (context, editableTextState) {
        final value = editableTextState.textEditingValue;
        final selected = value.selection.textInside(value.text).trim();
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: editableTextState.contextMenuAnchors,
          buttonItems: [
            if (selected.isNotEmpty)
              ContextMenuButtonItem(
                label: 'Объяснить с AI',
                onPressed: () {
                  editableTextState.hideToolbar();
                  onExplain(selected);
                },
              ),
            ...editableTextState.contextMenuButtonItems,
          ],
        );
      },
    );
  }
}
