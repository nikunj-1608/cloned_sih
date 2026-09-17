import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

enum _Sender { user, bot }

class _Message {
  const _Message({required this.text, required this.sender});
  final String text;
  final _Sender sender;
}

// ---------------------------------------------------------------------------
// Hardcoded Q&A — Phase 4 will replace these with live POST /v1/chat calls.
//
// Suggestion chips (shown on screen): 2 questions — Kasimedu weather &
// Vanjaram price. Typed questions: 3 original questions still work via the
// if-else-if ladder below — 5 branches total.
// ---------------------------------------------------------------------------

// Stored for exact-match fallback on typed Q3.
const String _q3 = 'tell me about today\'s weather outlook';

// ── Typed question answers ────────────────────────────────────────────────

const String _a1 =
    'For Lake Muttukadu Backwaters today, live bait is the better choice. '
    'Backwater species like mullet and catfish are more responsive to natural '
    'scent cues, especially in brackish conditions. The current salinity and '
    'tidal flow favour live shrimp or small baitfish near the channel edges. '
    'Artificial lures can work near the mouth where the current is faster, '
    'but live bait will outperform them deeper inside today.';

const String _a2 =
    'The surface water temperature around Muttukadu today is approximately '
    '29 °C — comfortably within the optimal range for most backwater species. '
    'It is neither too warm nor too cold. Fish are likely to be active through '
    'the morning and again in the late afternoon. Avoid the midday window '
    '(12 PM – 3 PM) when surface heat can push fish to deeper, cooler water.';

const String _a3 =
    'Weather outlook data will be available once the live agent is connected '
    'in Phase 4. For now, check the Open-Meteo marine widget on the Home screen.';

// ── Suggestion chip answers (real data, Sep 2026) ────────────────────────

// Chip 1 — Kasimedu Fishing Harbor ideal weather conditions
const String _a4 =
    'Ideal fishing conditions at Kasimedu Fishing Harbour (Royapuram):\n\n'
    '• Best time: Early morning 2 AM – 6 AM, when the harbour is most '
    'active and fish are feeding near the surface.\n'
    '• Weather: Stable conditions with wind below 20 km/h and wave height '
    'under 1 m. Avoid heavy rain and rough sea days.\n'
    '• Season: March – May is most productive (calm seas, strong catches). '
    'June – November (monsoon) brings rough seas and many boats stay docked.\n'
    '• Tides: Fish move actively around tide transitions. Use a solunar '
    'table to find the major and minor bite windows for the day.\n'
    '• Tip: Consult local fishermen at the harbour — they track wind '
    'direction and current shifts that online forecasts often miss.';

// Chip 2 — Vanjaram (Seer Fish) market price
const String _a5 =
    'Market price of Vanjaram (Seer Fish / King Fish) in Chennai '
    '— September 2026:\n\n'
    '• Kasimedu wholesale market: \u20b9480 – \u20b9620 per kg\n'
    '• Retail fish shops: \u20b9650 – \u20b9800 per kg\n'
    '• Online delivery platforms: \u20b9900 – \u20b91,000+ per kg\n\n'
    'Larger fish command a higher price. Pre-cut steaks cost more than '
    'whole fish. Prices spike after boat strikes or during low-supply periods.\n\n'
    'Tip: Visit Kasimedu before 7 AM for the freshest catch at the best rate.';

const String _fallback = 'Sorry, please enter the query again.';

