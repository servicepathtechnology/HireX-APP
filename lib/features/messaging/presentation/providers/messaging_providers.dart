import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/datasources/messaging_remote_datasource.dart';
import '../../data/models/messaging_models.dart';

final dioClientProvider = Provider<DioClient>((ref) => DioClient());

final messagingDatasourceProvider = Provider<MessagingRemoteDatasource>(
  (ref) => MessagingRemoteDatasource(ref.watch(dioClientProvider)),
);

// ── Thread list ───────────────────────────────────────────────────────────────

final threadListProvider = AsyncNotifierProvider<ThreadListNotifier, List<MessageThread>>(
  ThreadListNotifier.new,
);

class ThreadListNotifier extends AsyncNotifier<List<MessageThread>> {
  @override
  Future<List<MessageThread>> build() async {
    final ds = ref.watch(messagingDatasourceProvider);
    return ds.getThreads();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(messagingDatasourceProvider).getThreads());
  }

  void markThreadRead(String threadId) {
    state.whenData((threads) {
      state = AsyncData(
        threads.map((t) => t.id == threadId
            ? MessageThread(
                id: t.id, recruiterId: t.recruiterId, candidateId: t.candidateId,
                taskId: t.taskId, lastMessageAt: t.lastMessageAt,
                lastMessagePreview: t.lastMessagePreview, unreadCount: 0,
                isActive: t.isActive, createdAt: t.createdAt,
                otherPartyName: t.otherPartyName, otherPartyAvatar: t.otherPartyAvatar,
                taskTitle: t.taskTitle,
              )
            : t).toList(),
      );
    });
  }
}

// ── Chat state ────────────────────────────────────────────────────────────────

class ChatState {
  final List<ChatMessage> messages;
  final bool isConnected;
  final bool isTyping;
  final bool hasMore;
  final int page;

  const ChatState({
    this.messages = const [],
    this.isConnected = false,
    this.isTyping = false,
    this.hasMore = false,
    this.page = 1,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isConnected,
    bool? isTyping,
    bool? hasMore,
    int? page,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        isConnected: isConnected ?? this.isConnected,
        isTyping: isTyping ?? this.isTyping,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
      );
}

final chatProvider = AsyncNotifierProviderFamily<ChatNotifier, ChatState, String>(
  ChatNotifier.new,
);

class ChatNotifier extends FamilyAsyncNotifier<ChatState, String> {
  WebSocketChannel? _channel;
  Timer? _typingTimer;
  String get _threadId => arg;

  @override
  Future<ChatState> build(String threadId) async {
    ref.onDispose(() {
      _channel?.sink.close();
      _typingTimer?.cancel();
    });

    final ds = ref.read(messagingDatasourceProvider);
    final data = await ds.getThread(threadId);
    final messages = (data['messages'] as List)
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
    final hasMore = data['has_more'] as bool? ?? false;

    // Mark as read
    await ds.markRead(threadId);
    ref.read(threadListProvider.notifier).markThreadRead(threadId);

    // Connect WebSocket
    _connectWebSocket();

    return ChatState(messages: messages, isConnected: false, hasMore: hasMore);
  }

  void _connectWebSocket() {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
    final wsUrl = baseUrl.replaceFirst('http', 'ws').replaceFirst('https', 'wss');

    // We need the JWT token for WS auth — get from Firebase
    _getToken().then((token) {
      if (token == null) return;
      try {
        _channel = WebSocketChannel.connect(
          Uri.parse('$wsUrl/api/v1/ws/messages?token=$token'),
        );
        state.whenData((s) => state = AsyncData(s.copyWith(isConnected: true)));

        _channel!.stream.listen(
          (data) => _handleWsMessage(data as String),
          onDone: () {
            state.whenData((s) => state = AsyncData(s.copyWith(isConnected: false)));
            // Auto-reconnect after 2s
            Future.delayed(const Duration(seconds: 2), _connectWebSocket);
          },
          onError: (_) {
            state.whenData((s) => state = AsyncData(s.copyWith(isConnected: false)));
            Future.delayed(const Duration(seconds: 2), _connectWebSocket);
          },
        );

        // Heartbeat
        Timer.periodic(const Duration(seconds: 30), (_) {
          _channel?.sink.add(jsonEncode({'type': 'ping'}));
        });
      } catch (e) {
        debugPrint('[WS] Connect failed: $e');
      }
    });
  }

  Future<String?> _getToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      return user?.getIdToken();
    } catch (_) {
      return null;
    }
  }

  void _handleWsMessage(String raw) {
    try {
      final msg = jsonDecode(raw) as Map<String, dynamic>;
      final type = msg['type'] as String?;

      if (type == 'message') {
        final chatMsg = ChatMessage.fromJson(msg['data'] as Map<String, dynamic>);
        if (chatMsg.threadId == _threadId) {
          state.whenData((s) {
            state = AsyncData(s.copyWith(messages: [...s.messages, chatMsg]));
          });
        }
      } else if (type == 'typing') {
        final data = msg['data'] as Map<String, dynamic>;
        if (data['thread_id'] == _threadId) {
          state.whenData((s) => state = AsyncData(s.copyWith(isTyping: data['is_typing'] as bool? ?? false)));
          _typingTimer?.cancel();
          _typingTimer = Timer(const Duration(seconds: 3), () {
            state.whenData((s) => state = AsyncData(s.copyWith(isTyping: false)));
          });
        }
      } else if (type == 'read') {
        final data = msg['data'] as Map<String, dynamic>;
        if (data['thread_id'] == _threadId) {
          state.whenData((s) {
            final updated = s.messages.map((m) => m.copyWith(status: MessageStatus.sent)).toList();
            state = AsyncData(s.copyWith(messages: updated));
          });
        }
      }
    } catch (e) {
      debugPrint('[WS] Parse error: $e');
    }
  }

  Future<void> sendMessage(String content) async {
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = ChatMessage(
      id: tempId,
      threadId: _threadId,
      senderId: 'me',
      content: content,
      isRead: false,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );

    // Optimistic add
    state.whenData((s) => state = AsyncData(s.copyWith(messages: [...s.messages, tempMsg])));

    try {
      final ds = ref.read(messagingDatasourceProvider);
      final sent = await ds.sendMessage(_threadId, content);
      state.whenData((s) {
        final updated = s.messages.map((m) => m.id == tempId ? sent : m).toList();
        state = AsyncData(s.copyWith(messages: updated));
      });
    } catch (e) {
      state.whenData((s) {
        final updated = s.messages
            .map((m) => m.id == tempId ? m.copyWith(status: MessageStatus.failed) : m)
            .toList();
        state = AsyncData(s.copyWith(messages: updated));
      });
    }
  }

  void sendTypingIndicator() {
    _channel?.sink.add(jsonEncode({
      'type': 'typing',
      'data': {'thread_id': _threadId, 'is_typing': true},
    }));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore) return;

    final ds = ref.read(messagingDatasourceProvider);
    final data = await ds.getThread(_threadId, page: current.page + 1);
    final older = (data['messages'] as List)
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();

    state.whenData((s) => state = AsyncData(s.copyWith(
      messages: [...older, ...s.messages],
      hasMore: data['has_more'] as bool? ?? false,
      page: s.page + 1,
    )));
  }
}

// ── Unread count ──────────────────────────────────────────────────────────────

final unreadCountProvider = FutureProvider<int>((ref) async {
  final ds = ref.watch(messagingDatasourceProvider);
  return ds.getUnreadCount();
});
