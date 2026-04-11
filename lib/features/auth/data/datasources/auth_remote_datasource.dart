import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/user_model.dart';

/// Handles all Firebase Auth calls and backend API calls for auth.
class AuthRemoteDataSource {
  AuthRemoteDataSource({required Dio dio})
      : _dio = dio,
        _firebaseAuth = FirebaseAuth.instance,
        _googleSignIn = GoogleSignIn(serverClientId: _webClientId);

  final Dio _dio;
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  // Web client ID (type 3) from google-services.json — required for idToken on Android
  static const _webClientId =
      '888625993836-9dafumf1ed0l5v7ucupb6mmiak79hilu.apps.googleusercontent.com';

  /// Register user in backend DB after Firebase signup.
  Future<UserModel> registerInBackend({
    required String firebaseUid,
    required String email,
    required String fullName,
    String? referralCode,
  }) async {
    final response = await _dio.post('/api/v1/auth/register', data: {
      'firebase_uid': firebaseUid,
      'email': email,
      'full_name': fullName,
      if (referralCode != null && referralCode.isNotEmpty) 'referral_code': referralCode,
    });
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Sign in with email and password via Firebase.
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapFirebaseError(e.code));
    }
  }

  /// Create account with email and password via Firebase.
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapFirebaseError(e.code));
    }
  }

  /// Send email verification to current user.
  Future<void> sendEmailVerification() async {
    await _firebaseAuth.currentUser?.sendEmailVerification();
  }

  /// Google Sign-In flow — always shows account picker.
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Sign out first to force account picker (handles multi-account switching)
      await _googleSignIn.signOut();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw const AuthException('Google sign-in cancelled.');
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapFirebaseError(e.code));
    }
  }

  /// Apple Sign-In flow (iOS only).
  Future<UserCredential> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      return await _firebaseAuth.signInWithCredential(oauthCredential);
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapFirebaseError(e.code));
    }
  }

  /// Send OTP to phone number.
  Future<String> sendPhoneOtp(String phoneNumber) async {
    String? verificationId;
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (_) {},
      verificationFailed: (e) => throw AuthException(mapFirebaseError(e.code)),
      codeSent: (id, _) => verificationId = id,
      codeAutoRetrievalTimeout: (_) {},
      timeout: const Duration(seconds: 60),
    );
    if (verificationId == null) throw const AuthException('Failed to send OTP.');
    return verificationId!;
  }

  /// Verify OTP and sign in.
  Future<UserCredential> verifyPhoneOtp({
    required String verificationId,
    required String otp,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      return await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapFirebaseError(e.code));
    }
  }

  /// Send password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapFirebaseError(e.code));
    }
  }

  /// Fetch current user from backend.
  Future<UserModel> getMe() async {
    final response = await _dio.get('/api/v1/auth/me');
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Update user profile.
  Future<UserModel> updateMe(Map<String, dynamic> fields) async {
    final response = await _dio.put('/api/v1/auth/me', data: fields);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Sign out from Firebase.
  Future<void> signOut() async {
    try {
      // disconnect() fully revokes Google token so next signIn() shows account picker
      await _googleSignIn.disconnect();
    } catch (_) {
      // disconnect can fail if user wasn't signed in with Google — ignore
      await _googleSignIn.signOut();
    }
    await _firebaseAuth.signOut();
  }

  Stream<bool> get authStateChanges =>
      _firebaseAuth.authStateChanges().map((user) => user != null);
}
