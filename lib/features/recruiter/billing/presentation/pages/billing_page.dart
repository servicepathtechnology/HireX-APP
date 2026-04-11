import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/hirex_scaffold.dart';
import '../../../../../shared/widgets/hirex_loader.dart';
import '../../../presentation/providers/recruiter_providers.dart';
import '../../../data/models/recruiter_models.dart';

class BillingPage extends ConsumerWidget {
  const BillingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(billingProvider);

    return HireXScaffold(
      appBar: AppBar(title: const Text('Billing & Payments')),
      body: paymentsAsync.when(
        loading: () => const Center(child: HireXLoader()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (payments) {
          final now = DateTime.now();
          final thisMonthTotal = payments
              .where((p) => p.status == 'paid' && p.paidAt != null && p.paidAt!.month == now.month && p.paidAt!.year == now.year)
              .fold(0.0, (sum, p) => sum + p.amountInr);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Subscription banner
              GestureDetector(
                onTap: () => context.push('/recruiter/subscription'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium_outlined, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Subscription Plans', style: AppTextStyles.titleSmall.copyWith(color: Colors.white)),
                            Text('Unlimited tasks from ₹9,999/mo', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (payments.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.onSurface.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text('No payments yet', style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  ),
                )
              else ...[
                // Summary card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Spent this month', style: AppTextStyles.bodySmall),
                          Text('₹${NumberFormat('#,##0').format(thisMonthTotal)}', style: AppTextStyles.headlineLarge.copyWith(color: AppColors.primary)),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Total payments', style: AppTextStyles.bodySmall),
                          Text('${payments.length}', style: AppTextStyles.titleMedium),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('Payment History', style: AppTextStyles.titleSmall),
                const SizedBox(height: 8),
                ...payments.map((p) => _PaymentTile(payment: p)),
              ],
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.help_outline, size: 16),
                  label: const Text('Need help with billing? Contact support'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment});
  final PaymentModel payment;

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (payment.status) {
      case 'paid': statusColor = AppColors.success; break;
      case 'failed': statusColor = AppColors.error; break;
      case 'refunded': statusColor = AppColors.warning; break;
      default: statusColor = AppColors.onSurface;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment.taskTitle ?? 'Task', style: AppTextStyles.titleSmall),
                Text('${payment.tier[0].toUpperCase()}${payment.tier.substring(1)} tier', style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurface.withValues(alpha: 0.6))),
                if (payment.paidAt != null)
                  Text(DateFormat('dd MMM yyyy').format(payment.paidAt!), style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurface.withValues(alpha: 0.5))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${NumberFormat('#,##0').format(payment.amountInr)}', style: AppTextStyles.titleSmall),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Text(payment.status, style: AppTextStyles.bodySmall.copyWith(color: statusColor)),
              ),
              if (payment.status == 'paid')
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  child: const Text('Download Invoice', style: TextStyle(fontSize: 11)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
