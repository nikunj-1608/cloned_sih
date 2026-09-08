import 'package:flutter/material.dart';

import '../models/advisory_pack.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// The staleness meter.
///
/// Cached data ages, and an advisory downloaded yesterday must not look like
/// one downloaded ten minutes ago. The bar drains over the pack's validity
/// window and changes colour as it goes, so the user can see confidence decay
/// without reading a timestamp.
class FreshnessBar extends StatelessWidget {
  const FreshnessBar({super.key, required this.pack});

  final AdvisoryPack? pack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (pack == null) {
      return _Shell(
        color: AppColors.inkMuted,
        progress: 0,
        title: 'No advisory saved',
        titleTa: 'தரவு எதுவும் இல்லை',
        detail: 'Download before you sail.',
      );
    }

    final advisory = pack!;
    final total = advisory.validUntil.difference(advisory.generatedAt);
    final remaining = advisory.validUntil.difference(DateTime.now());
    final progress = total.inSeconds <= 0
        ? 0.0
        : (remaining.inSeconds / total.inSeconds).clamp(0.0, 1.0);

    final color = switch (advisory.freshness) {
      'live' => AppColors.safe,
      'recent' => AppColors.caution,
      _ => AppColors.danger,
    };

    final source = advisory.source == AdvisorySource.cache
        ? 'Saved on this phone'
        : 'Downloaded';

    return _Shell(
      color: color,
      progress: progress,
      title: '$source · ${advisory.ageLabel}',
      titleTa: 'தரவு புதுப்பிப்பு',
      detail: advisory.isExpired
          ? 'Expired. Refresh at port before your next trip.'
          : 'Good for ${_hours(remaining)} more.',
      textTheme: theme.textTheme,
    );
  }

  static String _hours(Duration d) {
    if (d.inHours >= 1) return '${d.inHours} hr';
    return '${d.inMinutes.clamp(0, 59)} min';
  }
}

class _Shell extends StatelessWidget {
  const _Shell({
    required this.color,
    required this.progress,
    required this.title,
    required this.titleTa,
    required this.detail,
    this.textTheme,
  });

  final Color color;
  final double progress;
  final String title;
  final String titleTa;
  final String detail;
  final TextTheme? textTheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_download_outlined, size: 20, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 16),
                ),
              ),
              Text(titleTa, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: theme.colorScheme.outlineVariant,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 10),
          Text(detail, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13.5)),
        ],
      ),
    );
  }
}
