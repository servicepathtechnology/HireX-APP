import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/auth_landing_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/phone_auth_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/candidate/pipeline/presentation/pages/candidate_pipeline_page.dart';
import '../../features/candidate/score_explanation/presentation/pages/score_explanation_page.dart';
import '../../features/candidate/skill_score/presentation/pages/skill_score_detail_page.dart';
import '../../features/leaderboard/presentation/pages/leaderboard_page.dart';
import '../../features/messaging/presentation/pages/chat_screen_page.dart';
import '../../features/messaging/presentation/pages/thread_list_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/pow_profile_page.dart';
import '../../features/profile/presentation/pages/recruiter_profile_page.dart';
import '../../features/recruiter/ai_review/presentation/pages/ai_review_page.dart';
import '../../features/recruiter/analytics/presentation/pages/recruiter_analytics_page.dart';
import '../../features/recruiter/billing/presentation/pages/billing_page.dart';
import '../../features/recruiter/candidates/presentation/pages/candidate_deep_dive_page.dart';
import '../../features/recruiter/dashboard/presentation/pages/recruiter_dashboard_page.dart';
import '../../features/recruiter/pipeline/presentation/pages/hiring_pipeline_page.dart';
import '../../features/recruiter/post_task/presentation/pages/post_task_wizard_page.dart';
import '../../features/recruiter/submissions/presentation/pages/score_submission_page.dart';
import '../../features/recruiter/submissions/presentation/pages/submissions_dashboard_page.dart';
import '../../features/recruiter/tasks/presentation/pages/recruiter_my_tasks_page.dart';
import '../../features/settings/presentation/pages/notification_settings_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/shell/presentation/pages/shell_page.dart';
import '../../features/submissions/presentation/pages/submission_status_page.dart';
import '../../features/submissions/presentation/pages/submit_solution_page.dart';
import '../../features/tasks/presentation/pages/bookmarks_page.dart';
import '../../features/tasks/presentation/pages/my_tasks_page.dart';
import '../../features/tasks/presentation/pages/recommended_tasks_page.dart';
import '../../features/tasks/presentation/pages/task_detail_page.dart';
import '../../features/tasks/presentation/pages/task_feed_page.dart';
// Part 5
import '../../features/recruiter/billing/presentation/pages/subscription_page.dart';
import '../../features/referral/presentation/pages/referral_hub_page.dart';
// Part 1 — 1v1 Live Challenges
import '../../features/challenges/presentation/pages/challenge_hub_page.dart';
import '../../features/challenges/presentation/pages/new_challenge_page.dart';
import '../../features/challenges/presentation/pages/live_challenge_room_page.dart';
import '../../features/challenges/presentation/pages/challenge_room_webview_page.dart';
import '../../features/challenges/presentation/pages/match_result_page.dart';
import '../../features/challenges/presentation/pages/match_comparison_page.dart';
import '../../features/challenges/presentation/pages/spectator_view_page.dart';
import '../../features/challenges/presentation/pages/match_history_page.dart';
import '../../features/challenges/presentation/pages/match_detail_page.dart';
import '../../features/challenges/presentation/pages/challenge_invite_page.dart';
import '../../features/challenges/presentation/pages/pending_challenge_page.dart';
import '../../features/challenges/presentation/pages/badge_earned_overlay_page.dart';
import '../../features/challenges/presentation/pages/unified_challenge_hub_page.dart';
// Part 2 — Solo Challenges
import '../../features/solo_challenges/presentation/pages/solo_challenge_hub_page.dart';
import '../../features/solo_challenges/presentation/pages/daily_challenge_page.dart';
import '../../features/solo_challenges/presentation/pages/weekly_challenge_page.dart';
import '../../features/solo_challenges/presentation/pages/monthly_challenge_page.dart';
import '../../features/solo_challenges/presentation/pages/solo_room_webview_page.dart';
import '../../features/solo_challenges/presentation/pages/streak_detail_page.dart';
import '../../features/solo_challenges/presentation/pages/preferences_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// A [ChangeNotifier] that bridges Riverpod auth state to GoRouter's
/// [refreshListenable], so the router re-evaluates redirects on auth changes.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen(authNotifierProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthChangeNotifier(ref);

  ref.onDispose(authNotifier.dispose);

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      if (authState.isLoading) return null;

      final user = authState.valueOrNull;
      final isAuthenticated = user != null;
      final path = state.uri.path;

      final authRoutes = ['/auth', '/auth/login', '/auth/signup',
          '/auth/forgot-password', '/auth/phone'];
      final isAuthRoute = authRoutes.contains(path) || path == '/';

      // Not logged in — send to auth unless already there
      if (!isAuthenticated) {
        return isAuthRoute ? null : '/auth';
      }

      // Logged in — redirect away from auth/splash screens
      if (isAuthRoute) {
        if (!user.onboardingComplete) return '/onboarding';
        return user.isCandidate ? '/candidate/home' : '/recruiter/home';
      }

      // Logged in but onboarding not done — force onboarding
      // Exception: if the path is already a home route (user just completed
      // onboarding and navigated manually), don't redirect back
      final isHomeRoute = path == '/candidate/home' || path == '/recruiter/home';
      if (!user.onboardingComplete && path != '/onboarding' && !isHomeRoute) {
        return '/onboarding';
      }

      // Logged in, onboarding done — prevent wrong-role access
      if (user.onboardingComplete) {
        final isOnRecruiterRoute = path.startsWith('/recruiter/');
        final isOnCandidateRoute = path.startsWith('/candidate/');
        if (user.isCandidate && isOnRecruiterRoute) {
          return '/candidate/home';
        }
        if (user.isRecruiter && isOnCandidateRoute) {
          return '/recruiter/home';
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', name: 'splash', builder: (_, __) => const SplashPage()),

      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(path: '/auth', name: 'authLanding', builder: (_, __) => const AuthLandingPage()),
      GoRoute(path: '/auth/login', name: 'login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/auth/signup', name: 'signup', builder: (_, __) => const SignupPage()),
      GoRoute(path: '/auth/forgot-password', name: 'forgotPassword', builder: (_, __) => const ForgotPasswordPage()),
      GoRoute(path: '/auth/phone', name: 'phoneAuth', builder: (_, __) => const PhoneAuthPage()),

      // ── Onboarding ────────────────────────────────────────────────────────
      GoRoute(path: '/onboarding', name: 'onboarding', builder: (_, __) => const OnboardingPage()),

      // ── Profile & Settings ────────────────────────────────────────────────
      GoRoute(path: '/profile/edit', name: 'editProfile', builder: (_, __) => const EditProfilePage()),
      GoRoute(path: '/settings', name: 'settings', builder: (_, __) => const SettingsPage()),

      // ── Notifications ─────────────────────────────────────────────────────
      GoRoute(path: '/notifications', name: 'notifications', builder: (_, __) => const NotificationsPage()),

      // ── Candidate task routes ─────────────────────────────────────────────
      GoRoute(
        path: '/candidate/tasks/:taskId',
        name: 'taskDetail',
        builder: (_, state) => TaskDetailPage(taskId: state.pathParameters['taskId']!),
      ),
      GoRoute(
        path: '/candidate/tasks/:taskId/submit',
        name: 'submitSolution',
        builder: (_, state) => SubmitSolutionPage(taskId: state.pathParameters['taskId']!),
      ),
      GoRoute(
        path: '/candidate/submissions/:submissionId',
        name: 'submissionStatus',
        builder: (_, state) => SubmissionStatusPage(submissionId: state.pathParameters['submissionId']!),
      ),
      GoRoute(
        path: '/candidate/leaderboard/:taskId',
        name: 'taskLeaderboard',
        builder: (_, state) => LeaderboardPage(taskId: state.pathParameters['taskId']!),
      ),
      GoRoute(
        path: '/candidate/bookmarks',
        name: 'bookmarks',
        builder: (_, __) => const BookmarksPage(),
      ),

      // ── Part 4 — Candidate Pipeline ───────────────────────────────────────
      GoRoute(
        path: '/candidate/pipeline',
        name: 'candidatePipeline',
        builder: (_, __) => const CandidatePipelinePage(),
      ),

      // ── Recruiter full-screen routes ──────────────────────────────────────
      GoRoute(
        path: '/recruiter/post-task/basics',
        name: 'postTask',
        builder: (_, __) => const PostTaskWizardPage(),
      ),
      GoRoute(
        path: '/recruiter/tasks/:taskId/submissions',
        name: 'submissionsDashboard',
        builder: (_, state) => SubmissionsDashboardPage(taskId: state.pathParameters['taskId']!),
      ),
      GoRoute(
        path: '/recruiter/tasks/:taskId/edit',
        name: 'editTask',
        builder: (_, state) {
          final taskId = state.pathParameters['taskId']!;
          return PostTaskWizardPage(editTaskId: taskId);
        },
      ),
      GoRoute(
        path: '/recruiter/submissions/:submissionId/score',
        name: 'scoreSubmission',
        builder: (_, state) => ScoreSubmissionPage(submissionId: state.pathParameters['submissionId']!),
      ),
      GoRoute(
        path: '/recruiter/candidates/:userId',
        name: 'candidateDeepDive',
        builder: (_, state) => CandidateDeepDivePage(userId: state.pathParameters['userId']!),
      ),
      GoRoute(
        path: '/recruiter/pipeline',
        name: 'hiringPipeline',
        builder: (_, __) => const HiringPipelinePage(),
      ),
      GoRoute(
        path: '/recruiter/analytics',
        name: 'recruiterAnalytics',
        builder: (_, __) => const RecruiterAnalyticsPage(),
      ),
      GoRoute(
        path: '/recruiter/billing',
        name: 'billing',
        builder: (_, __) => const BillingPage(),
      ),

      // ── Part 4 — AI Review ────────────────────────────────────────────────
      GoRoute(
        path: '/recruiter/submissions/:submissionId/ai-review',
        name: 'aiReview',
        builder: (_, state) => AIReviewPage(submissionId: state.pathParameters['submissionId']!),
      ),

      // ── Part 4 — Score Explanation ────────────────────────────────────────
      GoRoute(
        path: '/candidate/submissions/:submissionId/score-explanation',
        name: 'scoreExplanation',
        builder: (_, state) => ScoreExplanationPage(submissionId: state.pathParameters['submissionId']!),
      ),

      // ── Part 4 — Skill Score Detail ───────────────────────────────────────
      GoRoute(
        path: '/candidate/skill-score',
        name: 'skillScoreDetail',
        builder: (_, __) => const SkillScoreDetailPage(),
      ),

      // ── Part 4 — Messaging ────────────────────────────────────────────────
      GoRoute(
        path: '/messages/:threadId',
        name: 'chatScreen',
        builder: (_, state) => ChatScreenPage(threadId: state.pathParameters['threadId']!),
      ),

      // ── Part 4 — Recommended Tasks ────────────────────────────────────────
      GoRoute(
        path: '/candidate/recommended',
        name: 'recommendedTasks',
        builder: (_, __) => const RecommendedTasksPage(),
      ),

      // ── Part 4 — Notification Settings ───────────────────────────────────
      GoRoute(
        path: '/settings/notifications',
        name: 'notificationSettings',
        builder: (_, __) => const NotificationSettingsPage(),
      ),

      // ── Part 5 — Subscription ─────────────────────────────────────────────
      GoRoute(
        path: '/recruiter/subscription',
        name: 'subscription',
        builder: (_, __) => const SubscriptionPage(),
      ),

      // ── Part 5 — Referral ─────────────────────────────────────────────────
      GoRoute(
        path: '/referral',
        name: 'referralHub',
        builder: (_, __) => const ReferralHubPage(),
      ),

      // ── Part 1 — 1v1 Live Challenges ──────────────────────────────────────
      GoRoute(
        path: '/challenges/1v1/new',
        name: 'newChallenge',
        builder: (_, __) => const NewChallengePage(),
      ),
      GoRoute(
        path: '/challenges/1v1/:matchId/invite',
        name: 'challengeInvite',
        builder: (_, state) =>
            ChallengeInvitePage(matchId: state.pathParameters['matchId']!),
      ),
      GoRoute(
        path: '/challenges/1v1/:matchId/pending',
        name: 'pendingChallenge',
        builder: (_, state) =>
            PendingChallengePage(matchId: state.pathParameters['matchId']!),
      ),
      GoRoute(
        path: '/challenges/1v1/:matchId/room',
        name: 'challengeRoomWebView',
        builder: (_, state) =>
            ChallengeRoomWebViewPage(matchId: state.pathParameters['matchId']!),
      ),
      GoRoute(
        path: '/challenges/1v1/:matchId/badge',
        name: 'badgeEarned',
        builder: (_, state) => BadgeEarnedOverlayPage(
          matchId: state.pathParameters['matchId']!,
          badge: state.uri.queryParameters['badge'] ?? 'coding_warrior',
          points: int.tryParse(state.uri.queryParameters['points'] ?? '50') ?? 50,
        ),
      ),
      GoRoute(
        path: '/challenges/1v1/:matchId',
        name: 'liveRoom',
        builder: (_, state) =>
            LiveChallengeRoomPage(matchId: state.pathParameters['matchId']!),
      ),
      GoRoute(
        path: '/challenges/1v1/:matchId/result',
        name: 'matchResult',
        builder: (_, state) =>
            MatchResultPage(matchId: state.pathParameters['matchId']!),
      ),
      GoRoute(
        path: '/challenges/1v1/:matchId/watch',
        name: 'spectatorView',
        builder: (_, state) =>
            SpectatorViewPage(matchId: state.pathParameters['matchId']!),
      ),
      GoRoute(
        path: '/challenges/1v1/:matchId/detail',
        name: 'matchDetail',
        builder: (_, state) =>
            MatchDetailPage(matchId: state.pathParameters['matchId']!),
      ),
      // Deep link target: hirex://challenges/compare/{matchId}
      GoRoute(
        path: '/challenges/compare/:matchId',
        name: 'matchComparison',
        builder: (_, state) =>
            MatchComparisonPage(matchId: state.pathParameters['matchId']!),
      ),
      GoRoute(
        path: '/profile/:userId/matches',
        name: 'matchHistory',
        builder: (_, state) =>
            MatchHistoryPage(userId: state.pathParameters['userId']!),
      ),

      // ── Part 5 — Signup with referral code ───────────────────────────────
      GoRoute(
        path: '/auth/signup/:referralCode',
        name: 'signupWithReferral',
        builder: (_, state) => SignupPage(referralCode: state.pathParameters['referralCode']),
      ),

      // ── Part 2 — Solo Challenges ──────────────────────────────────────────
      GoRoute(
        path: '/challenges/solo',
        name: 'soloChallengeHub',
        builder: (_, __) => const SoloChallengeHubPage(),
      ),
      GoRoute(
        path: '/challenges/solo/daily',
        name: 'dailyChallenge',
        builder: (_, __) => const DailyChallengePage(),
      ),
      GoRoute(
        path: '/challenges/solo/weekly',
        name: 'weeklyChallenge',
        builder: (_, __) => const WeeklyChallengePage(),
      ),
      GoRoute(
        path: '/challenges/solo/monthly',
        name: 'monthlyChallenge',
        builder: (_, __) => const MonthlyChallengePage(),
      ),
      GoRoute(
        path: '/challenges/solo/room',
        name: 'soloRoomWebView',
        builder: (_, state) {
          final url = state.uri.queryParameters['url'] ?? '';
          final token = state.uri.queryParameters['token'] ?? '';
          return SoloRoomWebViewPage(
            roomUrl: Uri.decodeComponent(url),
            roomToken: token,
          );
        },
      ),
      GoRoute(
        path: '/challenges/solo/streak',
        name: 'streakDetail',
        builder: (_, __) => const StreakDetailPage(),
      ),
      GoRoute(
        path: '/challenges/solo/preferences',
        name: 'challengePreferences',
        builder: (_, __) => const ChallengePreferencesPage(),
      ),

      // ── Candidate shell ───────────────────────────────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (_, __, child) => ShellPage(child: child),
        routes: [
          GoRoute(
            path: '/candidate/home',
            name: 'candidateHome',
            builder: (_, __) => const TaskFeedPage(),
          ),
          GoRoute(
            path: '/candidate/my-tasks',
            name: 'candidateTasks',
            builder: (_, __) => const MyTasksPage(),
          ),
          GoRoute(
            path: '/challenges/1v1',
            name: 'challengeHubShell',
            builder: (_, __) => const UnifiedChallengeHubPage(),
          ),
          GoRoute(
            path: '/messages',
            name: 'messages',
            builder: (_, __) => const ThreadListPage(),
          ),
          GoRoute(
            path: '/candidate/profile',
            name: 'candidateProfile',
            builder: (_, __) => const POWProfilePage(),
          ),
        ],
      ),

      // ── Recruiter shell ───────────────────────────────────────────────────
      ShellRoute(
        builder: (_, __, child) => ShellPage(child: child),
        routes: [
          GoRoute(
            path: '/recruiter/home',
            name: 'recruiterHome',
            builder: (_, __) => const RecruiterDashboardPage(),
          ),
          GoRoute(
            path: '/recruiter/my-tasks',
            name: 'recruiterMyTasks',
            builder: (_, __) => const RecruiterMyTasksPage(),
          ),
          GoRoute(
            path: '/recruiter/messages',
            name: 'recruiterMessages',
            builder: (_, __) => const ThreadListPage(),
          ),
          GoRoute(
            path: '/recruiter/profile',
            name: 'recruiterProfile',
            builder: (_, __) => const RecruiterProfilePage(),
          ),
        ],
      ),
    ],
  );

  return router;
});
