import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Compact, read-only score display used on gallery cards and detail headers.
class AppRatingStars extends StatelessWidget {
  const AppRatingStars({
    required this.rating,
    required this.ratingCount,
    this.size = 14,
    this.showCount = true,
    super.key,
  });

  final double rating;
  final int ratingCount;
  final double size;
  final bool showCount;

  @override
  Widget build(BuildContext context) {
    final normalized = rating.clamp(0, 5).toDouble();
    final halfSteps = (normalized * 2).round();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < 5; index++)
          Icon(
            halfSteps >= (index + 1) * 2
                ? Icons.star_rounded
                : halfSteps == index * 2 + 1
                ? Icons.star_half_rounded
                : Icons.star_outline_rounded,
            size: size,
            color: AppTheme.gold,
          ),
        if (showCount) ...[
          SizedBox(width: size * 0.25),
          Icon(
            Icons.people_alt_outlined,
            size: size * 0.9,
            color: Colors.white70,
          ),
          const SizedBox(width: 2),
          Text(
            '${_compactCount(ratingCount)} ratings',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              shadows: const [Shadow(color: Colors.black, blurRadius: 5)],
            ),
          ),
        ],
      ],
    );
  }

  String _compactCount(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}k';
    }
    return '$value';
  }
}
