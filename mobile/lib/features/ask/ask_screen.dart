import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/voice_button.dart';

/// Voice-first entry to the agent swarm.
///
/// Phase 1 ships the surface only: the suggestion set, the microphone
/// affordance, and the shape of an answer. Phase 3 wires speech in, Phase 4
/// replaces [_SampleAnswer] with the live `POST /v1/chat` response.
class AskScreen extends ConsumerStatefulWidget {
  const AskScreen({super.key});

  @override
  ConsumerState<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends ConsumerState<AskScreen> {
  bool _listening = false;
  String? _asked;

  static const List<_Suggestion> _suggestions = [
    _Suggestion(
      icon: Icons.set_meal_rounded,
      en: 'Where can I find fish today?',
      ta: 'இன்று மீன் எங்கே கிடைக்கும்?',
    ),
    _Suggestion(
      icon: Icons.sailing_rounded,
      en: 'Is it safe to go out tomorrow morning?',
      ta: 'நாளை காலை கடலுக்குச் செல்லலாமா?',
    ),
    _Suggestion(
      icon: Icons.thunderstorm_rounded,
      en: 'Any storm warning near me?',
      ta: 'அருகில் புயல் எச்சரிக்கை உள்ளதா?',
    ),
    _Suggestion(
      icon: Icons.route_rounded,
      en: 'What is the safest way back to port?',
      ta: 'துறைமுகம் திரும்ப பாதுகாப்பான வழி எது?',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSizes.gutter,
        title: const Text('Ask'),
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
            VoiceButton(
              listening: _listening,
              onTap: () => setState(() => _listening = !_listening),
            ),
            const SizedBox(height: 10),
            Text(
              'Speak in Tamil or English. Hold the boat steady — you do not '
              'need to type anything.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 26),

            const SectionHeader(
              title: 'Common questions',
              titleTa: 'பொதுவான கேள்விகள்',
            ),
            for (final suggestion in _suggestions) ...[
              _SuggestionCard(
                suggestion: suggestion,
                selected: _asked == suggestion.en,
                onTap: () => setState(() => _asked = suggestion.en),
              ),
              const SizedBox(height: AppSizes.gap),
            ],

            if (_asked != null) ...[
              const SizedBox(height: 14),
              const _SampleAnswer(),
            ],
          ],
        ),
      ),
    );
  }
}

class _Suggestion {
  const _Suggestion({required this.icon, required this.en, required this.ta});

  final IconData icon;
  final String en;
  final String ta;
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.suggestion,
    required this.selected,
    required this.onTap,
  });

  final _Suggestion suggestion;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius),
        side: BorderSide(
          color: selected ? AppColors.deepSea : theme.colorScheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(suggestion.icon, size: 26, color: AppColors.deepSea),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(suggestion.en, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(suggestion.ta, style: theme.textTheme.bodyMedium),
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

/// A worked example of the answer format, shown so the team can agree on the
/// layout before the agent exists. Every real answer will carry the same
/// evidence footer — sources and their age — because the problem statement
/// asks for explainable, evidence-backed recommendations.
class _SampleAnswer extends StatelessWidget {
  const _SampleAnswer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.deepSea.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: AppColors.deepSea.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 18, color: AppColors.deepSea),
              const SizedBox(width: 8),
              Text(
                'Sample answer format',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 13,
                  color: AppColors.deepSea,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'The agent replies here, in the language you asked in, with a map '
            'layer attached when the answer is a place.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.deepSea.withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          Text(
            'Based on',
            style: theme.textTheme.labelLarge?.copyWith(fontSize: 12.5),
          ),
          const SizedBox(height: 8),
          const _EvidenceChip(source: 'Open-Meteo Marine', age: 'live'),
          const SizedBox(height: 6),
          const _EvidenceChip(source: 'INCOIS PFZ advisory', age: 'pending'),
          const SizedBox(height: 14),
          Text(
            'Connects to the agent swarm in Phase 4.',
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _EvidenceChip extends StatelessWidget {
  const _EvidenceChip({required this.source, required this.age});

  final String source;
  final String age;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const Icon(Icons.dataset_outlined, size: 15, color: AppColors.inkMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(source, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14)),
        ),
        Text(
          age,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
