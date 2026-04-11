import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:hirex_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:hirex_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:hirex_app/features/auth/data/models/user_model.dart';

// Reuse mock from auth_repository_test — run build_runner to generate
import '../auth/auth_repository_test.mocks.dart';

void main() {
  late MockAuthRemoteDataSource mockDataSource;
  late AuthRepositoryImpl repository;

  final baseModel = UserModel(
    id: 'id',
    firebaseUid: 'uid',
    email: 'test@test.com',
    fullName: 'Test User',
    onboardingComplete: true,
    isVerified: true,
    isActive: true,
  );

  setUp(() {
    mockDataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(dataSource: mockDataSource);
  });

  group('Profile fetch', () {
    test('getCurrentUser returns entity with profile data', () async {
      final modelWithProfile = UserModel(
        id: 'id',
        firebaseUid: 'uid',
        email: 'test@test.com',
        fullName: 'Test User',
        onboardingComplete: true,
        isVerified: true,
        isActive: true,
        candidateProfile: const CandidateProfileModel(
          headline: 'Flutter Dev',
          skillTags: ['Flutter', 'Dart'],
          skillScore: 42,
        ),
      );
      when(mockDataSource.getMe()).thenAnswer((_) async => modelWithProfile);
      final result = await repository.getCurrentUser();
      expect(result?.candidateProfile?.headline, 'Flutter Dev');
      expect(result?.candidateProfile?.skillTags, contains('Flutter'));
      expect(result?.candidateProfile?.skillScore, 42);
    });
  });

  group('Profile update', () {
    test('updateUser sends correct fields and returns updated entity', () async {
      final updated = UserModel(
        id: 'id',
        firebaseUid: 'uid',
        email: 'test@test.com',
        fullName: 'Updated Name',
        onboardingComplete: true,
        isVerified: true,
        isActive: true,
        candidateProfile: const CandidateProfileModel(
          city: 'Bangalore',
          bio: 'Updated bio',
        ),
      );
      when(mockDataSource.updateMe(any)).thenAnswer((_) async => updated);
      final result = await repository.updateUser({
        'full_name': 'Updated Name',
        'city': 'Bangalore',
        'bio': 'Updated bio',
      });
      expect(result.fullName, 'Updated Name');
      expect(result.candidateProfile?.city, 'Bangalore');
      verify(mockDataSource.updateMe(any)).called(1);
    });

    test('updateUser with skill_tags persists correctly', () async {
      final updated = UserModel(
        id: 'id',
        firebaseUid: 'uid',
        email: 'test@test.com',
        fullName: 'Test User',
        onboardingComplete: true,
        isVerified: true,
        isActive: true,
        candidateProfile: const CandidateProfileModel(
          skillTags: ['Flutter', 'React', 'Python'],
        ),
      );
      when(mockDataSource.updateMe(any)).thenAnswer((_) async => updated);
      final result = await repository.updateUser({
        'skill_tags': ['Flutter', 'React', 'Python'],
      });
      expect(result.candidateProfile?.skillTags.length, 3);
    });
  });
}
