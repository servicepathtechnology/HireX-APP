import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hirex_app/core/theme/app_theme.dart';
import 'package:hirex_app/features/onboarding/presentation/pages/onboarding_welcome_page.dart';
import 'package:hirex_app/features/onboarding/presentation/pages/onboarding_role_page.dart';
import 'package:hirex_app/features/onboarding/presentation/pages/onboarding_skills_page.dart';
import 'package:hirex_app/features/onboarding/presentation/providers/onboarding_provider.dart';

Widget _buildTestApp(Widget child) {
  return ProviderScope(
    child: MaterialApp(theme: AppTheme.dark, home: Scaffold(body: child)),
  );
}

void main() {
  group('OnboardingWelcomePage', () {
    testWidgets('renders value proposition points', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingWelcomePage()));
      await tester.pump();
      expect(find.text('Welcome to HireX'), findsOneWidget);
      expect(find.text('Real tasks. Real proof. Real jobs.'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('Get Started button advances step', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(body: const OnboardingWelcomePage()),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Get Started'));
      await tester.pump();
      expect(container.read(onboardingProvider).currentStep, 1);
    });
  });

  group('OnboardingRolePage', () {
    testWidgets('renders both role cards', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingRolePage()));
      await tester.pump();
      expect(find.text('Find Opportunities'), findsOneWidget);
      expect(find.text('Hire Talent'), findsOneWidget);
    });

    testWidgets('Continue button disabled until role selected', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingRolePage()));
      await tester.pump();
      final continueBtn = find.text('Continue');
      expect(continueBtn, findsOneWidget);
      // Button should be disabled (no role selected)
      final elevatedBtn = tester.widget<ElevatedButton>(
        find.ancestor(of: continueBtn, matching: find.byType(ElevatedButton)),
      );
      expect(elevatedBtn.onPressed, isNull);
    });

    testWidgets('selecting candidate role enables Continue', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(body: const OnboardingRolePage()),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Find Opportunities'));
      await tester.pump();
      expect(container.read(onboardingProvider).selectedRole, 'candidate');
    });
  });

  group('OnboardingSkillsPage', () {
    testWidgets('renders preset skill chips', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingSkillsPage()));
      await tester.pump();
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('React'), findsOneWidget);
    });

    testWidgets('skip button is present', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingSkillsPage()));
      await tester.pump();
      expect(find.text('Skip for now'), findsOneWidget);
    });
  });
}
