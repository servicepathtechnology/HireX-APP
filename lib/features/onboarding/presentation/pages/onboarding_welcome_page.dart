import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/hirex_button.dart';
import '../providers/onboarding_provider.dart';

/// Step 1 — Welcome screen with value proposition.
class OnboardingWelcomePage extends ConsumerWidget {
  const OnboardingWelcomePage({super.key});

  static const _points = [
    ('Real tasks. Real proof. Real jobs.', Icons.task_alt),
    ('Your skills speak — not your resume.', Icons.record_voice_over),
    ('Build a career reputation that compounds.', Icons.trending_up),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.bolt, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 24),
          Text('Welcome to HireX', style: AppTextStyles.displayLarge),
          const SizedBox(height: 8),
          Text('Let Work Speak Louder Than Resumes.', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 40),
          ..._points.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(p.$2, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Text(p.$1, style: AppTextStyles.bodyLarge)),
                  ],
                ),
              )),
          const SizedBox(height: 32),
          HireXButton(
            label: 'Get Started',
            onPressed: () => ref.read(onboardingProvider.notifier).nextStep(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
