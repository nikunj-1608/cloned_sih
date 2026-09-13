import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// A small floating chat button, bottom-right, that expands into a typed
/// question/answer box.
///
/// This is intentionally separate from [VoiceButton]/[AskScreen] (the
/// voice-first flow wired to the future `POST /v1/chat` agent). This widget
/// is fully offline: it matches the typed question against a fixed list of
/// question/answer pairs below and returns the answer string as-is.
///
/// To change what the bot knows, edit only the `_qa` list — nothing else
/// needs to change.
class ChatBubble extends StatefulWidget {
  const ChatBubble({super.key});

  /// The 3 question/answer pairs. Edit the strings here only.
  ///
  /// Matching is exact (case-insensitive, surrounding whitespace ignored).
  static const List<(String, String)> _qa = [
    (
      'What is the weather today?',
      'The weather today is sunny with a light breeze.',
    ),
    (
      'Is it safe to go fishing?',
      'Yes, sea conditions are currently within safe limits.',
    ),
    (
      'Where is the nearest port?',
      'The nearest port is Rameswaram, approximately 6 km away.',
    ),
  ];

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatMessage {
  const _ChatMessage(this.text, {required this.isUser});
  final String text;
  final bool isUser;
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _open = false;
  final List<_ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// The if/else-if ladder. Exact-match only, case-insensitive.
  String _getBotReply(String question) {
    final q = question.trim().toLowerCase();
    final qa = ChatBubble._qa;

    if (q == qa[0].$1.toLowerCase()) {
      return qa[0].$2;
    } else if (q == qa[1].$1.toLowerCase()) {
      return qa[1].$2;
    } else if (q == qa[2].$1.toLowerCase()) {
      return qa[2].$2;
    } else {
      return "Sorry, didnt get it.Please enter the question once again";
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final reply = _getBotReply(text);

    setState(() {
      _messages.add(_ChatMessage(text, isUser: true));
      _messages.add(_ChatMessage(reply, isUser: false));
      _controller.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_open) ...[
          _ChatPanel(
            messages: _messages,
            controller: _controller,
            scrollController: _scrollController,
            onSend: _send,
            onClose: () => setState(() => _open = false),
          ),
          const SizedBox(height: 12),
        ],
        Semantics(
          button: true,
          label: _open ? 'Close chat' : 'Open chat',
          child: FloatingActionButton(
            backgroundColor: AppColors.deepSea,
            onPressed: () => setState(() => _open = !_open),
            child: Icon(
              _open ? Icons.close_rounded : Icons.chat_bubble_rounded,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatPanel extends StatelessWidget {
  const _ChatPanel({
    required this.messages,
    required this.controller,
    required this.scrollController,
    required this.onSend,
    required this.onClose,
  });

  final List<_ChatMessage> messages;
  final TextEditingController controller;
  final ScrollController scrollController;
  final VoidCallback onSend;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(AppSizes.radius),
      color: theme.colorScheme.surface,
      child: Container(
        width: 300,
        height: 380,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radius),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.support_agent_rounded,
                    color: AppColors.deepSea, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Ask a question',
                      style: theme.textTheme.titleMedium),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: onClose,
                  splashRadius: 18,
                ),
              ],
            ),
            const Divider(height: 16),
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Text(
                        'Ask me something to get started.',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final m = messages[index];
                        return Align(
                          alignment: m.isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            constraints:
                                const BoxConstraints(maxWidth: 220),
                            decoration: BoxDecoration(
                              color: m.isUser
                                  ? AppColors.deepSea
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              m.text,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: m.isUser ? Colors.white : null,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Type your question…',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: onSend,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.deepSea,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}