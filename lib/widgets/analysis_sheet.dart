import 'package:flutter/material.dart';

import '../debug/debug_analysis.dart';
import '../models/analysis_result.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'analysis_sheet_controller.dart';
import 'illustration_view.dart';
import 'shimmer.dart';

export 'analysis_sheet_controller.dart';

/// Открывает шторку AI-разбора поверх экрана чтения (задача #12).
///
/// [fragment] — выделенный текст, он показывается в шапке в кавычках.
/// [fetch] — запрос к бэкенду (см. [AnalysisFetcher]). Шторка сама
/// переключает состояния: Loading → Success или Error → «Повторить».
///
/// [loadIllustration] — загрузка картинки по `image_prompt` (см.
/// [IllustrationLoader]). Пока её не передали — в шторке пунктирная
/// заглушка «Здесь появится иллюстрация».
///
/// Закрывается свайпом вниз, тапом по затемнению или крестиком ✕;
/// экран чтения под ней не пересоздаётся, позиция не теряется.
Future<void> showAnalysisSheet(
  BuildContext context, {
  required String fragment,
  required AnalysisFetcher fetch,
  IllustrationLoader? loadIllustration,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.colors.surface,
    // Полупрозрачное затемнение текста книги под шторкой.
    barrierColor: Colors.black.withValues(alpha: 0.32),
    elevation: 0,
    // Скругление верхних углов 24dp — как в макете.
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    clipBehavior: Clip.antiAlias,
    // Плавный выезд снизу вверх.
    sheetAnimationStyle: AnimationStyle(
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 220),
    ),
    builder: (_) => _AnalysisSheetHost(
      fragment: fragment,
      fetch: applyDebugAnalysisMode(fetch),
      loadIllustration: applyDebugIllustrationMode(loadIllustration),
    ),
  );
}

/// Создаёт контроллер на время жизни шторки и отправляет первый запрос.
class _AnalysisSheetHost extends StatefulWidget {
  const _AnalysisSheetHost({
    required this.fragment,
    required this.fetch,
    required this.loadIllustration,
  });

  final String fragment;
  final AnalysisFetcher fetch;
  final IllustrationLoader? loadIllustration;

  @override
  State<_AnalysisSheetHost> createState() => _AnalysisSheetHostState();
}

class _AnalysisSheetHostState extends State<_AnalysisSheetHost> {
  late final AnalysisSheetController _controller =
      AnalysisSheetController(fetch: widget.fetch);

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AnalysisSheetState>(
      valueListenable: _controller,
      builder: (context, state, _) => AnalysisSheetView(
        fragment: widget.fragment,
        state: state,
        loadIllustration: widget.loadIllustration,
        onRetry: _controller.retry,
        onClose: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}

/// Сама шторка без логики: рисует нужное состояние.
/// Можно использовать отдельно, например в виджет-тестах.
class AnalysisSheetView extends StatelessWidget {
  const AnalysisSheetView({
    super.key,
    required this.fragment,
    required this.state,
    this.loadIllustration,
    required this.onRetry,
    required this.onClose,
  });

  final String fragment;
  final AnalysisSheetState state;
  final IllustrationLoader? loadIllustration;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    final Widget content = switch (state) {
      AnalysisLoading() => const _LoadingContent(key: ValueKey('loading')),
      AnalysisLoaded(:final result) => _ResultContent(
          key: const ValueKey('result'),
          result: result,
          loadIllustration: loadIllustration,
        ),
      AnalysisFailed() => _ErrorContent(
          key: const ValueKey('error'),
          onRetry: onRetry,
        ),
    };

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // «Ручка» — подсказка, что шторку можно смахнуть вниз.
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      '«${fragment.trim()}»',
                      style: AppText.bookQuote.copyWith(color: c.text),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  tooltip: 'Закрыть',
                  icon: Icon(Icons.close_rounded, color: c.textSecondary),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottomInset),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.topCenter,
                    children: [...previous, ?current],
                  ),
                  child: content,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Normal ─────────────────────────

class _ResultContent extends StatelessWidget {
  const _ResultContent({
    super.key,
    required this.result,
    required this.loadIllustration,
  });

