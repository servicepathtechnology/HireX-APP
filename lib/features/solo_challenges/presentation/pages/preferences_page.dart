/// Part 2 — Challenge Preferences Page
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/solo_challenge_entities.dart';
import '../providers/solo_challenge_providers.dart';

class ChallengePreferencesPage extends ConsumerStatefulWidget {
  const ChallengePreferencesPage({super.key});

  @override
  ConsumerState<ChallengePreferencesPage> createState() => _ChallengePreferencesPageState();
}

class _ChallengePreferencesPageState extends ConsumerState<ChallengePreferencesPage> {
  String? _weeklyDay;
  int? _monthlyDate;
  String? _notificationTime;
  String? _timezone;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(preferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenge Preferences'),
      ),
      body: prefsAsync.when(
        data: (prefs) {
          // Initialize values if not set
          _weeklyDay ??= prefs.weeklyDay;
          _monthlyDate ??= prefs.monthlyDate;
          _notificationTime ??= prefs.notificationTime;
          _timezone ??= prefs.timezone;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly Challenge',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _weeklyDay,
                  decoration: const InputDecoration(
                    labelText: 'Preferred Day',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'monday', child: Text('Monday')),
                    DropdownMenuItem(value: 'tuesday', child: Text('Tuesday')),
                    DropdownMenuItem(value: 'wednesday', child: Text('Wednesday')),
                    DropdownMenuItem(value: 'thursday', child: Text('Thursday')),
                    DropdownMenuItem(value: 'friday', child: Text('Friday')),
                    DropdownMenuItem(value: 'saturday', child: Text('Saturday')),
                    DropdownMenuItem(value: 'sunday', child: Text('Sunday')),
                  ],
                  onChanged: (value) {
                    setState(() => _weeklyDay = value);
                  },
                ),
                const SizedBox(height: 24),

                Text(
                  'Monthly Challenge',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _monthlyDate,
                  decoration: const InputDecoration(
                    labelText: 'Preferred Date',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(
                    28,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text('${index + 1}'),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _monthlyDate = value);
                  },
                ),
                const SizedBox(height: 24),

                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _notificationTime,
                  decoration: const InputDecoration(
                    labelText: 'Notification Time (HH:MM)',
                    border: OutlineInputBorder(),
                    hintText: '09:00',
                  ),
                  onChanged: (value) {
                    setState(() => _notificationTime = value);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _timezone,
                  decoration: const InputDecoration(
                    labelText: 'Timezone',
                    border: OutlineInputBorder(),
                    hintText: 'UTC',
                  ),
                  onChanged: (value) {
                    setState(() => _timezone = value);
                  },
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _savePreferences(prefs),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Preferences'),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(preferencesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePreferences(UserPreferences currentPrefs) async {
    setState(() => _isLoading = true);

    try {
      final updatedPrefs = UserPreferences(
        weeklyDay: _weeklyDay ?? currentPrefs.weeklyDay,
        monthlyDate: _monthlyDate ?? currentPrefs.monthlyDate,
        notificationTime: _notificationTime ?? currentPrefs.notificationTime,
        timezone: _timezone ?? currentPrefs.timezone,
        notificationsEnabled: currentPrefs.notificationsEnabled,
      );

      final repository = ref.read(soloChallengeRepositoryProvider);
      await repository.updatePreferences(updatedPrefs);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences saved successfully')),
        );
        ref.invalidate(preferencesProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
