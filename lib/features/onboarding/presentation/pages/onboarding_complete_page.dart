import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/hirex_button.dart';
import '../../../../shared/widgets/hirex_snackbar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';

/// Step 6 — Completion. Sets onboarding_complete = true and routes to home.
class OnboardingCompletePage extends ConsumerWidget {
  const OnboardingCompletePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(onboardingProvider).isLoading;

    Future<void> onExplore() async {
      await ref.read(onboardingProvider.notifier).completeOnboarding();
      if (!context.mounted) return;

      // Navigate regardless of backend error — onboarding_complete will
      // be retried on next app launch via the auth provider build().
      // Never block the user on a server error at this step.
      final user = ref.read(authNotifierProvider).valueOrNull;

      // Force refresh auth state so router sees updated onboarding_complete
      ref.read(authNotifierProvider.notifier).refreshUser();

      if (user?.isCandidate == true) {
        context.go('/candidate/home');
      } else if (user?.isRecruiter == true) {
        context.go('/recruiter/home');
      } else {
        // Role not yet set — read from onboarding state as fallback
        final onboardingState = ref.read(onboardingProvider);
        if (onboardingState.isCandidate) {
          context.go('/candidate/home');
        } else {
          context.go('/recruiter/home');
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: AppColors.success, size: 60),
          ),
          const SizedBox(height: 32),
          Text('Your profile is ready!', style: AppTextStyles.displayMedium, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            'Welcome to HireX. Let your work do the talking.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          HireXButton(label: 'Explore HireX', onPressed: onExplore, isLoading: isLoading),
        ],
      ),
    );
  }
}
