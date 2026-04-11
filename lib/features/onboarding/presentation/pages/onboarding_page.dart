import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/onboarding_provider.dart';
import '../../providers/ab_test_provider.dart';
import 'onboarding_welcome_page.dart';
import 'onboarding_role_page.dart';
import 'onboarding_basic_info_page.dart';
import 'onboarding_skills_page.dart';
import 'onboarding_company_page.dart';
import 'onboarding_photo_page.dart';
import 'onboarding_complete_page.dart';

/// Shell that hosts the onboarding PageView and drives step navigation.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  PageController _pageController = PageController();
  String? _lastRole;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final abVariant = ref.watch(abTestProvider);
    final isShortFlow = abVariant == 'B';
    final isCandidate = state.isCandidate;

    // Step counts — candidates always get a skills step
    final totalSteps = isShortFlow ? (isCandidate ? 4 : 3) : 6;

    // Recreate PageController when role changes so page index stays correct
    if (state.selectedRole != _lastRole) {
      _lastRole = state.selectedRole;
      _pageController.dispose();
      _pageController = PageController(initialPage: state.currentStep);
    }

    // Sync page controller when state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients &&
          _pageController.page?.round() != state.currentStep) {
        _goToStep(state.currentStep);
      }
    });

    // IMPORTANT: PageView children list must be STABLE in length to avoid
    // position drift. We always include both Skills and Company pages but
    // only one is reachable via nextStep() based on role.
    // Short flow: Role(0) → BasicInfo(1) → Skills(2) → Complete(3)
    //             Role(0) → BasicInfo(1) → Complete(2)  [recruiter, 3 pages]
    // Full flow:  Welcome(0) → Role(1) → BasicInfo(2) → Skills/Company(3) → Photo(4) → Complete(5)
    final pages = isShortFlow
        ? (isCandidate
            ? <Widget>[
                const OnboardingRolePage(),
                const OnboardingBasicInfoPage(),
                const OnboardingSkillsPage(),
                const OnboardingCompletePage(),
              ]
            : <Widget>[
                const OnboardingRolePage(),
                const OnboardingBasicInfoPage(),
                const OnboardingCompletePage(),
              ])
        : <Widget>[
            const OnboardingWelcomePage(),
            const OnboardingRolePage(),
            const OnboardingBasicInfoPage(),
            // Step 3: always Skills for candidate, Company for recruiter
            // This is safe because role is set before reaching step 3
            isCandidate
                ? const OnboardingSkillsPage()
                : const OnboardingCompanyPage(),
            const OnboardingPhotoPage(),
            const OnboardingCompletePage(),
          ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _StepIndicator(currentStep: state.currentStep, totalSteps: totalSteps),
            Expanded(
              child: PageView(
                key: ValueKey('${isShortFlow}_${isCandidate}'),
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: pages,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep, required this.totalSteps});

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(totalSteps, (i) {
          final active = i <= currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
