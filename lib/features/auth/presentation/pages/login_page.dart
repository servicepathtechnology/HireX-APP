import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/hirex_button.dart';
import '../../../../shared/widgets/hirex_scaffold.dart';
import '../../../../shared/widgets/hirex_snackbar.dart';
import '../../../../shared/widgets/hirex_text_field.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _autoValidate = false;
  bool _isLoading = false;
  bool _showResendVerification = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _autoValidate = true;
      _showResendVerification = false;
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authNotifierProvider.notifier).signInWithEmail(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
      // Router's refreshListenable handles navigation automatically
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        final isVerificationError = msg.contains('verify your email');
        if (isVerificationError) {
          setState(() => _showResendVerification = true);
        }
        HireXSnackbar.show(context, message: msg, type: SnackbarType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HireXScaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          autovalidateMode: _autoValidate ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back', style: AppTextStyles.displayMedium),
              const SizedBox(height: 8),
              Text('Sign in to continue.', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 32),
              HireXTextField(
                label: 'Email',
                controller: _emailCtrl,
                validator: Validators.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.onSurface),
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 16),
              HireXTextField(
                label: 'Password',
                controller: _passwordCtrl,
                obscureText: true,
                validator: (v) => v == null || v.isEmpty ? 'Password is required.' : null,
                textInputAction: TextInputAction.done,
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.onSurface),
                onFieldSubmitted: (_) => _submit(),
                autofillHints: const [AutofillHints.password],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/auth/forgot-password'),
                  child: Text('Forgot Password?',
                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                ),
              ),
              const SizedBox(height: 24),
              HireXButton(label: 'Sign In', onPressed: _submit, isLoading: _isLoading),
              if (_showResendVerification) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.email_outlined, color: AppColors.warning, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Email not verified. Check your inbox or resend.',
                          style: AppTextStyles.labelMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.push('/auth/signup'),
                  child: Text("Don't have an account? Create one",
                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
