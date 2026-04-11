class SubscriptionStatus {
  final String? plan;
  final String? status;
  final DateTime? validUntil;
  final int? activeTaskLimit;
  final int activeTasksUsed;
  final String? subscriptionId;

  const SubscriptionStatus({
    this.plan,
    this.status,
    this.validUntil,
    this.activeTaskLimit,
    required this.activeTasksUsed,
    this.subscriptionId,
  });

  bool get isActive => status == 'active';
  bool get hasSubscription => plan != null && plan!.isNotEmpty;

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) => SubscriptionStatus(
        plan: json['plan'] as String?,
        status: json['status'] as String?,
        validUntil: json['valid_until'] != null ? DateTime.parse(json['valid_until'] as String) : null,
        activeTaskLimit: json['active_task_limit'] as int?,
        activeTasksUsed: json['active_tasks_used'] as int? ?? 0,
        subscriptionId: json['subscription_id'] as String?,
      );
}

class SubscriptionPlan {
  final String id;
  final String name;
  final int monthlyPriceInr;
  final int annualPriceInr;
  final int activeTaskLimit;
  final List<String> features;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.monthlyPriceInr,
    required this.annualPriceInr,
    required this.activeTaskLimit,
    required this.features,
  });
}

const kSubscriptionPlans = [
  SubscriptionPlan(
    id: 'starter',
    name: 'Starter',
    monthlyPriceInr: 9999,
    annualPriceInr: 99999,
    activeTaskLimit: 3,
    features: ['Up to 3 active tasks', 'Unlimited submissions', 'AI scoring', 'Basic analytics'],
  ),
  SubscriptionPlan(
    id: 'growth',
    name: 'Growth',
    monthlyPriceInr: 24999,
    annualPriceInr: 249999,
    activeTaskLimit: 10,
    features: ['Up to 10 active tasks', 'All AI features', 'Advanced analytics', 'Priority support', 'Candidate export'],
  ),
  SubscriptionPlan(
    id: 'enterprise',
    name: 'Enterprise',
    monthlyPriceInr: 0,
    annualPriceInr: 0,
    activeTaskLimit: 9999,
    features: ['Unlimited tasks', 'White-label option', 'API access', 'Dedicated account manager', 'SLA guarantee'],
  ),
];
