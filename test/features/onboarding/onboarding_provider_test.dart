import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hirex_app/features/onboarding/presentation/providers/onboarding_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  test('initial state has currentStep = 0', () {
    final state = container.read(onboardingProvider);
    expect(state.currentStep, 0);
  });

  test('nextStep increments currentStep', () {
    container.read(onboardingProvider.notifier).nextStep();
    expect(container.read(onboardingProvider).currentStep, 1);
  });

  test('prevStep does not go below 0', () {
    container.read(onboardingProvider.notifier).prevStep();
    expect(container.read(onboardingProvider).currentStep, 0);
  });

  test('setRole updates selectedRole', () {
    container.read(onboardingProvider.notifier).setRole('candidate');
    expect(container.read(onboardingProvider).selectedRole, 'candidate');
    expect(container.read(onboardingProvider).isCandidate, true);
  });

  test('toggleSkill adds and removes skills', () {
    final notifier = container.read(onboardingProvider.notifier);
    notifier.toggleSkill('Flutter');
    expect(container.read(onboardingProvider).selectedSkills, contains('Flutter'));
    notifier.toggleSkill('Flutter');
    expect(container.read(onboardingProvider).selectedSkills, isNot(contains('Flutter')));
  });

  test('toggleSkill respects max 10 limit', () {
    final notifier = container.read(onboardingProvider.notifier);
    for (int i = 0; i < 12; i++) {
      notifier.toggleSkill('Skill$i');
    }
    expect(container.read(onboardingProvider).selectedSkills.length, 10);
  });

  test('setBasicInfo updates fields', () {
    container.read(onboardingProvider.notifier).setBasicInfo(
      fullName: 'Jane Doe',
      city: 'Mumbai',
      headline: 'Flutter Dev',
    );
    final state = container.read(onboardingProvider);
    expect(state.fullName, 'Jane Doe');
    expect(state.city, 'Mumbai');
    expect(state.headline, 'Flutter Dev');
  });
}
