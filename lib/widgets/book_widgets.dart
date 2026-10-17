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

/// Подпись прогресса: `null` или 0 — книга ещё не открывалась.
String progressLabel(double? p) {
  if (p == null || p <= 0) return 'Не начата';
  if (p >= 1) return 'Прочитана';
  return '${(p * 100).round()}%';
}

/// Обложка книги. Если в EPUB нет картинки — рисуем аккуратную
/// «тканевую» обложку с названием, чтобы список не выглядел пустым.
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.title,
    this.cover,
    this.width = 56,
    this.height = 80,
  });

  final String title;
  final ImageProvider? cover;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(6);
    final color = coverColorFor(title);
    final image = cover;

    final generated = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.25)!],
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
            padding: EdgeInsets.fromLTRB(
              width * 0.16,
              height * 0.1,
              width * 0.08,
              height * 0.08,
            ),
            child: Text(
              title,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppText.bookQuote.copyWith(
                color: Colors.white,
                fontSize: width / 6.2,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );

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
        child: image == null
            ? generated
            : Image(
                image: image,
                fit: BoxFit.cover,
                // Битый файл обложки — показываем сгенерированную.
                errorBuilder: (_, _, _) => generated,
              ),
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
              BookCover(title: title, cover: cover, width: 72, height: 104),
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          progressLabel(progress),
                          style: AppText.caption.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
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

/// Строка книги в общем списке.
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
            BookCover(title: title, cover: cover),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyStrong.copyWith(color: c.text),
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
                  Row(
                    children: [
                      Expanded(
                        child: ReadingProgressBar(value: progress ?? 0),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 68,
                        child: Text(
                          progressLabel(progress),
                          textAlign: TextAlign.right,
                          style: AppText.caption.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
