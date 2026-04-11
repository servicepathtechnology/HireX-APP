import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/hirex_button.dart';
import '../../../../shared/widgets/hirex_snackbar.dart';
import '../../../../shared/widgets/hirex_tag.dart';
import '../providers/onboarding_provider.dart';

/// Step 4 (Recruiter) — Company hiring info.
class OnboardingCompanyPage extends ConsumerStatefulWidget {
  const OnboardingCompanyPage({super.key});

  @override
  ConsumerState<OnboardingCompanyPage> createState() => _OnboardingCompanyPageState();
}

class _OnboardingCompanyPageState extends ConsumerState<OnboardingCompanyPage> {
  String? _hearAbout;

  static const _domains = [
    'Engineering', 'Design', 'Product', 'Marketing', 'Sales', 'Operations', 'Other',
  ];

  static const _hearOptions = [
    'LinkedIn', 'Twitter / X', 'Friend / Colleague', 'Google Search',
    'App Store', 'Blog / Article', 'Other',
  ];

  Future<void> _submit() async {
    await ref.read(onboardingProvider.notifier).saveRecruiterInfoToBackend();
    final state = ref.read(onboardingProvider);
    if (state.error != null && mounted) {
      HireXSnackbar.show(context, message: state.error!, type: SnackbarType.error);
      return;
    }
    ref.read(onboardingProvider.notifier).nextStep();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Hiring details', style: AppTextStyles.displayMedium),
          const SizedBox(height: 8),
          Text('Help candidates understand what you\'re looking for.', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 24),
          Text('Primary hiring domain', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _domains.map((d) {
              final selected = state.hiringDomains.contains(d);
              return GestureDetector(
                onTap: () => notifier.toggleHiringDomain(d),
                child: HireXTag(label: d, isSelected: selected),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            value: _hearAbout,
            decoration: const InputDecoration(labelText: 'How did you hear about HireX? (optional)'),
            dropdownColor: AppColors.surface,
            style: AppTextStyles.bodyLarge,
            items: _hearOptions
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: (v) => setState(() => _hearAbout = v),
          ),
          const SizedBox(height: 32),
          HireXButton(label: 'Continue', onPressed: _submit, isLoading: state.isLoading),
          TextButton(
            onPressed: () => notifier.nextStep(),
            child: Center(
              child: Text('Skip for now', style: AppTextStyles.labelLarge.copyWith(color: AppColors.onSurface)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
