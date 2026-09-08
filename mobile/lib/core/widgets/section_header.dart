import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.titleTa});

  final String title;
  final String? titleTa;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(title, style: theme.textTheme.titleLarge?.copyWith(fontSize: 19)),
          if (titleTa case final ta?) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                ta,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
