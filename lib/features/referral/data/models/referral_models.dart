class ReferralStats {
  final String referralCode;
  final int totalReferred;
  final int totalJoined;
  final int rewardsEarned;

  const ReferralStats({
    required this.referralCode,
    required this.totalReferred,
    required this.totalJoined,
    required this.rewardsEarned,
  });

  factory ReferralStats.fromJson(Map<String, dynamic> json) => ReferralStats(
        referralCode: json['referral_code'] as String,
        totalReferred: json['total_referred'] as int? ?? 0,
        totalJoined: json['total_joined'] as int? ?? 0,
        rewardsEarned: json['rewards_earned'] as int? ?? 0,
      );
}

class ReferralReward {
  final String id;
  final String rewardType;
  final String? rewardValue;
  final String status;
  final String? referredUserName;
  final DateTime createdAt;
  final DateTime? issuedAt;

  const ReferralReward({
    required this.id,
    required this.rewardType,
    this.rewardValue,
    required this.status,
    this.referredUserName,
    required this.createdAt,
    this.issuedAt,
  });

  factory ReferralReward.fromJson(Map<String, dynamic> json) => ReferralReward(
        id: json['id'] as String,
        rewardType: json['reward_type'] as String,
        rewardValue: json['reward_value'] as String?,
        status: json['status'] as String,
        referredUserName: json['referred_user_name'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        issuedAt: json['issued_at'] != null ? DateTime.parse(json['issued_at'] as String) : null,
      );
}
