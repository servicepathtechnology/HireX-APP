import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/hirex_button.dart';
import '../../../../shared/widgets/hirex_divider.dart';
import '../../../../shared/widgets/hirex_snackbar.dart';
import '../../../../shared/widgets/social_sign_in_button.dart';
import '../providers/auth_provider.dart';

/// Main entry point for unauthenticated users.
class AuthLandingPage extends ConsumerStatefulWidget {
  const AuthLandingPage({super.key});

  @override
  ConsumerState<AuthLandingPage> createState() => _AuthLandingPageState();
}

class _AuthLandingPageState extends ConsumerState<AuthLandingPage> {
  bool _googleLoading = false;
  bool _appleLoading = false;

  Future<void> _handleGoogle() async {
    setState(() => _googleLoading = true);
    try {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();
      // Router's refreshListenable handles navigation automatically
    } catch (e) {
      if (mounted) HireXSnackbar.show(context, message: e.toString(), type: SnackbarType.error);
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _handleApple() async {
    setState(() => _appleLoading = true);
    try {
      await ref.read(authNotifierProvider.notifier).signInWithApple();
      // Router's refreshListenable handles navigation automatically
    } catch (e) {
      if (mounted) HireXSnackbar.show(context, message: e.toString(), type: SnackbarType.error);
    } finally {
      if (mounted) setState(() => _appleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.bolt, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 16),
              Text('HireX', style: AppTextStyles.displayLarge),
              const SizedBox(height: 8),
              Text(
                'Let Work Speak Louder Than Resumes.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              HireXButton(
                label: 'Sign In with Email',
                onPressed: () => context.push('/auth/login'),
              ),
              const SizedBox(height: 12),
              HireXButton(
                label: 'Create Account',
                variant: HireXButtonVariant.secondary,
                onPressed: () => context.push('/auth/signup'),
              ),
              const SizedBox(height: 20),
              const HireXDivider(label: 'or'),
              const SizedBox(height: 20),
              SocialSignInButton(
                provider: SocialProvider.google,
                onPressed: _handleGoogle,
                isLoading: _googleLoading,
              ),
              if (Platform.isIOS) ...[
                const SizedBox(height: 12),
                SocialSignInButton(
                  provider: SocialProvider.apple,
                  onPressed: _handleApple,
                  isLoading: _appleLoading,
                ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.push('/auth/phone'),
                child: Text('Use Phone Number', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
              ),
              const SizedBox(height: 16),
              Text(
                'By continuing you agree to our Terms & Privacy Policy',
                style: AppTextStyles.labelSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
