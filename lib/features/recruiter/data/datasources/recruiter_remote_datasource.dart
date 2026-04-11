import 'package:dio/dio.dart';
import '../models/recruiter_models.dart';

class RecruiterRemoteDataSource {
  RecruiterRemoteDataSource({required this.dio});
  final Dio dio;

  // ── Dashboard ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDashboard() async {
    final res = await dio.get('/api/v1/recruiter/dashboard');
    return res.data as Map<String, dynamic>;
  }

  // ── Tasks ───────────────────────────────────────────────────────────────────

  Future<RecruiterTaskModel> createTask(Map<String, dynamic> data) async {
    final res = await dio.post('/api/v1/recruiter/tasks', data: data);
    return RecruiterTaskModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<RecruiterTaskModel> updateTask(String taskId, Map<String, dynamic> data) async {
    final res = await dio.put('/api/v1/recruiter/tasks/$taskId', data: data);
    return RecruiterTaskModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<RecruiterTaskModel>> getMyTasks({String? status}) async {
    final res = await dio.get('/api/v1/recruiter/tasks', queryParameters: {
      if (status != null) 'status': status,
    });
    final data = res.data as Map<String, dynamic>;
    return (data['items'] as List).map((e) => RecruiterTaskModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<RecruiterTaskModel> getTask(String taskId) async {
    final res = await dio.get('/api/v1/recruiter/tasks/$taskId');
    return RecruiterTaskModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<RecruiterTaskModel> pauseTask(String taskId) async {
    final res = await dio.put('/api/v1/recruiter/tasks/$taskId/pause');
    return RecruiterTaskModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<RecruiterTaskModel> closeTask(String taskId) async {
    final res = await dio.put('/api/v1/recruiter/tasks/$taskId/close');
    return RecruiterTaskModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteTask(String taskId) async {
    await dio.delete('/api/v1/recruiter/tasks/$taskId');
  }

  Future<RecruiterTaskModel> duplicateTask(String taskId) async {
    final res = await dio.post('/api/v1/recruiter/tasks/$taskId/duplicate');
    return RecruiterTaskModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getTaskStats(String taskId) async {
    final res = await dio.get('/api/v1/recruiter/tasks/$taskId/stats');
    return res.data as Map<String, dynamic>;
  }

  // ── Submissions ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getTaskSubmissions(
    String taskId, {
    String? status,
    String sort = 'most_recent',
    double? scoreMin,
    double? scoreMax,
    int page = 1,
  }) async {
    final res = await dio.get(
      '/api/v1/recruiter/tasks/$taskId/submissions',
      queryParameters: {
        if (status != null) 'status': status,
        'sort': sort,
        if (scoreMin != null) 'score_min': scoreMin,
        if (scoreMax != null) 'score_max': scoreMax,
        'page': page,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<RecruiterSubmissionModel> getSubmission(String submissionId) async {
    final res = await dio.get('/api/v1/recruiter/submissions/$submissionId');
    return RecruiterSubmissionModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<RecruiterSubmissionModel> scoreSubmission(
    String submissionId,
    Map<String, dynamic> data,
  ) async {
    final res = await dio.put('/api/v1/recruiter/submissions/$submissionId/score', data: data);
    return RecruiterSubmissionModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<RecruiterSubmissionModel> shortlistSubmission(String submissionId) async {
    final res = await dio.put('/api/v1/recruiter/submissions/$submissionId/shortlist');
    return RecruiterSubmissionModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<RecruiterSubmissionModel> rejectSubmission(String submissionId) async {
    final res = await dio.put('/api/v1/recruiter/submissions/$submissionId/reject');
    return RecruiterSubmissionModel.fromJson(res.data as Map<String, dynamic>);
  }

  // ── Pipeline ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getPipelineBoard({String? taskId}) async {
    final res = await dio.get('/api/v1/recruiter/pipeline', queryParameters: {
      if (taskId != null) 'task_id': taskId,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<PipelineEntryModel> updatePipelineStage(String entryId, String stage) async {
    final res = await dio.put('/api/v1/recruiter/pipeline/$entryId/stage', data: {'stage': stage});
    return PipelineEntryModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PipelineEntryModel> updatePipelineNotes(String entryId, String notes) async {
    final res = await dio.put('/api/v1/recruiter/pipeline/$entryId/notes', data: {'recruiter_notes': notes});
    return PipelineEntryModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> removeFromPipeline(String entryId) async {
    await dio.delete('/api/v1/recruiter/pipeline/$entryId');
  }

  // ── Billing ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createOrder(String taskId, String tier) async {
    final res = await dio.post('/api/v1/billing/create-order', data: {
      'task_id': taskId,
      'tier': tier,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final res = await dio.post('/api/v1/billing/verify-payment', data: {
      'order_id': orderId,
      'payment_id': paymentId,
      'signature': signature,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<List<PaymentModel>> getPaymentHistory() async {
    final res = await dio.get('/api/v1/billing/history');
    final data = res.data as Map<String, dynamic>;
    return (data['items'] as List).map((e) => PaymentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Analytics ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAnalytics({String? taskId}) async {
    final path = taskId != null
        ? '/api/v1/recruiter/analytics/$taskId'
        : '/api/v1/recruiter/analytics';
    final res = await dio.get(path);
    return res.data as Map<String, dynamic>;
  }

  // ── Notifications ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getNotifications({int page = 1}) async {
    final res = await dio.get('/api/v1/notifications', queryParameters: {'page': page});
    return res.data as Map<String, dynamic>;
  }

  Future<int> getUnreadCount() async {
    final res = await dio.get('/api/v1/notifications/unread-count');
    return (res.data as Map<String, dynamic>)['count'] as int? ?? 0;
  }

  Future<void> markNotificationRead(String notificationId) async {
    await dio.put('/api/v1/notifications/$notificationId/read');
  }

  Future<void> markAllNotificationsRead() async {
    await dio.put('/api/v1/notifications/read-all');
  }
}
