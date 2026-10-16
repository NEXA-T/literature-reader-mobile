import 'package:flutter/material.dart';

import 'ai_explain_request.dart';

/// Точка входа в шторку «Объяснить с AI».
///
/// Экран чтения вызывает только эту функцию. Когда компонент шторки
/// от Вероники попадёт в develop, достаточно заменить содержимое
/// [_AiExplainSheetPlaceholder] (или вызвать её компонент здесь) —
/// экран чтения менять не придётся.
Future<void> showAiExplainSheet(
  BuildContext context,
  AiExplainRequest request,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _AiExplainSheetPlaceholder(request: request),
  );
}

/// Временная шторка: показывает переданные данные и состояние загрузки.
class _AiExplainSheetPlaceholder extends StatelessWidget {
  const _AiExplainSheetPlaceholder({required this.request});

  final AiExplainRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Объяснить с AI', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              Text('Выделено', style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(
                '«${request.selectedText}»',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Контекст · ${request.bookTitle}',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(
                request.context,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Готовим объяснение…'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
