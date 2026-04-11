import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/hirex_loader.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/messaging_models.dart';
import '../providers/messaging_providers.dart';

class ChatScreenPage extends ConsumerStatefulWidget {
  const ChatScreenPage({super.key, required this.threadId});
  final String threadId;

  @override
  ConsumerState<ChatScreenPage> createState() => _ChatScreenPageState();
}

class _ChatScreenPageState extends ConsumerState<ChatScreenPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _typingDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _typingDebounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= 100) {
      ref.read(chatProvider(widget.threadId).notifier).loadMore();
    }
  }

  void _onTextChanged(String value) {
    _typingDebounce?.cancel();
    if (value.isNotEmpty) {
      ref.read(chatProvider(widget.threadId).notifier).sendTypingIndicator();
      _typingDebounce = Timer(const Duration(milliseconds: 1500), () {});
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await ref.read(chatProvider(widget.threadId).notifier).sendMessage(text);
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
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(chatProvider(widget.threadId));
    final currentUser = ref.watch(authNotifierProvider).valueOrNull;
    final currentUserId = currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chat'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: chatAsync.whenData((s) => s.isConnected
              ? const SizedBox.shrink()
              : LinearProgressIndicator(
                  backgroundColor: AppColors.surface,
                  color: AppColors.warning,
                )).valueOrNull ?? const SizedBox.shrink(),
        ),
      ),
      body: chatAsync.when(
        loading: () => const Center(child: HireXLoader()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (state) => Column(
          children: [
            // Reconnecting banner
            if (!state.isConnected)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                color: AppColors.warning.withOpacity(0.2),
                child: Text(
                  'Reconnecting...',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.warning),
                  textAlign: TextAlign.center,
                ),
              ),

            // Messages list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: state.messages.length,
                itemBuilder: (_, i) {
                  final msg = state.messages[i];
                  final isMine = msg.senderId == currentUserId;
                  return _MessageBubble(message: msg, isMine: isMine);
                },
              ),
            ),

            // Typing indicator
            if (state.isTyping)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Row(
                  children: [
                    _TypingDots(),
                    const SizedBox(width: 8),
                    Text('typing...', style: AppTextStyles.labelSmall),
                  ],
                ),
              ),

            // Input bar
            _InputBar(
              controller: _controller,
              onChanged: _onTextChanged,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});
  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMine ? Colors.white : AppColors.onBackground,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    color: isMine ? Colors.white70 : AppColors.onSurface.withOpacity(0.5),
                    fontSize: 10,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  _StatusIcon(status: message.status, isRead: message.isRead),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status, required this.isRead});
  final MessageStatus status;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    if (status == MessageStatus.sending) {
      return const SizedBox(
        width: 12, height: 12,
        child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white70),
      );
    }
    if (status == MessageStatus.failed) {
      return const Icon(Icons.error_outline, size: 12, color: Colors.redAccent);
    }
    return Icon(
      isRead ? Icons.done_all : Icons.done,
      size: 12,
      color: isRead ? Colors.lightBlueAccent : Colors.white70,
    );
  }
}

class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final opacity = ((_controller.value * 3 - i).clamp(0.0, 1.0));
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6, height: 6,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      );
}

class _InputBar extends StatefulWidget {
  const _InputBar({
    required this.controller,
    required this.onChanged,
    required this.onSend,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      final has = widget.controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                onChanged: widget.onChanged,
                maxLength: 1000,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: IconButton(
                onPressed: _hasText ? widget.onSend : null,
                icon: const Icon(Icons.send_rounded),
                color: _hasText ? AppColors.primary : AppColors.onSurface.withOpacity(0.3),
                style: IconButton.styleFrom(
                  backgroundColor: _hasText ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      );
}
