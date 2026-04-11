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

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key, this.referralCode});
  final String? referralCode;

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  late final TextEditingController _referralCtrl;
  bool _autoValidate = false;
  bool _isLoading = false;
  bool _emailSent = false;
  int _passwordStrength = 0;

  @override
  void initState() {
    super.initState();
    _referralCtrl = TextEditingController(text: widget.referralCode ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _referralCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _autoValidate = true);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authNotifierProvider.notifier).signUpWithEmail(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            fullName: _nameCtrl.text.trim(),
            referralCode: _referralCtrl.text.trim().isEmpty ? null : _referralCtrl.text.trim().toUpperCase(),
          );
      if (mounted) setState(() => _emailSent = true);
    } catch (e) {
      if (mounted) HireXSnackbar.show(context, message: e.toString(), type: SnackbarType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _strengthIndicator() {
    final labels = ['Weak', 'Medium', 'Strong'];
    final colors = [AppColors.error, AppColors.warning, AppColors.success];
    if (_passwordCtrl.text.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        ...List.generate(3, (i) => Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: i <= _passwordStrength ? colors[_passwordStrength] : AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            )),
        const SizedBox(width: 8),
        Text(labels[_passwordStrength], style: AppTextStyles.labelSmall.copyWith(color: colors[_passwordStrength])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_emailSent) {
      return HireXScaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_read_outlined, color: AppColors.success, size: 72),
              const SizedBox(height: 24),
              Text('Check your email', style: AppTextStyles.headlineLarge),
              const SizedBox(height: 12),
              Text(
                'We sent a verification link to ${_emailCtrl.text.trim()}. Verify your email to continue.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              HireXButton(label: 'Back to Sign In', onPressed: () => context.go('/auth/login')),
            ],
          ),
        ),
      );
    }

    return HireXScaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          autovalidateMode: _autoValidate ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Join HireX', style: AppTextStyles.displayMedium),
              const SizedBox(height: 8),
              Text('Prove your skills. Get hired.', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 32),
              HireXTextField(
                label: 'Full Name',
                controller: _nameCtrl,
                validator: Validators.fullName,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.person_outline, color: AppColors.onSurface),
              ),
              const SizedBox(height: 16),
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
                validator: Validators.password,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.onSurface),
                onChanged: (v) => setState(() => _passwordStrength = Validators.passwordStrength(v)),
              ),
              const SizedBox(height: 8),
              _strengthIndicator(),
              const SizedBox(height: 16),
              HireXTextField(
                label: 'Confirm Password',
                controller: _confirmCtrl,
                obscureText: true,
                validator: (v) => Validators.confirmPassword(v, _passwordCtrl.text),
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.onSurface),
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              HireXTextField(
                label: 'Referral Code (optional)',
                controller: _referralCtrl,
                textInputAction: TextInputAction.done,
                prefixIcon: const Icon(Icons.card_giftcard_outlined, color: AppColors.onSurface),
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 32),
              HireXButton(label: 'Create Account', onPressed: _submit, isLoading: _isLoading),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: Text('Already have an account? Sign In',
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
