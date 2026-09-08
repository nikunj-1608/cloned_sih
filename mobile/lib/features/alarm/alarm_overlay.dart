import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import 'alarm_controller.dart';
import 'alarm_state.dart';

/// Full-screen boundary alarm.
///
/// It takes over the screen deliberately. Below `critical` the user gets a
/// banner instead, but minutes from an international maritime boundary the
/// chart is no longer the most important thing on the display — and a
/// dismissal has to be a decision, not a stray tap while handling gear.
class AlarmOverlay extends ConsumerStatefulWidget {
  const AlarmOverlay({super.key});

  @override
  ConsumerState<AlarmOverlay> createState() => _AlarmOverlayState();
}

class _AlarmOverlayState extends ConsumerState<AlarmOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alarm = ref.watch(alarmProvider);
    final level = alarm.level;

    return PopScope(
      // The back gesture must not dismiss a boundary alarm.
      canPop: false,
      child: Material(
        color: level.color,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.gutter),
            child: Column(
              children: [
                const Spacer(),
                FadeTransition(
                  opacity: Tween<double>(begin: 0.45, end: 1).animate(_pulse),
                  child: Icon(level.icon, size: 116, color: Colors.white),
                ),
                const SizedBox(height: 28),
                Text(
                  level.title.en,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  level.title.ta,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 24,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 32),
                _CountdownPlate(alarm: alarm),
                const SizedBox(height: 20),
                Text(
                  alarm.boundaryName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 17,
                  ),
                ),
                const Spacer(),
                _DismissButton(
                  color: level.color,
                  onPressed: () => ref.read(alarmProvider.notifier).acknowledge(),
                ),
                const SizedBox(height: 12),
                Text(
                  'The alarm returns on its own if you keep going.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13.5,
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

class _CountdownPlate extends StatelessWidget {
  const _CountdownPlate({required this.alarm});

  final AlarmState alarm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Column(
        children: [
          Text(
            alarm.timeLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 46,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${alarm.distanceKm.toStringAsFixed(1)} km — எல்லைக்கு',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _DismissButton extends StatelessWidget {
  const _DismissButton({required this.color, required this.onPressed});

  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 78,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'I UNDERSTAND',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 2),
            Text('புரிந்தது', style: TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

/// The non-blocking form, for `advisory` and `warning`.
///
/// Sits above the navigation bar so it is visible on every screen without
/// covering the chart.
class AlarmBanner extends ConsumerWidget {
  const AlarmBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarm = ref.watch(alarmProvider);
    if (!alarm.isRinging || alarm.level.takesOverScreen) {
      return const SizedBox.shrink();
    }

    final level = alarm.level;
    return Material(
      color: level.color,
      child: InkWell(
        onTap: () => ref.read(alarmProvider.notifier).acknowledge(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.gutter, 12, AppSizes.gutter, 12),
          child: Row(
            children: [
              Icon(level.icon, color: Colors.white, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${level.title.en} — ${alarm.timeLabel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      level.title.ta,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.close_rounded, color: Colors.white, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
