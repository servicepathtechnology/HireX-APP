import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Exposes the current user for profile screens.
/// Delegates all mutations to [authNotifierProvider].
final profileProvider = Provider<UserEntity?>((ref) {
  return ref.watch(authNotifierProvider).valueOrNull;
});

class ProfileEditNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> save(Map<String, dynamic> fields) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authNotifierProvider.notifier).updateUser(fields),
    );
  }
}

final profileEditProvider = AsyncNotifierProvider<ProfileEditNotifier, void>(
  ProfileEditNotifier.new,
);