  final AnalysisResult result;
  final IllustrationLoader? loadIllustration;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final slang = result.slangOrEtymology;
    final prompt = result.imagePrompt;

    // spacing — отступ только между блоками: если какой-то блок скрыт,
    // лишнего пустого места не остаётся.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 18,
      children: [
        _Section(
          icon: Icons.translate_rounded,
          label: 'Перевод',
          child: Text(
            result.translation,
            style: AppText.bodyStrong.copyWith(color: c.text),
          ),
        ),
        _Section(
          icon: Icons.menu_book_outlined,
          label: 'Смысловой контекст',
          child: Text(
            result.contextMeaning,
            style: AppText.body.copyWith(color: c.text),
          ),
        ),
        // Нет сленга — блока нет вовсе, без пустого места.
        if (slang != null)
          _Section(
            icon: Icons.history_edu_outlined,
            label: 'Этимология / сленг',
            child: Text(slang, style: AppText.body.copyWith(color: c.text)),
          ),
        // Сервер не придумал сцену (image_prompt = null) — рисовать нечего.
        if (prompt != null)
          _Section(
            icon: Icons.image_outlined,
            label: 'Иллюстрация',
            child: switch (loadIllustration) {
              final load? => IllustrationView(
                  key: ValueKey(prompt),
                  prompt: prompt,
                  load: load,
                ),
              null => const IllustrationPlaceholder(),
            },
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionLabel(icon: icon, label: label),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.textSecondary;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(label.toUpperCase(), style: AppText.label.copyWith(color: color)),
      ],
    );
  }
}

// ───────────────────────── Loading ─────────────────────────

class _LoadingContent extends StatelessWidget {
  const _LoadingContent({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    // Скелетон повторяет форму настоящих блоков, чтобы шторка не «прыгала».
    Widget block(IconData icon, String label, List<double> widths) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(icon: icon, label: label),
            const SizedBox(height: 10),
            for (final f in widths) ...[
              FractionallySizedBox(
                widthFactor: f,
                child: const SkeletonBox(height: 10),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      );
    }

    return Semantics(
      label: 'Разбираем фрагмент',
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Shimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                block(Icons.translate_rounded, 'Перевод', [0.5, 0.75]),
                block(Icons.menu_book_outlined, 'Смысловой контекст',
                    [1, 1, 0.6]),
                block(Icons.history_edu_outlined, 'Этимология / сленг',
                    [1, 0.8]),
                const _SectionLabel(
                  icon: Icons.image_outlined,
                  label: 'Иллюстрация',
                ),
                const SizedBox(height: 10),
                const AspectRatio(
                  aspectRatio: illustrationAspectRatio,
                  child: SkeletonBox(height: double.infinity, radius: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Разбираем фрагмент…',
            textAlign: TextAlign.center,
            style: AppText.caption.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Error ─────────────────────────

class _ErrorContent extends StatelessWidget {
  const _ErrorContent({super.key, required this.onRetry});

  final VoidCallback onRetry;

  // Тексты из задачи #12 и макета Figma (BottomSheet / Разбор, State=Error).
  static const title = 'Не удалось получить разбор';
  static const message =
      'Проверьте подключение к интернету и попробуйте ещё раз';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: c.errorBg, shape: BoxShape.circle),
            // Розовый круг с иконкой сети — как в макете.
            child: Icon(Icons.wifi_off_rounded, size: 26, color: c.error),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppText.bodyStrong.copyWith(color: c.text),
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: c.textSecondary),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Повторить'),
            style: FilledButton.styleFrom(
              backgroundColor: c.accentStrong,
              foregroundColor: c.onAccent,
              textStyle: AppText.button,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
