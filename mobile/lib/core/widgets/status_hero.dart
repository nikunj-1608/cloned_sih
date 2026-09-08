import 'package:flutter/material.dart';

import '../models/safety_level.dart';
import '../theme/app_theme.dart';

/// The answer-at-a-glance card.
///
/// Colour and icon carry the meaning; the text confirms it. Someone who cannot
/// read either script should still know, from across the deck, whether the card
/// is green or red.
class StatusHero extends StatelessWidget {
  const StatusHero({
    super.key,
    required this.level,
    required this.summary,
    this.footnote,
  });

  final SafetyLevel level;
  final String summary;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Semantics(
      liveRegion: true,
      label: '${level.label.en}. $summary',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.gutter,
          vertical: 28,
        ),
        decoration: BoxDecoration(
          color: level.color,
          borderRadius: BorderRadius.circular(AppSizes.radius + 6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(level.icon, size: 64, color: Colors.white),
            const SizedBox(height: 18),
            Text(
              level.label.en,
              style: text.headlineLarge?.copyWith(
                color: Colors.white,
                fontSize: 34,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              level.label.ta,
              style: text.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              summary,
              style: text.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.95),
                height: 1.4,
              ),
            ),
            if (footnote case final note?) ...[
              const SizedBox(height: 18),
              _Freshness(note: note),
            ],
          ],
        ),
      ),
    );
  }
}

class _Freshness extends StatelessWidget {
  const _Freshness({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule_rounded, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            note,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
