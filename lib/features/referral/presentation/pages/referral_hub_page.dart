import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/deep_link/deep_link_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/hirex_loader.dart';
import '../../../../shared/widgets/hirex_scaffold.dart';
import '../../data/models/referral_models.dart';
import '../providers/referral_provider.dart';

class ReferralHubPage extends ConsumerWidget {
  const ReferralHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referralAsync = ref.watch(referralProvider);
    final user = ref.watch(authNotifierProvider).valueOrNull;

    return HireXScaffold(
      appBar: AppBar(title: const Text('Refer & Earn')),
      body: referralAsync.when(
        loading: () => const Center(child: HireXLoader()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ReferralCodeCard(
              code: data.stats.referralCode,
              onShare: () => _shareReferral(
                context,
                data.stats.referralCode,
                user?.fullName ?? 'A friend',
              ),
            ),
            const SizedBox(height: 16),
            _StatsRow(stats: data.stats),
            const SizedBox(height: 24),
            Text('How it works', style: AppTextStyles.titleMedium),
            const SizedBox(height: 12),
            const _HowItWorksCard(),
            const SizedBox(height: 24),
            Text('Reward History', style: AppTextStyles.titleMedium),
            const SizedBox(height: 12),
            if (data.rewards.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No rewards yet. Start referring!',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              )
            else
              ...data.rewards.map((r) => _RewardTile(reward: r)),
          ],
        ),
      ),
    );
  }

  Future<void> _shareReferral(
    BuildContext context,
    String code,
    String userName,
  ) async {
    final link = await DeepLinkHandler.instance.createReferralLink(code, userName);
    final shareText = link != null
        ? '$userName invited you to HireX — prove your skills, get hired!\n$link'
        : 'Join HireX with my referral code: $code\nhttps://hirex.app/ref/$code';
    await Share.share(shareText, subject: 'Join HireX');
    AnalyticsService.instance.referralLinkShared(code, 'share_sheet');
  }
}

// ── Referral code card ────────────────────────────────────────────────────────

class _ReferralCodeCard extends StatelessWidget {
  const _ReferralCodeCard({required this.code, required this.onShare});
  final String code;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Your Referral Code',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                code,
                style: AppTextStyles.displaySmall
                    .copyWith(color: Colors.white, letterSpacing: 2),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.white70),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code copied!')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.share),
            label: const Text('Share Invite Link'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});
  final ReferralStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(label: 'Referred', value: '${stats.totalReferred}'),
        const SizedBox(width: 8),
        _StatChip(label: 'Joined', value: '${stats.totalJoined}'),
        const SizedBox(width: 8),
        _StatChip(label: 'Rewards', value: '${stats.rewardsEarned}'),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary),
            ),
            Text(label, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}

// ── How it works ──────────────────────────────────────────────────────────────

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          _HowItWorksStep(step: '1', text: 'Share your referral link with friends'),
          _HowItWorksStep(step: '2', text: 'They sign up and complete their first task'),
          _HowItWorksStep(step: '3', text: 'You both get rewarded automatically'),
        ],
      ),
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  const _HowItWorksStep({required this.step, required this.text});
  final String step, text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary,
            child: Text(
              step,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}

// ── Reward tile ───────────────────────────────────────────────────────────────

class _RewardTile extends StatelessWidget {
  const _RewardTile({required this.reward});
  final ReferralReward reward;

  @override
  Widget build(BuildContext context) {
    final isIssued = reward.status == 'issued';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isIssued
            ? Colors.green.withValues(alpha: 0.15)
            : AppColors.surface,
        child: Icon(
          isIssued ? Icons.check_circle : Icons.hourglass_empty,
          color: isIssued
              ? Colors.green
              : AppColors.onSurface.withValues(alpha: 0.4),
        ),
      ),
      title: Text(_rewardLabel(reward.rewardType), style: AppTextStyles.bodyMedium),
      subtitle: Text(
        reward.referredUserName ?? 'Referred user',
        style: AppTextStyles.bodySmall,
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isIssued
              ? Colors.green.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          reward.status,
          style: AppTextStyles.labelSmall.copyWith(
            color: isIssued ? Colors.green : AppColors.onSurface,
          ),
        ),
      ),
    );
  }

  String _rewardLabel(String type) {
    switch (type) {
      case 'spotlight':
        return '7-day Profile Spotlight';
      case 'cashback':
        return '₹500 Cashback Credit';
      case 'free_task':
        return 'Free Task Posting Credit';
      case 'score_bonus':
        return '+50 Skill Score Bonus';
      case 'discount':
        return '20% Task Discount';
      default:
        return type;
    }
  }
}
