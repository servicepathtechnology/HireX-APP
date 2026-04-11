import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/hirex_button.dart';
import '../../../../shared/widgets/hirex_snackbar.dart';
import '../providers/onboarding_provider.dart';

/// Step 2 — Role selection: Candidate or Recruiter.
class OnboardingRolePage extends ConsumerWidget {
  const OnboardingRolePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    Future<void> onContinue() async {
      if (state.selectedRole == null) {
        HireXSnackbar.show(context, message: 'Please select a role to continue.', type: SnackbarType.error);
        return;
      }
      await notifier.saveRoleToBackend();
      if (state.error != null && context.mounted) {
        HireXSnackbar.show(context, message: state.error!, type: SnackbarType.error);
        return;
      }
      notifier.nextStep();
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('I am here to...', style: AppTextStyles.displayMedium),
          const SizedBox(height: 8),
          Text('Choose your role on HireX.', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 32),
          _RoleCard(
            title: 'Find Opportunities',
            subtitle: 'Prove your skills, get hired faster',
            icon: Icons.person_search,
            role: 'candidate',
            isSelected: state.selectedRole == 'candidate',
            onTap: () => notifier.setRole('candidate'),
          ),
          const SizedBox(height: 16),
          _RoleCard(
            title: 'Hire Talent',
            subtitle: 'Post tasks, find proven performers',
            icon: Icons.business_center,
            role: 'recruiter',
            isSelected: state.selectedRole == 'recruiter',
            onTap: () => notifier.setRole('recruiter'),
          ),
          const Spacer(),
          HireXButton(
            label: 'Continue',
            onPressed: state.selectedRole != null ? onContinue : null,
            isLoading: state.isLoading,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String role;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isSelected ? AppColors.primary : AppColors.onSurface, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );
  }
}
