import '../entities/user_entity.dart';

/// Abstract contract for auth operations.
/// Implemented in the data layer — domain never touches Firebase directly.
abstract class AuthRepository {
  /// Sign in with email and password.
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  });

  /// Create a new account with email and password.
  /// Signs out after creating the account so the user must verify email first.
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? referralCode,
  });

  /// Sign in with Google OAuth.
  Future<UserEntity> signInWithGoogle();

  /// Sign in with Apple OAuth (iOS only).
  Future<UserEntity> signInWithApple();

  /// Send OTP to phone number.
  Future<String> sendPhoneOtp(String phoneNumber);

  /// Verify OTP and sign in.
  Future<UserEntity> verifyPhoneOtp({
    required String verificationId,
    required String otp,
  });

  /// Send password reset email.
  Future<void> sendPasswordResetEmail(String email);

  /// Sign out and clear local storage.
  Future<void> signOut();

  /// Get the current authenticated user from the backend.
  Future<UserEntity?> getCurrentUser();

  /// Update user profile fields.
  Future<UserEntity> updateUser(Map<String, dynamic> fields);

  /// Stream of Firebase auth state changes.
  Stream<bool> get authStateChanges;
}
