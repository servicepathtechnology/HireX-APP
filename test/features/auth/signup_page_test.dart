import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hirex_app/features/auth/presentation/pages/signup_page.dart';
import 'package:hirex_app/core/theme/app_theme.dart';

Widget _buildTestApp(Widget child) {
  return ProviderScope(
    child: MaterialApp(theme: AppTheme.dark, home: child),
  );
}

void main() {
  group('SignupPage', () {
    testWidgets('renders all required fields', (tester) async {
      await tester.pumpWidget(_buildTestApp(const SignupPage()));
      await tester.pump();
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
    });

    testWidgets('shows validation errors on empty submit', (tester) async {
      await tester.pumpWidget(_buildTestApp(const SignupPage()));
      await tester.pump();
      await tester.tap(find.text('Create Account'));
      await tester.pump();
      expect(find.text('Full name is required.'), findsOneWidget);
    });

    testWidgets('shows password mismatch error', (tester) async {
      await tester.pumpWidget(_buildTestApp(const SignupPage()));
      await tester.pump();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'John Doe');
      await tester.enterText(fields.at(1), 'john@example.com');
      await tester.enterText(fields.at(2), 'Secure@123');
      await tester.enterText(fields.at(3), 'Different@456');
      await tester.tap(find.text('Create Account'));
      await tester.pump();
      expect(find.text('Passwords do not match.'), findsOneWidget);
    });

    testWidgets('password strength indicator appears when typing', (tester) async {
      await tester.pumpWidget(_buildTestApp(const SignupPage()));
      await tester.pump();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(2), 'abc');
      await tester.pump();
      expect(find.text('Weak'), findsOneWidget);
    });

    testWidgets('sign in link is present', (tester) async {
      await tester.pumpWidget(_buildTestApp(const SignupPage()));
      await tester.pump();
      expect(find.textContaining('Already have an account'), findsOneWidget);
    });
  });
}
