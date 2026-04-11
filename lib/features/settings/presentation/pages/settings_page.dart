import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/hirex_scaffold.dart';
import '../../../../shared/widgets/hirex_snackbar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HireXScaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _SectionHeader('Account'),
          _SettingsTile(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            onTap: () => context.push('/profile/edit'),
          ),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () => _changePassword(context, ref),
          ),
          _SettingsTile(
            icon: Icons.link,
            title: 'Linked Accounts',
            onTap: () => _showLinkedAccounts(context),
          ),
          _SectionHeader('Notifications'),
          _SettingsTile(
            icon: Icons.tune_outlined,
            title: 'Notification Preferences',
            onTap: () => context.push('/settings/notifications'),
          ),
          _SettingsToggle(title: 'Push Notifications', icon: Icons.notifications_outlined),
          _SettingsToggle(title: 'Email Notifications', icon: Icons.email_outlined),
          _SectionHeader('App'),
          _SettingsToggle(title: 'Dark Mode', icon: Icons.dark_mode_outlined, value: true, enabled: false),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'App Version',
            trailing: Text('1.0.0', style: AppTextStyles.bodyMedium),
            onTap: null,
          ),
          _SectionHeader('Legal'),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () => _launchUrl('https://hirex.app/terms'),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => _launchUrl('https://hirex.app/privacy'),
          ),
          _SettingsTile(
            icon: Icons.download_outlined,
            title: 'Download My Data',
            onTap: () => _requestDataExport(context, ref),
          ),
          _SectionHeader('Referral'),
          _SettingsTile(
            icon: Icons.card_giftcard_outlined,
            title: 'Refer & Earn',
            onTap: () => context.push('/referral'),
          ),
          _SectionHeader('Danger Zone'),
          _SettingsTile(
            icon: Icons.logout,
            title: 'Sign Out',
            titleColor: AppColors.error,
            onTap: () => _confirmSignOut(context, ref),
          ),
          _SettingsTile(
            icon: Icons.delete_forever_outlined,
            title: 'Delete Account',
            titleColor: AppColors.error,
            onTap: () => _confirmDeleteAccount(context, ref),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;
    await ref.read(authRepositoryProvider).sendPasswordResetEmail(user.email);
    if (context.mounted) {
      HireXSnackbar.show(context, message: 'Password reset email sent.', type: SnackbarType.success);
    }
  }

  void _showLinkedAccounts(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Linked Accounts', style: AppTextStyles.headlineLarge),
            const SizedBox(height: 16),
            _LinkedAccountRow(icon: Icons.email_outlined, label: 'Email', linked: true),
            _LinkedAccountRow(icon: Icons.g_mobiledata, label: 'Google', linked: false),
            _LinkedAccountRow(icon: Icons.apple, label: 'Apple', linked: false),
            _LinkedAccountRow(icon: Icons.phone_outlined, label: 'Phone', linked: false),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Sign Out', style: AppTextStyles.headlineMedium),
        content: Text('Are you sure you want to sign out?', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sign Out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (context.mounted) context.go('/auth');
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete Account', style: AppTextStyles.headlineMedium),
        content: Text(
          'This will permanently delete your account and all data. This cannot be undone.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        final dio = ref.read(dioClientProvider).instance;
        await dio.delete('/auth/me');
        await ref.read(authNotifierProvider.notifier).signOut();
        if (context.mounted) {
          HireXSnackbar.show(context, message: 'Account deletion initiated. Data will be wiped within 30 days.', type: SnackbarType.success);
          context.go('/auth');
        }
      } catch (e) {
        if (context.mounted) {
          HireXSnackbar.show(context, message: 'Error: $e', type: SnackbarType.error);
        }
      }
    }
  }

  Future<void> _requestDataExport(BuildContext context, WidgetRef ref) async {
    try {
      final dio = ref.read(dioClientProvider).instance;
      await dio.get('/auth/me/export');
      if (context.mounted) {
        HireXSnackbar.show(context, message: 'Data export requested. You will receive an email when ready.', type: SnackbarType.success);
      }
    } catch (e) {
      if (context.mounted) {
        HireXSnackbar.show(context, message: 'Error: $e', type: SnackbarType.error);
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title, style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: titleColor ?? AppColors.onSurface),
      title: Text(title, style: AppTextStyles.bodyLarge.copyWith(color: titleColor)),
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right, color: AppColors.onSurface) : null),
      onTap: onTap,
    );
  }
}

class _SettingsToggle extends StatefulWidget {
  const _SettingsToggle({required this.title, required this.icon, this.value = false, this.enabled = true});
  final String title;
  final IconData icon;
  final bool value;
  final bool enabled;

  @override
  State<_SettingsToggle> createState() => _SettingsToggleState();
}

class _SettingsToggleState extends State<_SettingsToggle> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(widget.icon, color: AppColors.onSurface),
      title: Text(widget.title, style: AppTextStyles.bodyLarge),
      trailing: Switch(
        value: _value,
        onChanged: widget.enabled ? (v) => setState(() => _value = v) : null,
        activeThumbColor: AppColors.primary,
      ),
    );
  }
}

class _LinkedAccountRow extends StatelessWidget {
  const _LinkedAccountRow({required this.icon, required this.label, required this.linked});
  final IconData icon;
  final String label;
  final bool linked;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.onSurface),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppTextStyles.bodyLarge)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: linked ? AppColors.success.withValues(alpha: 0.15) : AppColors.divider,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              linked ? 'Linked' : 'Not linked',
              style: AppTextStyles.labelSmall.copyWith(
                color: linked ? AppColors.success : AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
