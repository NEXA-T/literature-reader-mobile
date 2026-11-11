import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'shimmer.dart';

/// Загружает иллюстрацию сцены по `image_prompt` из ответа AI.
///
/// Договорённость с Дашей (#15): функция `loadIllustration` живёт
/// в lib/ai_explain/ai_explain_sheet.dart и при ошибке бросает
/// исключение (AnalysisException) — блок покажет «Повторить генерацию».
typedef IllustrationLoader = Future<ImageProvider> Function(String imagePrompt);

/// Пропорции блока одинаковы во всех состояниях — поэтому при смене
/// «генерация → картинка → ошибка» шторка не дёргается.
const illustrationAspectRatio = 16 / 10;

const _radius = BorderRadius.all(Radius.circular(12));

/// Блок иллюстрации сцены в шторке разбора (задача #14).
///
/// Три состояния:
/// • генерация — шиммер, иконка палитры, «Генерируем иллюстрацию сцены…»;
/// • успех — скруглённая картинка, по тапу открывается на весь экран;
/// • ошибка — плашка и кнопка «Повторить генерацию».
///
/// Если загрузчика ещё нет, шторка показывает [IllustrationPlaceholder].
class IllustrationView extends StatefulWidget {
  const IllustrationView({
    super.key,
    required this.prompt,
    required this.load,
  });

  /// `image_prompt` из ответа AI — описание сцены на английском.
  final String prompt;

  final IllustrationLoader load;

  @override
  State<IllustrationView> createState() => _IllustrationViewState();
}

enum _Phase { generating, ready, failed }

class _IllustrationViewState extends State<IllustrationView> {
  _Phase _phase = _Phase.generating;
  ImageProvider? _image;
  int _attempt = 0;

  /// Уникальный тег для анимации перехода в полноэкранный просмотр.
  late final Object _heroTag = Object();

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final attempt = ++_attempt;
    if (_phase != _Phase.generating) {
      setState(() => _phase = _Phase.generating);
    }
    try {
      final image = await widget.load(widget.prompt);
      if (!mounted || attempt != _attempt) return;
      // Не успев за отведённое время, бэкенд отвечает ссылкой на SVG-заглушку,
      // а Flutter SVG не рисует. Сразу показываем «Повторить генерацию».
      if (image is NetworkImage &&
          Uri.tryParse(image.url)?.path.toLowerCase().endsWith('.svg') ==
              true) {
        throw StateError('сервер вернул SVG-заглушку: ${image.url}');
      }
      setState(() {
        _image = image;
        _phase = _Phase.ready;
      });
    } catch (e) {
      debugPrint('[Illustration] не удалось: $e');
      if (!mounted || attempt != _attempt) return;
      setState(() => _phase = _Phase.failed);
    }
  }

  /// Загрузчик вернул картинку, но показать её не вышло (ссылка
  /// не открылась, байты не картинка) — переходим в состояние ошибки.
  void _imageFailed() {
    if (mounted && _phase == _Phase.ready) {
      setState(() => _phase = _Phase.failed);
    }
  }

  void _openFullscreen() {
    final image = _image;
    if (image == null) return;
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        barrierDismissible: true,
        barrierLabel: 'Закрыть иллюстрацию',
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, _, _) =>
            _FullscreenIllustration(image: image, heroTag: _heroTag),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = switch (_phase) {
      _Phase.generating => const _Generating(key: ValueKey('generating')),
      _Phase.failed => _Failed(key: const ValueKey('failed'), onRetry: _run),
      _Phase.ready => _Ready(
          key: const ValueKey('ready'),
          image: _image!,
          heroTag: _heroTag,
          onOpen: _openFullscreen,
          onImageError: _imageFailed,
        ),
    };

    return AspectRatio(
      aspectRatio: illustrationAspectRatio,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        layoutBuilder: (current, previous) => Stack(
          fit: StackFit.expand,
          children: [...previous, ?current],
        ),
        child: child,
      ),
    );
  }
}

// ───────────────────────── Генерация ─────────────────────────

class _Generating extends StatefulWidget {
  const _Generating({super.key});

  /// Через сколько показать подсказку, что генерация идёт долго.
  static const hintDelay = Duration(seconds: 8);

  @override
  State<_Generating> createState() => _GeneratingState();
}

