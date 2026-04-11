import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:hirex_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:hirex_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:hirex_app/features/auth/data/models/user_model.dart';
import 'package:hirex_app/core/errors/app_exception.dart';

@GenerateMocks([AuthRemoteDataSource])
import 'auth_repository_test.mocks.dart';

void main() {
  late MockAuthRemoteDataSource mockDataSource;
  late AuthRepositoryImpl repository;

  final testUserModel = UserModel(
    id: 'test-id',
    firebaseUid: 'firebase-uid',
    email: 'test@example.com',
    fullName: 'Test User',
    onboardingComplete: false,
    isVerified: false,
    isActive: true,
  );

  setUp(() {
    mockDataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(dataSource: mockDataSource);
  });

  group('getCurrentUser', () {
    test('returns UserEntity on success', () async {
      when(mockDataSource.getMe()).thenAnswer((_) async => testUserModel);
      final result = await repository.getCurrentUser();
      expect(result, isNotNull);
      expect(result!.email, 'test@example.com');
    });

    test('returns null on error', () async {
      when(mockDataSource.getMe()).thenThrow(const NetworkException('No connection'));
      final result = await repository.getCurrentUser();
      expect(result, isNull);
    });
  });

  group('updateUser', () {
    test('returns updated UserEntity', () async {
      final updated = UserModel(
        id: 'test-id',
        firebaseUid: 'firebase-uid',
        email: 'test@example.com',
        fullName: 'Updated Name',
        onboardingComplete: true,
        isVerified: true,
        isActive: true,
      );
      when(mockDataSource.updateMe(any)).thenAnswer((_) async => updated);
      final result = await repository.updateUser({'full_name': 'Updated Name'});
      expect(result.fullName, 'Updated Name');
      expect(result.onboardingComplete, true);
    });
  });

  group('sendPasswordResetEmail', () {
    test('completes without error', () async {
      when(mockDataSource.sendPasswordResetEmail(any)).thenAnswer((_) async {});
      expect(() => repository.sendPasswordResetEmail('test@example.com'), returnsNormally);
    });
  });
}
