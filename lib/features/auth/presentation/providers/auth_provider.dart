import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';

// ── Infrastructure providers ──────────────────────────────────────────────────

final dioClientProvider = Provider<DioClient>((ref) => DioClient());

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

final authDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(dio: ref.watch(dioClientProvider).instance);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(dataSource: ref.watch(authDataSourceProvider));
});

// ── Auth state stream ─────────────────────────────────────────────────────────

final authStateProvider = StreamProvider<bool>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// ── Current user ──────────────────────────────────────────────────────────────

final currentUserProvider = StateProvider<UserEntity?>((ref) => null);

// ── Auth notifier ─────────────────────────────────────────────────────────────

class AuthNotifier extends AsyncNotifier<UserEntity?> {
  @override
  Future<UserEntity?> build() async {
    // Fast path: if Firebase says no user, skip the backend call entirely
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return null;

    // Firebase user exists — fetch full profile from backend
    try {
      final user = await ref
          .watch(authRepositoryProvider)
          .getCurrentUser()
          .timeout(const Duration(seconds: 8));
      return user;
    } catch (_) {
      // Backend unreachable or timed out — treat as unauthenticated so user can retry.
      return null;
    }
  }

  Future<void> _persistToken(UserEntity user) async {
    // Store firebase UID as session marker in secure storage
    await ref
        .read(secureStorageProvider)
        .write(key: AppConstants.tokenKey, value: user.firebaseUid);
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    // Clear token cache so the new user's Firebase token is used
    ref.read(dioClientProvider).clearTokenCache();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signInWithGoogle(),
    );
    if (state.valueOrNull != null) await _persistToken(state.value!);
  }

  Future<void> signInWithApple() async {
    state = const AsyncLoading();
    ref.read(dioClientProvider).clearTokenCache();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signInWithApple(),
    );
    if (state.valueOrNull != null) await _persistToken(state.value!);
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    ref.read(dioClientProvider).clearTokenCache();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signInWithEmail(
            email: email,
            password: password,
          ),
    );
    if (state.valueOrNull != null) await _persistToken(state.value!);
  }

  /// Verify phone OTP and sign in — updates notifier state.
  Future<void> signInWithPhone({
    required String verificationId,
    required String otp,
  }) async {
    state = const AsyncLoading();
    ref.read(dioClientProvider).clearTokenCache();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).verifyPhoneOtp(
            verificationId: verificationId,
            otp: otp,
          ),
    );
    if (state.valueOrNull != null) await _persistToken(state.value!);
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? referralCode,
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signUpWithEmail(
            email: email,
            password: password,
            fullName: fullName,
            referralCode: referralCode,
          );
      // Stay signed out — user must verify email then sign in
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    // Clear the cached Dio token so the next user gets a fresh Firebase token
    ref.read(dioClientProvider).clearTokenCache();
    // Reset onboarding state so a new user starts fresh
    ref.read(onboardingProvider.notifier).reset();
    await ref.read(authRepositoryProvider).signOut();
    await ref.read(secureStorageProvider).delete(key: AppConstants.tokenKey);
    state = const AsyncData(null);
    // Force the notifier to rebuild on next sign-in so fresh profile is fetched
    ref.invalidateSelf();
  }

  /// Force-refresh the user profile from backend (e.g. after role change).
  Future<void> refreshUser() async {
    ref.invalidateSelf();
  }

  Future<void> updateUser(Map<String, dynamic> fields) async {
    final updated = await ref.read(authRepositoryProvider).updateUser(fields);
    state = AsyncData(updated);
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, UserEntity?>(
  AuthNotifier.new,
);
