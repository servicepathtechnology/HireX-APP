import 'package:flutter/foundation.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';

/// Represents a pending deep link destination to be consumed after auth.
class PendingDeepLink {
  final String route;
  final Map<String, String> params;

  const PendingDeepLink({required this.route, required this.params});
}

/// Callback type for when a deep link is received.
typedef DeepLinkCallback = void Function(PendingDeepLink link);

class DeepLinkHandler {
  DeepLinkHandler._();
  static final DeepLinkHandler instance = DeepLinkHandler._();

  DeepLinkCallback? _onLinkReceived;

  /// Initialize Branch SDK. Call once from main app widget.
  Future<void> initialize({DeepLinkCallback? onLinkReceived}) async {
    _onLinkReceived = onLinkReceived;
    try {
      await FlutterBranchSdk.init(enableLogging: kDebugMode);
      FlutterBranchSdk.listSession().listen(_handleLinkData);
    } catch (e) {
      debugPrint('[DeepLink] Branch init failed: $e');
    }
  }

  void setCallback(DeepLinkCallback callback) {
    _onLinkReceived = callback;
  }

  void _handleLinkData(Map<dynamic, dynamic> data) {
    if (data['+clicked_branch_link'] != true) return;
    final link = _parseRoute(data);
    if (link != null) {
      debugPrint('[DeepLink] Received: ${link.route} ${link.params}');
      _onLinkReceived?.call(link);
    }
  }

  PendingDeepLink? _parseRoute(Map<dynamic, dynamic> data) {
    final taskId = data['task_id'] as String?;
    final userId = data['user_id'] as String?;
    final submissionId = data['submission_id'] as String?;
    final referralCode = data['referral_code'] as String?;
    final matchId = data['match_id'] as String?;

    // Part 1 — 1v1 challenge match deep links
    if (matchId != null) {
      final view = data['view'] as String?;
      if (view == 'result') {
        return PendingDeepLink(
          route: '/challenges/1v1/:matchId/result',
          params: {'matchId': matchId},
        );
      }
      if (view == 'watch') {
        return PendingDeepLink(
          route: '/challenges/1v1/:matchId/watch',
          params: {'matchId': matchId},
        );
      }
      return PendingDeepLink(
        route: '/challenges/1v1/:matchId',
        params: {'matchId': matchId},
      );
    }

    if (taskId != null) {
      return PendingDeepLink(
        route: '/candidate/tasks/:taskId',
        params: {'taskId': taskId},
      );
    }
    if (submissionId != null) {
      return PendingDeepLink(
        route: '/candidate/submissions/:submissionId/score-explanation',
        params: {'submissionId': submissionId},
      );
    }
    if (userId != null) {
      return PendingDeepLink(
        route: '/profile/:userId',
        params: {'userId': userId},
      );
    }
    if (referralCode != null) {
      return PendingDeepLink(
        route: '/auth/signup/:referralCode',
        params: {'referralCode': referralCode},
      );
    }
    return null;
  }

  /// Create a shareable Branch link for a task.
  Future<String?> createTaskLink(
    String taskId,
    String taskTitle,
    String domain,
  ) async {
    try {
      final buo = BranchUniversalObject(
        canonicalIdentifier: 'task/$taskId',
        title: taskTitle,
        contentDescription: 'HireX Task — $domain',
        contentMetadata: BranchContentMetaData()
          ..addCustomMetadata('task_id', taskId),
      );
      final lp = BranchLinkProperties()
        ..addControlParam(r'$desktop_url', 'https://hirex.app/tasks/$taskId')
        ..addControlParam(r'$fallback_url', 'https://hirex.app/tasks/$taskId');
      final response =
          await FlutterBranchSdk.getShortUrl(buo: buo, linkProperties: lp);
      return response.success ? response.result : null;
    } catch (e) {
      debugPrint('[DeepLink] createTaskLink failed: $e');
      return null;
    }
  }

  /// Create a shareable Branch link for a score card.
  Future<String?> createScoreLink(
    String submissionId,
    String taskTitle,
    double score,
  ) async {
    try {
      final buo = BranchUniversalObject(
        canonicalIdentifier: 'score/$submissionId',
        title: 'I scored ${score.toInt()}/100 on $taskTitle',
        contentDescription: 'Check out my HireX score!',
        imageUrl:
            'https://api.hirex.app/api/v1/og/score-card/$submissionId',
        contentMetadata: BranchContentMetaData()
          ..addCustomMetadata('submission_id', submissionId),
      );
      final lp = BranchLinkProperties()
        ..addControlParam(
            r'$desktop_url', 'https://hirex.app/scores/$submissionId');
      final response =
          await FlutterBranchSdk.getShortUrl(buo: buo, linkProperties: lp);
      return response.success ? response.result : null;
    } catch (e) {
      debugPrint('[DeepLink] createScoreLink failed: $e');
      return null;
    }
  }

  /// Create a shareable Branch link for a match result (Part 1).
  Future<String?> createMatchResultLink(
    String matchId,
    String domain,
    String result, // win | loss | draw
  ) async {
    try {
      final verb = result == 'draw'
          ? 'drew'
          : result == 'win'
              ? 'won'
              : 'lost';
      final buo = BranchUniversalObject(
        canonicalIdentifier: 'match/$matchId/result',
        title: 'I just $verb a 1v1 $domain challenge on HireX!',
        contentDescription: 'Challenge me on HireX — prove your skills.',
        contentMetadata: BranchContentMetaData()
          ..addCustomMetadata('match_id', matchId)
          ..addCustomMetadata('view', 'result'),
      );
      final lp = BranchLinkProperties()
        ..addControlParam(
            r'$desktop_url',
            'https://hirex.app/challenges/1v1/$matchId/result');
      final response =
          await FlutterBranchSdk.getShortUrl(buo: buo, linkProperties: lp);
      return response.success ? response.result : null;
    } catch (e) {
      debugPrint('[DeepLink] createMatchResultLink failed: $e');
      return null;
    }
  }

  /// Create a referral link.
  Future<String?> createReferralLink(
    String referralCode,
    String userName,
  ) async {
    try {
      final buo = BranchUniversalObject(
        canonicalIdentifier: 'ref/$referralCode',
        title: '$userName invited you to HireX',
        contentDescription: 'Prove your skills. Get hired. No resumes needed.',
        contentMetadata: BranchContentMetaData()
          ..addCustomMetadata('referral_code', referralCode),
      );
      final lp = BranchLinkProperties()
        ..addControlParam(
            r'$desktop_url', 'https://hirex.app/ref/$referralCode');
      final response =
          await FlutterBranchSdk.getShortUrl(buo: buo, linkProperties: lp);
      return response.success ? response.result : null;
    } catch (e) {
      debugPrint('[DeepLink] createReferralLink failed: $e');
      return null;
    }
  }
}
