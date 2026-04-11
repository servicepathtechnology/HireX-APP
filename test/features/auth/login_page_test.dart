import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hirex_app/features/auth/presentation/pages/login_page.dart';
import 'package:hirex_app/core/theme/app_theme.dart';

Widget _buildTestApp(Widget child) {
  return ProviderScope(
    child: MaterialApp(theme: AppTheme.dark, home: child),
  );
}

void main() {
  group('LoginPage', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(_buildTestApp(const LoginPage()));
      await tester.pump();
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('shows validation errors on empty submit', (tester) async {
      await tester.pumpWidget(_buildTestApp(const LoginPage()));
      await tester.pump();
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      expect(find.text('Email is required.'), findsOneWidget);
    });

    testWidgets('shows invalid email error', (tester) async {
      await tester.pumpWidget(_buildTestApp(const LoginPage()));
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).first, 'notanemail');
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      expect(find.text('Enter a valid email address.'), findsOneWidget);
    });

    testWidgets('Forgot Password link is present', (tester) async {
      await tester.pumpWidget(_buildTestApp(const LoginPage()));
      await tester.pump();
      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('Create account link is present', (tester) async {
      await tester.pumpWidget(_buildTestApp(const LoginPage()));
      await tester.pump();
      expect(find.textContaining("Don't have an account"), findsOneWidget);
    });
  });
}
