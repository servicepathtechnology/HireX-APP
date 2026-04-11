import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hirex_app/core/theme/app_theme.dart';
import 'package:hirex_app/features/auth/domain/entities/user_entity.dart';
import 'package:hirex_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:hirex_app/features/profile/presentation/pages/candidate_profile_page.dart';
import 'package:hirex_app/features/profile/presentation/pages/recruiter_profile_page.dart';

final _testCandidate = UserEntity(
  id: 'test-id',
  firebaseUid: 'uid',
  email: 'candidate@test.com',
  fullName: 'Jane Dev',
  role: 'candidate',
  onboardingComplete: true,
  isVerified: true,
  isActive: true,
  candidateProfile: const CandidateProfileEntity(
    headline: 'Flutter Developer',
    city: 'Mumbai',
    skillTags: ['Flutter', 'Dart'],
    bio: 'Passionate developer.',
  ),
);

final _testRecruiter = UserEntity(
  id: 'rec-id',
  firebaseUid: 'uid2',
  email: 'recruiter@test.com',
  fullName: 'Bob Recruiter',
  role: 'recruiter',
  onboardingComplete: true,
  isVerified: true,
  isActive: true,
  recruiterProfile: const RecruiterProfileEntity(
    companyName: 'TechCorp',
    roleAtCompany: 'Talent Lead',
    companySize: '51–200',
    hiringDomains: ['Engineering'],
  ),
);

Widget _buildWithUser(Widget child, UserEntity user) {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(() => _FakeAuthNotifier(user)),
    ],
    child: MaterialApp(theme: AppTheme.dark, home: child),
  );
}

class _FakeAuthNotifier extends AsyncNotifier<UserEntity?> {
  _FakeAuthNotifier(this._user);
  final UserEntity _user;

  @override
  Future<UserEntity?> build() async => _user;
}

void main() {
  group('CandidateProfilePage', () {
    testWidgets('renders candidate name and headline', (tester) async {
      await tester.pumpWidget(_buildWithUser(const CandidateProfilePage(), _testCandidate));
      await tester.pump();
      expect(find.text('Jane Dev'), findsOneWidget);
      expect(find.text('Flutter Developer'), findsOneWidget);
    });

    testWidgets('renders skill tags', (tester) async {
      await tester.pumpWidget(_buildWithUser(const CandidateProfilePage(), _testCandidate));
      await tester.pump();
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Dart'), findsOneWidget);
    });

    testWidgets('shows Part 2 placeholder cards', (tester) async {
      await tester.pumpWidget(_buildWithUser(const CandidateProfilePage(), _testCandidate));
      await tester.pump();
      expect(find.text('Skill Score'), findsOneWidget);
      expect(find.text('Task History'), findsOneWidget);
      expect(find.text('Badges'), findsOneWidget);
    });

    testWidgets('edit button is present', (tester) async {
      await tester.pumpWidget(_buildWithUser(const CandidateProfilePage(), _testCandidate));
      await tester.pump();
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });
  });

  group('RecruiterProfilePage', () {
    testWidgets('renders recruiter name and company', (tester) async {
      await tester.pumpWidget(_buildWithUser(const RecruiterProfilePage(), _testRecruiter));
      await tester.pump();
      expect(find.text('Bob Recruiter'), findsOneWidget);
      expect(find.text('TechCorp'), findsOneWidget);
    });

    testWidgets('renders hiring domains', (tester) async {
      await tester.pumpWidget(_buildWithUser(const RecruiterProfilePage(), _testRecruiter));
      await tester.pump();
      expect(find.text('Engineering'), findsOneWidget);
    });
  });
}
