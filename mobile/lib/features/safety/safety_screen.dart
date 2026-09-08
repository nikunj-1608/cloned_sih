import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/safety_level.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/action_card.dart';
import '../../core/widgets/metric_tile.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_hero.dart';
import '../../core/widgets/voice_button.dart';
import '../voyage/voyage_controller.dart';

/// The home screen, and the only screen most trips will ever need.
///
/// Reading order is fixed and shallow: can I go out, what is the sea doing, how
/// close is the border, ask a question. Nothing is hidden behind a menu.
class SafetyScreen extends ConsumerWidget {
  const SafetyScreen({super.key, required this.onAsk, required this.onOpenMap});

  final VoidCallback onAsk;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conditions = ref.watch(seaConditionsProvider);
    final boundary = ref.watch(boundaryStatusProvider);
    final voyage = ref.watch(voyageProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSizes.gutter,
        title: const _Wordmark(),
        actions: const [_LanguageChip(), SizedBox(width: AppSizes.gutter)],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.gutter,
            8,
            AppSizes.gutter,
            32,
          ),
          children: [
            StatusHero(
              level: conditions.level,
              summary: conditions.summary,
              footnote: 'Updated ${conditions.ageLabel.toLowerCase()}',
            ),
            const SizedBox(height: 26),

            const SectionHeader(title: 'Sea right now', titleTa: 'கடல் நிலை'),
            Row(
              children: [
                Expanded(
                  child: MetricTile(
                    icon: Icons.waves_rounded,
                    value: conditions.waveHeightM.toStringAsFixed(1),
                    unit: 'm',
                    caption: 'Waves',
                    captionTa: 'அலைகள்',
                    tint: AppColors.horizon,
                  ),
                ),
                const SizedBox(width: AppSizes.gap),
                Expanded(
                  child: MetricTile(
                    icon: Icons.air_rounded,
                    value: conditions.windSpeedKmh.toStringAsFixed(0),
                    unit: 'km/h',
                    caption: 'Wind',
                    captionTa: 'காற்று',
                    tint: AppColors.horizon,
                  ),
                ),
                const SizedBox(width: AppSizes.gap),
                Expanded(
                  child: MetricTile(
                    icon: Icons.visibility_rounded,
                    value: conditions.visibilityKm.toStringAsFixed(0),
                    unit: 'km',
                    caption: 'Visibility',
                    captionTa: 'தெளிவு',
                    tint: AppColors.horizon,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            const SectionHeader(title: 'Boundary', titleTa: 'எல்லை'),
            ActionCard(
              icon: boundary.level == SafetyLevel.safe
                  ? Icons.shield_outlined
                  : Icons.report_problem_rounded,
              accent: boundary.level.color,
              title: boundary.headline,
              subtitle: boundary.isApproaching
                  ? 'Heading toward ${boundary.name}'
                  : '${boundary.name} — not approaching',
              onTap: onOpenMap,
            ),
            const SizedBox(height: AppSizes.gap),
            ActionCard(
              icon: voyage.underway
                  ? Icons.stop_circle_outlined
                  : Icons.sailing_rounded,
              accent: voyage.underway ? AppColors.danger : AppColors.safe,
              title: voyage.underway ? 'End trip' : 'Start trip',
              subtitle: voyage.underway
                  ? 'Tracking at ${voyage.speedKnots.toStringAsFixed(1)} knots'
                  : 'Begin tracking and boundary alerts',
              trailing: Switch(
                value: voyage.underway,
                onChanged: (_) =>
                    ref.read(voyageProvider.notifier).toggleVoyage(),
              ),
              onTap: () => ref.read(voyageProvider.notifier).toggleVoyage(),
            ),
            const SizedBox(height: 28),

            VoiceButton(onTap: onAsk),
          ],
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.deepSea,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.waves_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Text('ORCA', style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Change language',
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_rounded, size: 18),
            const SizedBox(width: 6),
            Text(
              'தமிழ்',
              style: theme.textTheme.labelLarge?.copyWith(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
