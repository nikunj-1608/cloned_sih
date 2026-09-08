import 'package:flutter/material.dart';


/// One number, one icon, one word. Used for wave height, wind and visibility.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.value,
    required this.unit,
    required this.caption,
    required this.captionTa,
    this.tint,
  });

  final IconData icon;
  final String value;
  final String unit;
  final String caption;
  final String captionTa;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = tint ?? theme.colorScheme.primary;

    return Semantics(
      label: '$caption $value $unit',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: accent),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: theme.textTheme.headlineLarge?.copyWith(fontSize: 26),
                  children: [
                    TextSpan(text: value),
                    TextSpan(
                      text: ' $unit',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                caption,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                captionTa,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
