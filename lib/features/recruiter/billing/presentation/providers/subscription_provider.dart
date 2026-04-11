import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/models/subscription_models.dart';

final subscriptionProvider = AsyncNotifierProvider<SubscriptionNotifier, SubscriptionStatus>(
  SubscriptionNotifier.new,
);

class SubscriptionNotifier extends AsyncNotifier<SubscriptionStatus> {
  @override
  Future<SubscriptionStatus> build() async {
    final dio = ref.watch(dioClientProvider).instance;
    final resp = await dio.get('/billing/subscriptions/me');
    return SubscriptionStatus.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> createSubscription(String plan, String billingPeriod) async {
    state = const AsyncLoading();
    final dio = ref.read(dioClientProvider).instance;
    await dio.post('/billing/subscriptions/create', data: {
      'plan': plan,
      'billing_period': billingPeriod,
    });
    state = await AsyncValue.guard(() async {
      final resp = await dio.get('/billing/subscriptions/me');
      return SubscriptionStatus.fromJson(resp.data as Map<String, dynamic>);
    });
  }

  Future<void> cancelSubscription() async {
    final dio = ref.read(dioClientProvider).instance;
    await dio.delete('/billing/subscriptions/me');
    ref.invalidateSelf();
  }
}
