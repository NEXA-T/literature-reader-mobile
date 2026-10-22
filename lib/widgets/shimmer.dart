import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Область, внутри которой скелетоны переливаются одной общей волной.
///
/// Сам [Shimmer] ничего не рисует: он только крутит анимацию.
/// Блик рисует каждый [SkeletonBox] внутри, поэтому обычный текст
/// и иконки рядом со скелетонами (подписи блоков) остаются как есть.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  static ShimmerState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<ShimmerState>();

  @override
  State<Shimmer> createState() => ShimmerState();
}

class ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  /// Анимация, на которую подписываются скелетоны.
  Listenable get animation => _controller;

  /// Положение блика: от 0 до 1 за один проход.
  double get progress => _controller.value;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // В настройках доступности можно отключить анимации — уважаем это.
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  RenderBox? get _box {
    final object = context.findRenderObject();
    return object is RenderBox && object.hasSize ? object : null;
  }

  /// Размер всей области шиммера.
  Size? get size => _box?.size;

  /// Где лежит [descendant] относительно области шиммера.
  Offset? offsetOf(RenderBox descendant) {
    final box = _box;
    if (box == null || !descendant.attached) return null;
    return descendant.localToGlobal(Offset.zero, ancestor: box);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Серая плашка-заглушка, на месте которой потом появится текст.
/// Внутри [Shimmer] по ней проходит блик.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 10,
    this.radius,
  });

  final double width;
  final double height;
  final double? radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> {
  ShimmerState? _shimmer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shimmer = Shimmer.maybeOf(context);
    if (shimmer != _shimmer) {
      _shimmer?.animation.removeListener(_tick);
      _shimmer = shimmer;
      _shimmer?.animation.addListener(_tick);
    }
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _shimmer?.animation.removeListener(_tick);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final box = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: c.skeleton,
        borderRadius: BorderRadius.circular(widget.radius ?? widget.height / 2),
      ),
    );

    final shimmer = _shimmer;
    if (shimmer == null) return box;

    final shine = Color.lerp(c.skeleton, c.surface, 0.75)!;
    final gradient = LinearGradient(
      begin: const Alignment(-1, -0.3),
      end: const Alignment(1, 0.3),
      colors: [c.skeleton, shine, c.skeleton],
      stops: const [0.35, 0.5, 0.65],
      transform: _SlideGradient(shimmer.progress),
    );

    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        // Вызывается при отрисовке, когда размеры уже известны.
        final area = shimmer.size;
        final self = context.findRenderObject();
        final offset = self is RenderBox && self.hasSize
            ? shimmer.offsetOf(self)
            : null;
        if (area == null || offset == null) {
          return LinearGradient(
            colors: [c.skeleton, c.skeleton],
          ).createShader(bounds);
        }
        // Градиент рассчитан на всю область шиммера, поэтому блик
        // проходит по всем плашкам одной волной, а не по каждой отдельно.
        return gradient.createShader(
          Rect.fromLTWH(-offset.dx, -offset.dy, area.width, area.height),
        );
      },
      child: box,
    );
  }
}

/// Сдвигает градиент слева направо: от −1 до +1 ширины области.
class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.progress);

  final double progress;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final dx = bounds.width * (progress * 2 - 1);
    return Matrix4.translationValues(dx, 0, 0);
  }
}
