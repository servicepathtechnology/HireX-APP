import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/messaging_models.dart';

class MessagingRemoteDatasource {
  MessagingRemoteDatasource(this._client);
  final DioClient _client;

  Future<MessageThread> createThread(String candidateId, String taskId) async {
    final res = await _client.instance.post('/api/v1/messages/threads', data: {
      'candidate_id': candidateId,
      'task_id': taskId,
    });
    return MessageThread.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<MessageThread>> getThreads() async {
    final res = await _client.instance.get('/api/v1/messages/threads');
    return (res.data as List).map((e) => MessageThread.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> getThread(String threadId, {int page = 1}) async {
    final res = await _client.instance.get(
      '/api/v1/messages/threads/$threadId',
      queryParameters: {'page': page, 'page_size': 30},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<ChatMessage> sendMessage(String threadId, String content) async {
    final res = await _client.instance.post(
      '/api/v1/messages/threads/$threadId/send',
      data: {'content': content},
    );
    return ChatMessage.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> markRead(String threadId) async {
    await _client.instance.put('/api/v1/messages/threads/$threadId/read');
  }

  Future<int> getUnreadCount() async {
    final res = await _client.instance.get('/api/v1/messages/unread-count');
    return (res.data as Map<String, dynamic>)['unread_count'] as int? ?? 0;
  }
}
