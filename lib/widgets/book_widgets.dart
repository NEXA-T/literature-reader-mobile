import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Цвета «тканевых» обложек для книг без картинки в EPUB.
const _coverPalette = [
  Color(0xFF4F7A6C),
  Color(0xFF9A6A55),
  Color(0xFF5A6F93),
  Color(0xFF7A5A7E),
  Color(0xFF3E4F55),
  Color(0xFFA4863F),
];

/// Один и тот же цвет для одного и того же названия.
Color coverColorFor(String title) {
  var hash = 0;
  for (final unit in title.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return _coverPalette[hash % _coverPalette.length];
}

/// Обложка книги. Если в EPUB нет картинки — рисуем градиентную
/// «тканевую» обложку с названием и (на крупных обложках) автором.
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.title,
    this.author,
    this.cover,
    this.width = 56,
    this.height = 80,
  });

  final String title;
  final String? author;
  final ImageProvider? cover;

  /// `double.infinity` — занять всё место, которое даёт родитель.
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(6);
    final image = cover;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: LayoutBuilder(
          builder: (context, size) {
            final generated = _GeneratedCover(
              title: title,
              author: author,
              size: size.biggest,
            );
            if (image == null) return generated;
            return Image(
              image: image,
              fit: BoxFit.cover,
              // Битый файл обложки — показываем сгенерированную.
              errorBuilder: (_, _, _) => generated,
            );
          },
        ),
      ),
    );
  }
}

class _GeneratedCover extends StatelessWidget {
  const _GeneratedCover({
    required this.title,
    required this.author,
    required this.size,
  });

  final String title;
  final String? author;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final color = coverColorFor(title);
    final w = size.width;
    final h = size.height;
    // На маленьких обложках в списке автор не читается — не показываем.
    final showAuthor = author != null && author!.isNotEmpty && h >= 100;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.28)!],
        ),
      ),
      child: Stack(
        children: [
          // «Корешок» слева.
          Positioned(
            left: 4,
            top: 0,
            bottom: 0,
            child: Container(
              width: 1,
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(w * 0.16, h * 0.08, w * 0.08, h * 0.07),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bookQuote.copyWith(
                      color: Colors.white,
                      fontSize: w / 6.2,
                      height: 1.2,
                    ),
                  ),
                ),
                if (showAuthor) ...[
                  const Spacer(),
                  Text(
                    author!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: w / 10,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Тонкая полоска прогресса чтения.
class ReadingProgressBar extends StatelessWidget {
  const ReadingProgressBar({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1).toDouble(),
        minHeight: 4,
        backgroundColor: c.divider,
        color: c.accent,
      ),
    );
  }
}

/// Компактный бейдж прогресса: «42%», «Новая» или «Прочитана».
class ProgressBadge extends StatelessWidget {
  const ProgressBadge({super.key, required this.progress});

  /// От 0 до 1; `null` — книгу ещё не открывали.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = progress ?? 0;
    final (label, background, foreground) = p <= 0
        ? ('Новая', c.controlBg, c.textSecondary)
        : p >= 1
        ? ('Прочитана', c.accentStrong, c.onAccent)
        : ('${(p * 100).round()}%', c.highlight, c.chipText);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: AppText.caption.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          height: 1.2,
        ),
      ),
    );
  }
}

/// Крупная карточка «Продолжить чтение».
class ContinueReadingCard extends StatelessWidget {
  const ContinueReadingCard({
    super.key,
    required this.title,
    required this.author,
    this.progress,
    this.cover,
    this.onTap,
  });

  final String title;
  final String author;
  final double? progress;
  final ImageProvider? cover;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.divider),
          ),
          child: Row(
            children: [
              BookCover(
                title: title,
                author: author,
                cover: cover,
                width: 80,
                height: 120,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodyStrong.copyWith(
                        color: c.text,
                        fontSize: 17,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body.copyWith(color: c.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    ReadingProgressBar(value: progress ?? 0),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ProgressBadge(progress: progress),
                        const Spacer(),
                        Text(
                          'Продолжить',
                          style: AppText.button.copyWith(
                            color: c.accentStrong,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: c.accentStrong,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Строка книги в виде «Список».
class BookListTile extends StatelessWidget {
  const BookListTile({
    super.key,
    required this.title,
    required this.author,
    this.progress,
    this.cover,
    this.onTap,
  });

  final String title;
  final String author;
  final double? progress;
  final ImageProvider? cover;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            BookCover(title: title, author: author, cover: cover),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.bodyStrong.copyWith(color: c.text),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: ProgressBadge(progress: progress),
                      ),
                    ],
                  ),
                  Text(
                    author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(
                      color: c.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ReadingProgressBar(value: progress ?? 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Карточка книги в виде «Сетка» (как полка Apple Books):
/// крупная обложка с бейджем, тонкий прогресс, название и автор.
class BookGridCard extends StatelessWidget {
  const BookGridCard({
    super.key,
    required this.title,
    required this.author,
    this.progress,
    this.cover,
    this.onTap,
  });

  final String title;
  final String author;
  final double? progress;
  final ImageProvider? cover;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                BookCover(
                  title: title,
                  author: author,
                  cover: cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: ProgressBadge(progress: progress),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ReadingProgressBar(value: progress ?? 0),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.bodyStrong.copyWith(
              color: c.text,
              fontSize: 14,
              height: 1.3,
            ),
          ),
          Text(
            author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}
