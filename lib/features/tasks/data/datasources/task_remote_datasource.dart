import 'package:dio/dio.dart';
import '../models/task_model.dart';
import '../../../submissions/data/models/submission_model.dart';

class TaskRemoteDataSource {
  TaskRemoteDataSource({required Dio dio}) : _dio = dio;
  final Dio _dio;

  Future<PaginatedTasksModel> getTasks({
    int page = 1,
    int pageSize = 20,
    String? domain,
    String? difficulty,
    String sort = 'latest',
    String? search,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      'sort': sort,
    };
    if (domain != null) params['domain'] = domain;
    if (difficulty != null) params['difficulty'] = difficulty;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final response = await _dio.get('/api/v1/tasks', queryParameters: params);
    return PaginatedTasksModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TaskModel> getTask(String id) async {
    final response = await _dio.get('/api/v1/tasks/$id');
    return TaskModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> incrementView(String id) async {
    await _dio.post('/api/v1/tasks/$id/view');
  }

  Future<List<TaskModel>> getBookmarks() async {
    final response = await _dio.get('/api/v1/bookmarks');
    return (response.data as List<dynamic>)
        .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<bool> toggleBookmark(String taskId) async {
    final response = await _dio.post('/api/v1/bookmarks', data: {'task_id': taskId});
    return response.data['bookmarked'] as bool;
  }

  Future<SubmissionModel> createSubmission(String taskId) async {
    final response = await _dio.post('/api/v1/submissions', data: {'task_id': taskId});
    return SubmissionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SubmissionModel> getSubmission(String id) async {
    final response = await _dio.get('/api/v1/submissions/$id');
    return SubmissionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SubmissionModel> updateSubmission(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/api/v1/submissions/$id', data: data);
    return SubmissionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SubmissionModel> submitSubmission(String id) async {
    final response = await _dio.post('/api/v1/submissions/$id/submit');
    return SubmissionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteSubmission(String id) async {
    await _dio.delete('/api/v1/submissions/$id');
  }

  Future<List<SubmissionModel>> getMySubmissions({String? status}) async {
    final params = <String, dynamic>{'page': 1, 'page_size': 100};
    if (status != null) params['status'] = status;
    final response = await _dio.get('/api/v1/submissions/my', queryParameters: params);
    final data = response.data as Map<String, dynamic>;
    return (data['items'] as List<dynamic>)
        .map((e) => SubmissionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> getPresignedUrl(String filename, String contentType) async {
    final response = await _dio.get(
      '/api/v1/upload/presigned-url',
      queryParameters: {'filename': filename, 'content_type': contentType},
    );
    return response.data['upload_url'] as String;
  }

  Future<String> getPresignedFileUrl(String filename, String contentType) async {
    final response = await _dio.get(
      '/api/v1/upload/presigned-url',
      queryParameters: {'filename': filename, 'content_type': contentType},
    );
    return response.data['file_url'] as String;
  }

  Future<Map<String, dynamic>> getLeaderboard(String taskId, {int page = 1}) async {
    final response = await _dio.get(
      '/api/v1/tasks/$taskId/leaderboard',
      queryParameters: {'page': page, 'page_size': 20},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPOWProfile() async {
    final response = await _dio.get('/api/v1/profile/me');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSkillScores() async {
    final response = await _dio.get('/api/v1/scores/me');
    return response.data as Map<String, dynamic>;
  }

  Future<void> seedSkillScores() async {
    await _dio.post('/api/v1/scores/seed');
  }

  Future<List<Map<String, dynamic>>> getBadges() async {
    final response = await _dio.get('/api/v1/badges/me');
    return (response.data as List<dynamic>).cast<Map<String, dynamic>>();
  }
}
