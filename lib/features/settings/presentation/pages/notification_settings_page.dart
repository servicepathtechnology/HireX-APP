import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/hirex_loader.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final _notifPrefsProvider = FutureProvider<Map<String, bool>>((ref) async {
  final res = await DioClient().instance.get('/api/v1/notifications/prefs');
  final prefs = (res.data as Map<String, dynamic>)['prefs'] as Map<String, dynamic>;
  return prefs.map((k, v) => MapEntry(k, v as bool));
});

class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends ConsumerState<NotificationSettingsPage> {
  Map<String, bool> _prefs = {};
  bool _saving = false;

  Future<void> _toggle(String key, bool value) async {
    setState(() {
      _prefs = {..._prefs, key: value};
      _saving = true;
    });
    try {
      await DioClient().instance.put('/api/v1/notifications/prefs', data: {
        'prefs': {key: value},
      });
    } catch (_) {}
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(_notifPrefsProvider);
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final isCandidate = user?.isCandidate ?? true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notification Settings'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
      body: prefsAsync.when(
        loading: () => const Center(child: HireXLoader()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (prefs) {
          if (_prefs.isEmpty) _prefs = prefs;

          final candidateItems = [
            _PrefItem('submission_scored', 'Score received', 'When your submission is scored'),
            _PrefItem('shortlisted', 'Shortlisted', 'When a recruiter shortlists you'),
            _PrefItem('stage_changed', 'Pipeline stage change', 'When your application stage changes'),
            _PrefItem('hired', 'Hired', 'When you are hired through HireX'),
            _PrefItem('task_closed', 'Scoring has begun', 'When a task you submitted to closes'),
            _PrefItem('new_message', 'New message', 'When you receive a message'),
          ];

          final recruiterItems = [
            _PrefItem('new_submission', 'New submission received', 'When a candidate submits to your task'),
            _PrefItem('ai_scoring_complete', 'AI scoring complete', 'When AI finishes scoring submissions'),
            _PrefItem('new_message', 'New message', 'When you receive a message'),
            _PrefItem('submission_count_milestone', 'Submission milestones', 'Milestone notifications (off by default)'),
          ];

          final items = isCandidate ? candidateItems : recruiterItems;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Choose which notifications you want to receive as push notifications.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 16),
              ...items.map((item) => _PrefTile(
                    item: item,
                    value: _prefs[item.key] ?? true,
                    onChanged: (v) => _toggle(item.key, v),
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _PrefItem {
  const _PrefItem(this.key, this.title, this.subtitle);
  final String key;
  final String title;
  final String subtitle;
}

class _PrefTile extends StatelessWidget {
  const _PrefTile({required this.item, required this.value, required this.onChanged});
  final _PrefItem item;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: AppTextStyles.labelLarge),
                  Text(item.subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      );
}