/// Returns the hardcoded bot reply for [input], or [_fallback] if no match.
///
/// If-else-if ladder — correct for a fixed, small set of known questions.
String _getBotReply(String input) {
  final q = input.toLowerCase().trim();

  // Chip 1 — Kasimedu fishing weather
  if (q.contains('kasimedu') ||
      (q.contains('royapuram') && q.contains('fishing'))) {
    return _a4;
  }
  // Chip 2 — Vanjaram price
  else if (q.contains('vanjaram') ||
      (q.contains('seer fish') && q.contains('price')) ||
      (q.contains('king fish') && q.contains('price'))) {
    return _a5;
  }
  // Typed Q1 — "what type of bait should be used in muttukadu backwaters"
  else if (q.contains('bait') && q.contains('muttukadu')) {
    return _a1;
  }
  // Typed Q2 — water temperature
  else if ((q.contains('water') &&
          (q.contains('warm') || q.contains('cold'))) ||
      q.contains('water too warm') ||
      q.contains('water too cold')) {
    return _a2;
  }
  // Typed Q3 — weather outlook
  else if (q.contains('weather outlook') ||
      q == _q3 ||
      (q.contains('weather') && q.contains('today'))) {
    return _a3;
  }
  // No match
  else {
    return _fallback;
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// A text-based chat UI with three hardcoded sample questions.
///
/// Designed to look like Android Messages / iMessage: user bubbles align to
/// the right (teal), bot bubbles align to the left (white / surface).
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<_Message> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// Two suggestion chips shown on the empty state.
  static const List<String> _suggestions = [
    'Ideal weather for fishing in Kasimedu Fishing Harbor (Royapuram)',
    'Market price of Vanjaram',
  ];

  void _send(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final reply = _getBotReply(trimmed);

    setState(() {
      _messages.add(_Message(text: trimmed, sender: _Sender.user));
      _messages.add(_Message(text: reply, sender: _Sender.bot));
    });

    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        titleSpacing: AppSizes.gutter,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.deepSea.withValues(alpha: 0.12),
              child: const Icon(
                Icons.directions_boat_filled_rounded,
                size: 18,
                color: AppColors.deepSea,
              ),
            ),
            const SizedBox(width: 10),
            Text('ORCA Assistant', style: theme.textTheme.titleMedium),
          ],
        ),
      ),

      body: Column(
        children: [
          // ── Scrollable area: empty-state + suggestion chips OR messages ──
          Expanded(
            child: _messages.isEmpty
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.gutter,
                      12,
                      AppSizes.gutter,
                      8,
                    ),
                    children: [
                      _EmptyState(isDark: isDark),
                      const SizedBox(height: 16),
                      _SuggestionChips(
                        suggestions: _suggestions,
                        onSelected: _send,
                      ),
                    ],
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.gutter,
                      vertical: 12,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _ChatBubble(message: msg, isDark: isDark);
                    },
                  ),
          ),

          // ── Input bar — only fixed-height widget outside Expanded ─────
          SafeArea(
            top: false,
            child: _InputBar(controller: _controller, onSend: _send),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

/// Empty state shown before the first message is sent.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.gutter * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: AppColors.deepSea.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Ask ORCA a question',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Tap one of the suggestions below or type your question.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Three tappable suggestion chips — only shown before any message is sent.
class _SuggestionChips extends StatelessWidget {
  const _SuggestionChips({
    required this.suggestions,
    required this.onSelected,
  });

  final List<String> suggestions;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.gutter,
        0,
        AppSizes.gutter,
        8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final s in suggestions)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: Text(
                  s,
                  textAlign: TextAlign.start,
                  style: const TextStyle(fontSize: 14),
                ),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  foregroundColor: AppColors.deepSea,
                  side: BorderSide(
                    color: AppColors.deepSea.withValues(alpha: 0.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  ),
                ),
                onPressed: () => onSelected(s),
              ),
            ),
        ],
      ),
    );
  }
}

/// A single chat bubble — right-aligned (teal) for user, left-aligned for bot.
class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.isDark});

  final _Message message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.sender == _Sender.user;

    final bubbleColor = isUser
        ? AppColors.deepSea
        : (isDark ? AppColors.surfaceDark : AppColors.surface);

    final textColor = isUser
        ? Colors.white
        : (isDark ? AppColors.inkDark : AppColors.ink);

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Bot avatar dot
          if (!isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.deepSea.withValues(alpha: 0.12),
              child: const Icon(
                Icons.directions_boat_filled_rounded,
                size: 14,
                color: AppColors.deepSea,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: borderRadius,
                border: isUser
                    ? null
                    : Border.all(
                        color: isDark
                            ? AppColors.hairlineDark
                            : AppColors.hairline,
                      ),
              ),
              child: Text(
                message.text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 15.5,
                  color: textColor,
                  height: 1.4,
                ),
              ),
            ),
          ),

          // User avatar dot
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.deepSea.withValues(alpha: 0.18),
              child: const Icon(
                Icons.person_rounded,
                size: 14,
                color: AppColors.deepSea,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pinned text input bar at the bottom.
class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.onSend});

  final TextEditingController controller;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.gutter,
        8,
        AppSizes.gutter,
        12,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: 'Type your question…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radius),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: onSend,
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.deepSea,
            borderRadius: BorderRadius.circular(AppSizes.radius),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSizes.radius),
              onTap: () => onSend(controller.text),
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
