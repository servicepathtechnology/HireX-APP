import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/models/referral_models.dart';

class ReferralData {
  final ReferralStats stats;
  final List<ReferralReward> rewards;

  const ReferralData({required this.stats, required this.rewards});
}

final referralProvider = AsyncNotifierProvider<ReferralNotifier, ReferralData>(
  ReferralNotifier.new,
);

class ReferralNotifier extends AsyncNotifier<ReferralData> {
  @override
  Future<ReferralData> build() async {
    final dio = ref.watch(dioClientProvider).instance;
    final statsResp = await dio.get('/referrals/me');
    final rewardsResp = await dio.get('/referrals/rewards');

    final stats = ReferralStats.fromJson(statsResp.data as Map<String, dynamic>);
    final rewards = (rewardsResp.data as List)
        .map((e) => ReferralReward.fromJson(e as Map<String, dynamic>))
        .toList();

    return ReferralData(stats: stats, rewards: rewards);
  }
}
