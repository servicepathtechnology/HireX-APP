import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/offline_banner.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Bottom navigation shell — wraps all post-onboarding screens.
class ShellPage extends ConsumerWidget {
  const ShellPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final isCandidate = user?.isCandidate ?? true;
    final location = GoRouterState.of(context).uri.toString();

    final candidateTabs = [
      _NavTab(icon: Icons.explore_outlined, label: 'Explore', route: '/candidate/home'),
      _NavTab(icon: Icons.check_circle_outline_rounded, label: 'My Tasks', route: '/candidate/my-tasks'),
      _NavTab(icon: Icons.sports_esports_rounded, label: 'Challenges', route: '/challenges/1v1'),
      _NavTab(icon: Icons.chat_bubble_outline_rounded, label: 'Messages', route: '/messages'),
      _NavTab(icon: Icons.person_outline_rounded, label: 'Profile', route: '/candidate/profile'),
    ];

    final recruiterTabs = [
      _NavTab(icon: Icons.grid_view_rounded, label: 'Dashboard', route: '/recruiter/home'),
      _NavTab(icon: Icons.assignment_outlined, label: 'My Tasks', route: '/recruiter/my-tasks'),
      _NavTab(icon: Icons.chat_bubble_outline_rounded, label: 'Messages', route: '/recruiter/messages'),
      _NavTab(icon: Icons.business_center_outlined, label: 'Profile', route: '/recruiter/profile'),
    ];

    final tabs = isCandidate ? candidateTabs : recruiterTabs;
    final currentIndex = tabs.indexWhere((t) => location.startsWith(t.route));

    final safeIndex = currentIndex < 0 ? 0 : currentIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: OfflineBanner(child: child),
      bottomNavigationBar: _HireXBottomNav(
        tabs: tabs,
        currentIndex: safeIndex,
        onTap: (i) => context.go(tabs[i].route),
      ),
    );
  }
}

class _HireXBottomNav extends StatelessWidget {
  const _HireXBottomNav({
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
  });
  final List<_NavTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: Color(0xFF2A2A4A), width: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: 10,
          bottom: bottomPadding > 0 ? bottomPadding : 12,
        ),
        child: Row(
          children: List.generate(tabs.length, (i) {
            final isActive = i == currentIndex;
            final tab = tabs[i];
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        tab.icon,
                        size: 22,
                        color: isActive
                            ? AppColors.primary
                            : AppColors.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isActive
                            ? AppColors.primary
                            : AppColors.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavTab {
  const _NavTab({required this.icon, required this.label, required this.route});
  final IconData icon;
  final String label;
  final String route;
}

// ── Placeholder home screens ──────────────────────────────────────────────────

class CandidateHomePage extends StatelessWidget {
  const CandidateHomePage({super.key});

  @override
  Widget build(BuildContext context) => _PlaceholderScreen(
        icon: Icons.search,
        title: 'Task Feed',
        subtitle: 'Discover tasks to prove your skills — coming in Part 2',
      );
}

class RecruiterHomePage extends StatelessWidget {
  const RecruiterHomePage({super.key});

  @override
  Widget build(BuildContext context) => _PlaceholderScreen(
        icon: Icons.dashboard,
        title: 'Recruiter Dashboard',
        subtitle: 'Manage your tasks and candidates — coming in Part 3',
      );
}

class PlaceholderTabPage extends StatelessWidget {
  const PlaceholderTabPage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => _PlaceholderScreen(
        icon: Icons.construction,
        title: title,
        subtitle: 'This section is coming in a future part.',
      );
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64, color: AppColors.onSurface.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text(title, style: AppTextStyles.headlineLarge, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(subtitle, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
