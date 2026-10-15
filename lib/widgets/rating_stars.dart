import 'package:flutter/material.dart';

/// Star rating widget with two modes:
/// - display: [onChanged] is null, shows [rating] as filled stars.
/// - input: [onChanged] is set, tapping a star reports 1..5.
class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final ValueChanged<double>? onChanged;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 20,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = rating >= i + 1 - 0.25;
        final star = Icon(
          filled ? Icons.star : Icons.star_border,
          size: size,
          color: Colors.amber,
        );
        if (onChanged == null) return star;
        return InkWell(
          onTap: () => onChanged((i + 1).toDouble()),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: star,
          ),
        );
      }),
    );
  }
}
