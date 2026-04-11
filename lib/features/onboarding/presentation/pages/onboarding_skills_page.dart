import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/hirex_button.dart';
import '../../../../shared/widgets/hirex_snackbar.dart';
import '../../../../shared/widgets/hirex_tag.dart';
import '../providers/onboarding_provider.dart';

/// Step 4 (Candidate) — Skill selection and career goal.
class OnboardingSkillsPage extends ConsumerStatefulWidget {
  const OnboardingSkillsPage({super.key});

  @override
  ConsumerState<OnboardingSkillsPage> createState() => _OnboardingSkillsPageState();
}

class _OnboardingSkillsPageState extends ConsumerState<OnboardingSkillsPage> {
  final _customSkillCtrl = TextEditingController();
  String? _careerGoal;

  static const _presetSkills = [
    'Flutter', 'React', 'Node.js', 'Python', 'Java', 'Kotlin', 'Swift',
    'TypeScript', 'Go', 'Rust', 'AWS', 'Docker', 'Kubernetes', 'GraphQL',
    'PostgreSQL', 'MongoDB', 'Redis', 'Figma', 'UI/UX Design', 'Product Management',
    'Data Science', 'Machine Learning', 'DevOps', 'iOS', 'Android',
    'Vue.js', 'Angular', 'Django', 'FastAPI', 'Spring Boot', 'React Native',
    'Firebase', 'Supabase', 'Next.js', 'Tailwind CSS', 'Git', 'CI/CD',
    'Agile', 'Scrum', 'Technical Writing', 'SEO', 'Marketing', 'Sales',
  ];

  static const _careerGoals = [
    'First Job', 'Switch Companies', 'Freelance', 'Promotion', 'Build Portfolio',
  ];

  @override
  void initState() {
    super.initState();
    _careerGoal = ref.read(onboardingProvider).careerGoal;
  }

  @override
  void dispose() {
    _customSkillCtrl.dispose();
    super.dispose();
  }

  void _addCustomSkill() {
    final skill = _customSkillCtrl.text.trim();
    if (skill.isEmpty) return;
    ref.read(onboardingProvider.notifier).toggleSkill(skill);
    _customSkillCtrl.clear();
  }

  Future<void> _submit() async {
    if (_careerGoal != null) {
      ref.read(onboardingProvider.notifier).setCareerGoal(_careerGoal!);
    }
    await ref.read(onboardingProvider.notifier).saveSkillsToBackend();
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Your skills', style: AppTextStyles.displayMedium),
          const SizedBox(height: 4),
          Text('Select up to 10 skills. (${state.selectedSkills.length}/10)', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetSkills.map((skill) {
              final selected = state.selectedSkills.contains(skill);
              return GestureDetector(
                onTap: () => ref.read(onboardingProvider.notifier).toggleSkill(skill),
                child: HireXTag(label: skill, isSelected: selected),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customSkillCtrl,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: '+ Add custom skill',
                    prefixIcon: Icon(Icons.add, color: AppColors.onSurface),
                  ),
                  onSubmitted: (_) => _addCustomSkill(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addCustomSkill,
                icon: const Icon(Icons.check, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Career goal', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _careerGoal,
            decoration: const InputDecoration(labelText: 'What are you aiming for?'),
            dropdownColor: AppColors.surface,
            style: AppTextStyles.bodyLarge,
            items: _careerGoals
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (v) => setState(() => _careerGoal = v),
          ),
          const SizedBox(height: 32),
          HireXButton(label: 'Continue', onPressed: _submit, isLoading: state.isLoading),
          TextButton(
            onPressed: () => ref.read(onboardingProvider.notifier).nextStep(),
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
