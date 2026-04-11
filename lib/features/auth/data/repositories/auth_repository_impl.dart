import 'package:dio/dio.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../../../../core/errors/app_exception.dart';

/// Concrete implementation of [AuthRepository].
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required AuthRemoteDataSource dataSource})
      : _dataSource = dataSource;

  final AuthRemoteDataSource _dataSource;

  @override
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _dataSource.signInWithEmail(email: email, password: password);
    final firebaseUser = credential.user!;

    // Enforce email verification
    if (!firebaseUser.emailVerified) {
      await _dataSource.sendEmailVerification();
      await _dataSource.signOut();
      throw const AuthException('Please verify your email before signing in. A new verification link has been sent.');
    }

    // Always fetch the fresh profile from backend — never use register response
    // for sign-in (register is for new accounts only)
    try {
      final model = await _dataSource.getMe();
      return model.toEntity();
    } catch (_) {
      // Backend doesn't have this user yet — register them
      final model = await _dataSource.registerInBackend(
        firebaseUid: firebaseUser.uid,
        email: email,
        fullName: firebaseUser.displayName ?? email.split('@').first,
      );
      return model.toEntity();
    }
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? referralCode,
  }) async {
    final credential = await _dataSource.signUpWithEmail(email: email, password: password);
    final user = credential.user!;
    await _dataSource.sendEmailVerification();
    try {
      await _dataSource.registerInBackend(
        firebaseUid: user.uid,
        email: email,
        fullName: fullName,
        referralCode: referralCode,
      );
    } catch (_) {
      // Backend registration failed — will retry on first login
    }
    // Sign out immediately so the router doesn't redirect away from the
    // "check your email" screen. User must verify then sign in manually.
    await _dataSource.signOut();
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    final credential = await _dataSource.signInWithGoogle();
    final user = credential.user!;
    final isNew = credential.additionalUserInfo?.isNewUser ?? false;
    if (isNew) {
      // New user — register in backend
      try {
        final model = await _dataSource.registerInBackend(
          firebaseUid: user.uid,
          email: user.email ?? '',
          fullName: user.displayName ?? '',
        );
        return model.toEntity();
      } catch (_) {
        // Registration failed — fall through to getMe
      }
    }
    // Existing user — always fetch fresh profile from backend
    final model = await _dataSource.getMe();
    return model.toEntity();
  }

  @override
  Future<UserEntity> signInWithApple() async {
    final credential = await _dataSource.signInWithApple();
    final user = credential.user!;
    final isNew = credential.additionalUserInfo?.isNewUser ?? false;
    if (isNew) {
      await _dataSource.registerInBackend(
        firebaseUid: user.uid,
        email: user.email ?? '',
        fullName: user.displayName ?? '',
      );
    }
    final model = await _dataSource.getMe();
    return model.toEntity();
  }

  @override
  Future<String> sendPhoneOtp(String phoneNumber) =>
      _dataSource.sendPhoneOtp(phoneNumber);

  @override
  Future<UserEntity> verifyPhoneOtp({
    required String verificationId,
    required String otp,
  }) async {
    final credential = await _dataSource.verifyPhoneOtp(
      verificationId: verificationId,
      otp: otp,
    );
    final user = credential.user!;
    final isNew = credential.additionalUserInfo?.isNewUser ?? false;
    if (isNew) {
      await _dataSource.registerInBackend(
        firebaseUid: user.uid,
        email: user.email ?? '',
        fullName: user.displayName ?? '',
      );
    }
    final model = await _dataSource.getMe();
    return model.toEntity();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _dataSource.sendPasswordResetEmail(email);

  @override
  Future<void> signOut() => _dataSource.signOut();

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final model = await _dataSource.getMe();
      return model.toEntity();
    } on DioException catch (e) {
      // 404 means user not in backend yet — not an error, just not registered
      if (e.response?.statusCode == 404) return null;
      rethrow;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserEntity> updateUser(Map<String, dynamic> fields) async {
    final model = await _dataSource.updateMe(fields);
    return model.toEntity();
  }

  @override
  Stream<bool> get authStateChanges => _dataSource.authStateChanges;
}
