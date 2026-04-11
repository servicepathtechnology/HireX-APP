import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/network/dio_client.dart';

final _dioProvider = Provider<DioClient>((ref) => DioClient());

// ── AI Job polling ────────────────────────────────────────────────────────────

enum AIJobPollState { polling, completed, failed, timeout }

class AIJobData {
  final Map<String, dynamic>? job;
  final AIJobPollState pollState;
  final int pollCount;

  const AIJobData({this.job, required this.pollState, this.pollCount = 0});
}

final aiJobProvider = AsyncNotifierProviderFamily<AIJobNotifier, AIJobData, String>(
  AIJobNotifier.new,
);

class AIJobNotifier extends FamilyAsyncNotifier<AIJobData, String> {
  Timer? _pollTimer;
  int _pollCount = 0;
  int _failCount = 0;
  static const _maxPolls = 20;
  static const _maxFails = 3;

  @override
  Future<AIJobData> build(String jobId) async {
    ref.onDispose(() => _pollTimer?.cancel());
    final data = await _fetchJob(jobId);
    if (data == null) {
      return const AIJobData(pollState: AIJobPollState.failed);
    }
    final status = data['status'] as String? ?? '';
    if (status == 'completed') {
      return AIJobData(job: data, pollState: AIJobPollState.completed);
    }
    if (status == 'failed') {
      return AIJobData(job: data, pollState: AIJobPollState.failed);
    }
    _startPolling(jobId);
    return AIJobData(job: data, pollState: AIJobPollState.polling);
  }

  Future<Map<String, dynamic>?> _fetchJob(String jobId) async {
    try {
      final res = await ref.read(_dioProvider).instance.get('/api/v1/ai/jobs/$jobId');
      _failCount = 0;
      return res.data as Map<String, dynamic>;
    } catch (_) {
      _failCount++;
      return null;
    }
  }

  void _startPolling(String jobId) {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      _pollCount++;

      // Timeout after 20 polls (~60s)
      if (_pollCount >= _maxPolls) {
        _pollTimer?.cancel();
        state = AsyncData(AIJobData(
          job: state.valueOrNull?.job,
          pollState: AIJobPollState.timeout,
          pollCount: _pollCount,
        ));
        return;
      }

      final data = await _fetchJob(jobId);

      // Stop polling after 3 consecutive network failures
      if (data == null && _failCount >= _maxFails) {
        _pollTimer?.cancel();
        state = AsyncData(AIJobData(
          job: state.valueOrNull?.job,
          pollState: AIJobPollState.failed,
          pollCount: _pollCount,
        ));
        return;
      }

      if (data != null) {
        final status = data['status'] as String? ?? '';
        if (status == 'completed') {
          _pollTimer?.cancel();
          state = AsyncData(AIJobData(job: data, pollState: AIJobPollState.completed, pollCount: _pollCount));
        } else if (status == 'failed') {
          _pollTimer?.cancel();
          state = AsyncData(AIJobData(job: data, pollState: AIJobPollState.failed, pollCount: _pollCount));
        } else {
          state = AsyncData(AIJobData(job: data, pollState: AIJobPollState.polling, pollCount: _pollCount));
        }
      }
    });
  }
}

// ── AI Review data ────────────────────────────────────────────────────────────

final aiReviewProvider = FutureProviderFamily<Map<String, dynamic>, String>((ref, submissionId) async {
  final res = await ref.read(_dioProvider).instance.get('/api/v1/ai/review/$submissionId');
  return res.data as Map<String, dynamic>;
});

// ── Score overrides ───────────────────────────────────────────────────────────

final scoreOverridesProvider = StateProviderFamily<Map<String, double>, String>(
  (ref, submissionId) => {},
);

// ── Enqueue AI scoring ────────────────────────────────────────────────────────

Future<String?> enqueueAIScoring(DioClient client, String submissionId) async {
  try {
    final res = await client.instance.post('/api/v1/ai/score/$submissionId');
    return (res.data as Map<String, dynamic>)['job_id'] as String?;
  } catch (_) {
    return null;
  }
}

Future<bool> approveAIScores(
  DioClient client,
  String submissionId, {
  Map<String, double>? overrides,
  String? feedback,
}) async {
  try {
    await client.instance.post('/api/v1/ai/approve/$submissionId', data: {
      if (overrides != null && overrides.isNotEmpty) 'overrides': overrides,
      if (feedback != null) 'recruiter_feedback': feedback,
    });
    return true;
  } catch (_) {
    return false;
  }
}
