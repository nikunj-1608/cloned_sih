import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/voice_button.dart';

/// Voice-first entry to the agent swarm.
///
/// Phase 1 ships the surface only: the suggestion set, the microphone
/// affordance, and the shape of an answer. Phase 3 wires speech in, Phase 4
/// replaces the hardcoded [_Suggestion.answer]s with the live
/// `POST /v1/chat` response.
class AskScreen extends ConsumerStatefulWidget {
  const AskScreen({super.key});

  @override
  ConsumerState<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends ConsumerState<AskScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _answerKey = GlobalKey();
  final TextEditingController _transcriptController = TextEditingController();

  bool _speechAvailable = false;
  bool _listening = false;

  /// The suggestion currently being answered, or null if nothing asked yet.
  _Suggestion? _asked;

  /// Set when the user typed/spoke something that didn't match a known
  /// question — shows the generic placeholder instead of a hardcoded answer.
  bool _showFallbackAnswer = false;

  static const List<_Suggestion> _suggestions = [
    _Suggestion(
      icon: Icons.set_meal_rounded,
      en: 'Where can I find fish today?',
      ta: 'இன்று மீன் எங்கே கிடைக்கும்?',
      keywords: ['fish', 'find', 'today'],
      answer: _AnswerData(
        text:
        'Sardine and mackerel shoals are reported 8–11 km off the coast, '
            'bearing south-southeast from the harbor. Surface chlorophyll '
            'and recent catch logs both point to that zone.',
        evidence: [
          _EvidenceChip(source: 'INCOIS PFZ advisory', age: '2h ago'),
          _EvidenceChip(source: 'Ocean color / chlorophyll', age: '6h ago'),
        ],
      ),
    ),
    _Suggestion(
      icon: Icons.sailing_rounded,
      en: 'Is it safe to go out tomorrow morning?',
      ta: 'நாளை காலை கடலுக்குச் செல்லலாமா?',
      keywords: ['safe', 'tomorrow', 'morning', 'go out'],
      answer: _AnswerData(
        text:
        'Conditions look manageable: wind under 15 km/h and wave height '
            'around 0.6 m before 9 AM. No advisories are active for your '
            'zone right now, but that can change — recheck before you leave.',
        evidence: [
          _EvidenceChip(source: 'Open-Meteo Marine', age: 'live'),
          _EvidenceChip(source: 'IMD coastal bulletin', age: '3h ago'),
        ],
      ),
    ),
    _Suggestion(
      icon: Icons.thunderstorm_rounded,
      en: 'Any storm warning near me?',
      ta: 'அருகில் புயல் எச்சரிக்கை உள்ளதா?',
      keywords: ['storm', 'warning', 'near'],
      answer: _AnswerData(
        text:
        'No storm or cyclone warning is currently active for your '
            'coastal zone. The nearest advisory is for a low-pressure '
            'system still 400+ km out, being monitored but not yet upgraded.',
        evidence: [
          _EvidenceChip(source: 'IMD cyclone bulletin', age: '1h ago'),
        ],
      ),
    ),
    _Suggestion(
      icon: Icons.route_rounded,
      en: 'What is the safest way back to port?',
      ta: 'துறைமுகம் திரும்ப பாதுகாப்பான வழி எது?',
      keywords: ['safest', 'way', 'back', 'port', 'route'],
      answer: _AnswerData(
        text:
        'Head north along the coastal channel rather than the open-water '
            'shortcut — swell is running higher offshore this afternoon. The '
            'coastal route adds about 20 minutes but stays inside 2 m waves.',
        evidence: [
          _EvidenceChip(source: 'Open-Meteo Marine', age: 'live'),
          _EvidenceChip(source: 'Coast guard route advisory', age: '4h ago'),
        ],
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onStatus: _onSpeechStatus,
      onError: (error) {
        debugPrint('STT error: ${error.errorMsg}');
        if (mounted) setState(() => _listening = false);
      },
    );
    if (mounted) setState(() => _speechAvailable = available);
  }

  void _onSpeechStatus(String status) {
    if ((status == 'done' || status == 'notListening') && _listening) {
      setState(() => _listening = false);
    }
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      await _initSpeech();
      if (!_speechAvailable) return;
    }

    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }

