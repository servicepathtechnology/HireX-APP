import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

/// Centralised analytics service — wraps Mixpanel.
/// Never call Mixpanel directly from widgets; always use this class.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  Mixpanel? _mixpanel;
  bool _trackingEnabled = true;

  Future<void> initialize() async {
    final token = dotenv.env['MIXPANEL_TOKEN'] ?? '';
    if (token.isEmpty || kDebugMode) return;
    try {
      _mixpanel = await Mixpanel.init(token, optOutTrackingDefault: false, trackAutomaticEvents: false);
    } catch (e) {
      debugPrint('[Analytics] Init failed: $e');
    }
  }

  void setTrackingEnabled(bool enabled) {
    _trackingEnabled = enabled;
    if (!enabled) _mixpanel?.optOutTracking();
  }

  void identify(String userId, {String? email, String? role, DateTime? signupDate}) {
    if (!_trackingEnabled) return;
    _mixpanel?.identify(userId);
    if (email != null || role != null) {
      _mixpanel?.getPeople().set('\$email', email ?? '');
      if (role != null) _mixpanel?.getPeople().set('role', role);
      if (signupDate != null) _mixpanel?.getPeople().set('signup_date', signupDate.toIso8601String());
    }
  }

  void reset() => _mixpanel?.reset();

  void track(String event, [Map<String, dynamic>? properties]) {
    if (!_trackingEnabled) return;
    debugPrint('[Analytics] $event ${properties ?? ''}');
    _mixpanel?.track(event, properties: properties);
  }

  void flush() => _mixpanel?.flush();

  // ── Typed event helpers ───────────────────────────────────────────────────

  void appOpened({required bool isFirstOpen}) =>
      track('app_opened', {'is_first_open': isFirstOpen, 'platform': defaultTargetPlatform.name});

  void signupStarted(String method) => track('signup_started', {'method': method});

  void signupCompleted({required String role, required String method, int? timeSeconds}) =>
      track('signup_completed', {'role': role, 'signup_method': method, if (timeSeconds != null) 'time_to_complete_seconds': timeSeconds});

  void onboardingStepCompleted(int step, String stepName, String role) =>
      track('onboarding_step_completed', {'step_number': step, 'step_name': stepName, 'role': role});

  void taskViewed(String taskId, String domain, String difficulty) =>
      track('task_viewed', {'task_id': taskId, 'domain': domain, 'difficulty': difficulty});

  void taskBookmarked(String taskId, String domain) =>
      track('task_bookmarked', {'task_id': taskId, 'domain': domain});

  void submissionStarted(String taskId, String domain, List<String> types) =>
      track('submission_started', {'task_id': taskId, 'domain': domain, 'submission_types': types});

  void submissionCompleted(String taskId, String domain, List<String> types, int timeMinutes) =>
      track('submission_completed', {'task_id': taskId, 'domain': domain, 'submission_types': types, 'time_spent_minutes': timeMinutes});

  void scoreViewed(String taskId, double score, int rank, double percentile) =>
      track('score_viewed', {'task_id': taskId, 'score': score, 'rank': rank, 'percentile': percentile});

  void leaderboardViewed(String taskId, int userRank) =>
      track('leaderboard_viewed', {'task_id': taskId, 'user_rank': userRank});

  void profileViewed(int skillScore, int tasksCompleted) =>
      track('profile_viewed', {'skill_score': skillScore, 'tasks_completed': tasksCompleted});

  void taskPosted(String domain, String difficulty, String tier, double priceInr) =>
      track('task_posted', {'domain': domain, 'difficulty': difficulty, 'tier': tier, 'price_inr': priceInr});

  void submissionScored(String taskId, double totalScore, String method) =>
      track('submission_scored', {'task_id': taskId, 'total_score': totalScore, 'method': method});

  void candidateShortlisted(String taskId, double score, int rank) =>
      track('candidate_shortlisted', {'task_id': taskId, 'candidate_score': score, 'candidate_rank': rank});

  void hireConfirmed(String taskId, int daysFromPublish) =>
      track('hire_confirmed', {'task_id': taskId, 'time_from_publish_to_hire_days': daysFromPublish});

  void messageSent(String threadId, String senderRole) =>
      track('message_sent', {'thread_id': threadId, 'sender_role': senderRole});

  void subscriptionStarted(String plan, String billingPeriod, double amountInr) =>
      track('subscription_started', {'plan': plan, 'billing_period': billingPeriod, 'amount_inr': amountInr});

  void referralLinkShared(String referralCode, String shareMethod) =>
      track('referral_link_shared', {'referral_code': referralCode, 'share_method': shareMethod});

  void referralConverted(String referrerId, String referredRole, String rewardType) =>
      track('referral_converted', {'referrer_id': referrerId, 'referred_role': referredRole, 'reward_type': rewardType});

  void paymentCompleted(double amountInr, String tier, String paymentType) =>
      track('payment_completed', {'amount_inr': amountInr, 'tier': tier, 'payment_type': paymentType});

  // ── Part 1 — 1v1 Live Challenges ─────────────────────────────────────────

  void challengeInviteSent(String domain, int durationMinutes) =>
      track('challenge_invite_sent', {'domain': domain, 'duration_minutes': durationMinutes});

  void challengeInviteAccepted(String matchId, String domain) =>
      track('challenge_invite_accepted', {'match_id': matchId, 'domain': domain});

  void challengeInviteDeclined(String matchId, String domain) =>
      track('challenge_invite_declined', {'match_id': matchId, 'domain': domain});

  void matchStarted(String matchId, String domain, int durationMinutes) =>
      track('match_started', {'match_id': matchId, 'domain': domain, 'duration_minutes': durationMinutes});

  void matchSubmitted(String matchId, String domain, bool isAuto, int secondsRemaining) =>
      track('match_submitted', {
        'match_id': matchId,
        'domain': domain,
        'is_auto_submit': isAuto,
        'seconds_remaining': secondsRemaining,
      });

  void matchCompleted(String matchId, String domain, String result, int eloChange) =>
      track('match_completed', {
        'match_id': matchId,
        'domain': domain,
        'result': result, // win | loss | draw
        'elo_change': eloChange,
      });

  void eloTierChanged(String oldTier, String newTier, int newElo) =>
      track('elo_tier_changed', {'old_tier': oldTier, 'new_tier': newTier, 'new_elo': newElo});

  void matchResultShared(String matchId, String result) =>
      track('match_result_shared', {'match_id': matchId, 'result': result});

  void spectatorJoined(String matchId) =>
      track('spectator_joined', {'match_id': matchId});

  void antiCheatEvent(String matchId, String eventType) =>
      track('anti_cheat_event', {'match_id': matchId, 'event_type': eventType});
}