class _GeneratingState extends State<_Generating> {
  Timer? _timer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    // Настоящая генерация GigaChat занимает 20–40 секунд: без подсказки
    // долгий шиммер выглядит как зависание (#23).
    _timer = Timer(_Generating.hintDelay, () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: 'Генерируем иллюстрацию сцены',
      liveRegion: true,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Shimmer(child: SkeletonBox(height: double.infinity, radius: 12)),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.palette_outlined, size: 28, color: c.textSecondary),
                  const SizedBox(height: 8),
                  Text(
                    'Генерируем иллюстрацию сцены…',
                    textAlign: TextAlign.center,
                    style: AppText.caption.copyWith(color: c.textSecondary),
                  ),
                  AnimatedOpacity(
                    opacity: _slow ? 1 : 0,
                    duration: const Duration(milliseconds: 400),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Обычно это занимает до 40 секунд',
                        textAlign: TextAlign.center,
                        style: AppText.caption.copyWith(
                          color: c.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Успех ─────────────────────────

class _Ready extends StatelessWidget {
  const _Ready({
    super.key,
    required this.image,
    required this.heroTag,
    required this.onOpen,
    required this.onImageError,
  });

  final ImageProvider image;
  final Object heroTag;
  final VoidCallback onOpen;
  final VoidCallback onImageError;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: 'Иллюстрация сцены. Открыть на весь экран',
      child: Material(
        color: c.skeleton,
        borderRadius: _radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: heroTag,
                child: Image(
                  image: image,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  // Картинка проявляется плавно, когда декодировалась.
                  frameBuilder: (_, child, frame, wasSync) => wasSync
                      ? child
                      : AnimatedOpacity(
                          opacity: frame == null ? 0 : 1,
                          duration: const Duration(milliseconds: 300),
                          child: child,
                        ),
                  // Ссылка не открылась или байты не картинка — после кадра
                  // блок переключится на плашку «Повторить генерацию».
                  errorBuilder: (_, error, _) {
                    debugPrint('[Illustration] не удалось показать: $error');
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => onImageError(),
                    );
                    return const SizedBox.shrink();
                  },
                ),
              ),
              // Подсказка, что картинку можно открыть крупно.
              Positioned(
                right: 8,
                bottom: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.open_in_full_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
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

class _FullscreenIllustration extends StatelessWidget {
  const _FullscreenIllustration({required this.image, required this.heroTag});

  final ImageProvider image;
  final Object heroTag;

  @override
  Widget build(BuildContext context) {
    void close() => Navigator.of(context).maybePop();
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Тап по картинке закрывает, щипок — приближает.
          Positioned.fill(
            child: GestureDetector(
              onTap: close,
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Hero(
                    tag: heroTag,
                    child: Image(image: image, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  onPressed: close,
                  tooltip: 'Закрыть',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                  ),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Заглушка ─────────────────────────

/// Пунктирная заглушка, пока загрузчик иллюстраций не подключён.
/// Того же размера, что и [IllustrationView].
class IllustrationPlaceholder extends StatelessWidget {
  const IllustrationPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AspectRatio(
      aspectRatio: illustrationAspectRatio,
      child: CustomPaint(
        painter: DashedBorderPainter(color: c.divider, radius: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(color: c.bg, borderRadius: _radius),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.image_outlined, size: 28, color: c.textSecondary),
                const SizedBox(height: 8),
                Text(
                  'Здесь появится иллюстрация',
                  textAlign: TextAlign.center,
                  style: AppText.caption.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Ошибка ─────────────────────────

class _Failed extends StatelessWidget {
  const _Failed({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return CustomPaint(
      painter: DashedBorderPainter(color: c.divider, radius: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(color: c.bg, borderRadius: _radius),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  size: 26,
                  color: c.textSecondary,
                ),
                const SizedBox(height: 6),
                Text(
                  'Не удалось создать иллюстрацию',
                  textAlign: TextAlign.center,
                  style: AppText.caption.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Повторить генерацию'),
                  style: TextButton.styleFrom(
                    foregroundColor: c.accentStrong,
                    textStyle: AppText.button,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Пунктирная рамка со скруглением (для плашки ошибки).
class DashedBorderPainter extends CustomPainter {
  DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.75),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dash = 6.0, gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