    setState(() {
      _listening = true;
      _transcriptController.clear();
    });

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _transcriptController.text = result.recognizedWords;
          _transcriptController.selection = TextSelection.collapsed(
            offset: _transcriptController.text.length,
          );
        });
        if (result.finalResult) {
          _submitText(result.recognizedWords);
        }
      },
      // Swap for 'ta_IN' or make this dynamic per your language toggle.
      localeId: 'en_IN',
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
  }

  /// Matches free-form text (typed or spoken) against the known
  /// suggestions by keyword overlap, since voice recognition rarely comes
  /// back as an exact match to the suggestion's wording.
  _Suggestion? _matchSuggestion(String text) {
    final normalized = text.toLowerCase().trim();
    if (normalized.isEmpty) return null;

    _Suggestion? best;
    int bestHits = 0;
    for (final suggestion in _suggestions) {
      final hits = suggestion.keywords
          .where((keyword) => normalized.contains(keyword))
          .length;
      if (hits > bestHits) {
        bestHits = hits;
        best = suggestion;
      }
    }
    // Require at least one real keyword hit before calling it a match.
    return bestHits > 0 ? best : null;
  }

  void _selectSuggestion(_Suggestion suggestion) {
    setState(() {
      _asked = suggestion;
      _showFallbackAnswer = false;
      _transcriptController.text = suggestion.en;
    });
    _scrollToAnswer();
  }

  void _submitText(String text) {
    if (text.trim().isEmpty) return;
    final match = _matchSuggestion(text);
    setState(() {
      if (match != null) {
        _asked = match;
        _showFallbackAnswer = false;
      } else {
        _asked = null;
        _showFallbackAnswer = true;
      }
    });
    _scrollToAnswer();
  }

  void _scrollToAnswer() {
    // Wait a frame so the answer widget is actually laid out before we
    // try to scroll to it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final answerContext = _answerKey.currentContext;
      if (answerContext != null) {
        Scrollable.ensureVisible(
          answerContext,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          alignment: 0.1,
        );
      }
    });
  }

  Future<void> _speak(String text) async {
    await _tts.setLanguage('en-IN');
    await _tts.setSpeechRate(0.45);
    await _tts.speak(text);
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    _transcriptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showAnswer = _asked != null || _showFallbackAnswer;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSizes.gutter,
        title: const Text('Ask'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.gutter,
                  8,
                  AppSizes.gutter,
                  16,
                ),
                children: [
                  VoiceButton(
                    listening: _listening,
                    onTap: _toggleListening,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _speechAvailable
                        ? 'Speak in Tamil or English. Hold the boat steady — '
                        'you do not need to type anything.'
                        : 'Microphone unavailable. Check mic permission in '
                        'settings.',
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
                      selected: _asked == suggestion,
                      onTap: () => _selectSuggestion(suggestion),
                    ),
                    const SizedBox(height: AppSizes.gap),
                  ],

                  if (showAnswer) ...[
                    const SizedBox(height: 14),
                    KeyedSubtree(
                      key: _answerKey,
                      child: _asked != null
                          ? _AnswerCard(
                        suggestion: _asked!,
                        onSpeak: _speak,
                      )
                          : _FallbackAnswer(onSpeak: _speak),
                    ),
                  ],
                ],
              ),
            ),

            // Live transcript, pinned at the bottom of the page.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.gutter,
                8,
                AppSizes.gutter,
                12,
              ),
              child: TextField(
                controller: _transcriptController,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: _listening
                      ? 'Listening…'
                      : 'Transcript will appear here',
                  prefixIcon: Icon(
                    _listening ? Icons.mic : Icons.mic_none,
                    color: _listening ? AppColors.deepSea : null,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send_rounded),
                    color: AppColors.deepSea,
                    tooltip: 'Send',
                    onPressed: () => _submitText(_transcriptController.text),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radius),
                  ),
                ),
                onSubmitted: _submitText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Suggestion {
  const _Suggestion({
    required this.icon,
    required this.en,
    required this.ta,
    required this.keywords,
    required this.answer,
  });

  final IconData icon;
  final String en;
  final String ta;

  /// Lowercase keywords used to fuzzy-match spoken/typed text back to this
  /// suggestion — voice recognition rarely returns the exact phrasing.
  final List<String> keywords;
  final _AnswerData answer;
}

class _AnswerData {
  const _AnswerData({required this.text, required this.evidence});

  final String text;
  final List<_EvidenceChip> evidence;
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

/// The hardcoded answer for a matched question. Phase 4 replaces
/// [_Suggestion.answer] with the live `POST /v1/chat` response but keeps
/// this same layout.
class _AnswerCard extends StatelessWidget {
  const _AnswerCard({required this.suggestion, required this.onSpeak});

  final _Suggestion suggestion;
  final Future<void> Function(String text) onSpeak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answer = suggestion.answer;
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
              Expanded(
                child: Text(
                  suggestion.en,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 13,
                    color: AppColors.deepSea,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up_rounded,
                    size: 20, color: AppColors.deepSea),
                tooltip: 'Read aloud',
                onPressed: () => onSpeak(answer.text),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(answer.text, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          Divider(color: AppColors.deepSea.withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          Text(
            'Based on',
            style: theme.textTheme.labelLarge?.copyWith(fontSize: 12.5),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < answer.evidence.length; i++) ...[
            answer.evidence[i],
            if (i != answer.evidence.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

/// Shown when the user typed/spoke something that didn't match a known
/// question. Keeps the same visual format so it doesn't look broken.
class _FallbackAnswer extends StatelessWidget {
  const _FallbackAnswer({required this.onSpeak});

  final Future<void> Function(String text) onSpeak;

  static const String _text =
      "That one isn't in the sample set yet — the live agent will handle "
      'open-ended questions in Phase 4. Try one of the common questions '
      'above for now.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.inkMuted.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: AppColors.inkMuted.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 18, color: AppColors.inkMuted),
              const SizedBox(width: 8),
              Text(
                'No matching sample answer',
                style: theme.textTheme.labelLarge?.copyWith(fontSize: 13),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.volume_up_rounded, size: 20),
                tooltip: 'Read aloud',
                onPressed: () => onSpeak(_text),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(_text, style: theme.textTheme.bodyLarge),
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