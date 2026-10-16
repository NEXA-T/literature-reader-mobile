import 'package:flutter/material.dart';

import '../mock/mock_books.dart';
import '../services/mock_analysis_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/analysis_sheet.dart';
import '../widgets/book_widgets.dart';
import '../widgets/theme_menu_button.dart';

/// Демо-экран для проверки шторки разбора. Настоящая читалка
/// (листание страниц EPUB) делается отдельно — см. lib/poc/.
///
/// Как пользоваться:
/// • долгим нажатием выделите фразу → в меню «AI-анализ»;
/// • или нажмите кнопку внизу — разберётся «as dead as a door-nail».
/// Переключатель «Сценарий» показывает все состояния шторки.
class ReaderDemoScreen extends StatefulWidget {
  const ReaderDemoScreen({super.key, required this.book});

  final LibraryBookPreview book;

  @override
  State<ReaderDemoScreen> createState() => _ReaderDemoScreenState();
}

class _ReaderDemoScreenState extends State<ReaderDemoScreen> {
  final _service = MockAnalysisService();

  static const _paragraphs = [
    'Marley was dead: to begin with. There is no doubt whatever about that. '
        'The register of his burial was signed by the clergyman, the clerk, '
        'the undertaker, and the chief mourner. Scrooge signed it: and '
        'Scrooge’s name was good upon ’Change, for anything he chose to put '
        'his hand to. Old Marley was as dead as a door-nail.',
    'Mind! I don’t mean to say that I know, of my own knowledge, what there '
        'is particularly dead about a door-nail. I might have been inclined, '
        'myself, to regard a coffin-nail as the deadliest piece of '
        'ironmongery in the trade.',
    'Scrooge knew he was dead? Of course he did. How could it be otherwise? '
        'Scrooge and he were partners for I don’t know how many years.',
  ];

  static const _demoPhrase = 'as dead as a door-nail';

  void _analyze(String selected, String paragraph) {
    final text = selected.trim();
    if (text.isEmpty) return;
    var attempt = 0;
    showAnalysisSheet(
      context,
      fragment: text,
      // AC 3.3: уходит фраза, её абзац и название книги.
      fetch: () => _service.analyze(
        selectedText: text,
        context: paragraph,
        bookTitle: widget.book.title,
        // Для демо: после ошибки «Повторить» уже срабатывает успешно.
        override: attempt++ == 0 ? null : MockScenario.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Stave One · Marley’s Ghost',
          style: AppText.bodyStrong.copyWith(color: c.text),
        ),
        centerTitle: true,
        actions: const [ThemeMenuButton(), SizedBox(width: 4)],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(38),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Column(
              children: [
                ReadingProgressBar(value: widget.book.progress),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'стр. 190 из 380',
                      style: AppText.caption.copyWith(color: c.textSecondary),
                    ),
                    Text(
                      progressLabel(widget.book.progress),
                      style: AppText.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        children: [
          for (final p in _paragraphs)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SelectableText(
                p,
                style: AppText.bookBody.copyWith(color: c.text),
                contextMenuBuilder: (context, editable) {
                  final value = editable.textEditingValue;
                  final selected = value.selection.textInside(value.text);
                  return AdaptiveTextSelectionToolbar.buttonItems(
                    anchors: editable.contextMenuAnchors,
                    buttonItems: [
                      ContextMenuButtonItem(
                        label: 'Скопировать',
                        onPressed: () => editable.copySelection(
                          SelectionChangedCause.toolbar,
                        ),
                      ),
                      ContextMenuButtonItem(
                        label: 'AI-анализ',
                        onPressed: () {
                          ContextMenuController.removeAny();
                          _analyze(selected, p);
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: _DemoPanel(
        scenario: _service.scenario,
        onScenario: (s) => setState(() => _service.scenario = s),
        onAnalyze: () => _analyze(_demoPhrase, _paragraphs.first),
      ),
    );
  }
}

/// Панель только для демо: выбор ответа заглушки и быстрый запуск шторки.
class _DemoPanel extends StatelessWidget {
  const _DemoPanel({
    required this.scenario,
    required this.onScenario,
    required this.onAnalyze,
  });

  final MockScenario scenario;
  final ValueChanged<MockScenario> onScenario;
  final VoidCallback onAnalyze;

  static const _labels = {
    MockScenario.success: 'Успех',
    MockScenario.successNoSlang: 'Без сленга',
    MockScenario.offline: 'Нет сети',
    MockScenario.serverError: 'Сбой сервера',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ДЕМО · ОТВЕТ СЕРВЕРА',
                style: AppText.label.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in MockScenario.values)
                    ChoiceChip(
                      label: Text(_labels[s]!),
                      selected: s == scenario,
                      onSelected: (_) => onScenario(s),
                      showCheckmark: false,
                      labelStyle: AppText.caption.copyWith(
                        color: s == scenario ? c.chipText : c.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      selectedColor: c.highlight,
                      backgroundColor: c.controlBg,
                      side: BorderSide.none,
                      shape: const StadiumBorder(),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: onAnalyze,
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('AI-анализ «as dead as a door-nail»'),
                style: FilledButton.styleFrom(
                  backgroundColor: c.accentStrong,
                  foregroundColor: c.onAccent,
                  textStyle: AppText.button,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
