import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:country_code_picker/country_code_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/hirex_button.dart';
import '../../../../shared/widgets/hirex_scaffold.dart';
import '../../../../shared/widgets/hirex_snackbar.dart';
import '../providers/auth_provider.dart';

class PhoneAuthPage extends ConsumerStatefulWidget {
  const PhoneAuthPage({super.key});

  @override
  ConsumerState<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends ConsumerState<PhoneAuthPage> {
  final _phoneCtrl = TextEditingController();
  String _countryCode = '+91';
  String? _verificationId;
  String _otp = '';
  bool _otpSent = false;
  bool _isLoading = false;
  int _countdown = 0;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final error = Validators.phone(_phoneCtrl.text.trim());
    if (error != null) {
      HireXSnackbar.show(context, message: error, type: SnackbarType.error);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final id = await ref.read(authRepositoryProvider).sendPhoneOtp(
            '$_countryCode${_phoneCtrl.text.trim()}',
          );
      setState(() {
        _verificationId = id;
        _otpSent = true;
        _countdown = 60;
      });
      _startCountdown();
    } catch (e) {
      if (mounted) HireXSnackbar.show(context, message: e.toString(), type: SnackbarType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _countdown--);
      return _countdown > 0;
    });
  }

  Future<void> _verifyOtp() async {
    if (_otp.length != 6 || _verificationId == null) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authNotifierProvider.notifier).signInWithPhone(
            verificationId: _verificationId!,
            otp: _otp,
          );
      // Router's refreshListenable handles navigation automatically
    } catch (e) {
      if (mounted) HireXSnackbar.show(context, message: e.toString(), type: SnackbarType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HireXScaffold(
      appBar: AppBar(title: const Text('Phone Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_otpSent ? 'Enter OTP' : 'Your phone number', style: AppTextStyles.displayMedium),
            const SizedBox(height: 8),
            Text(
              _otpSent
                  ? 'Enter the 6-digit code sent to $_countryCode ${_phoneCtrl.text}'
                  : 'We\'ll send a verification code via SMS.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 32),
            if (!_otpSent) ...[
              Row(
                children: [
                  CountryCodePicker(
                    onChanged: (code) => setState(() => _countryCode = code.dialCode ?? '+91'),
                    initialSelection: 'IN',
                    favorite: const ['+91', 'IN'],
                    showCountryOnly: false,
                    showOnlyCountryWhenClosed: false,
                    alignLeft: false,
                    textStyle: AppTextStyles.bodyLarge,
                    dialogBackgroundColor: AppColors.surface,
                    barrierColor: Colors.black54,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: AppTextStyles.bodyLarge,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              HireXButton(label: 'Send OTP', onPressed: _sendOtp, isLoading: _isLoading),
            ] else ...[
              PinCodeTextField(
                appContext: context,
                length: 6,
                onChanged: (v) => _otp = v,
                onCompleted: (_) => _verifyOtp(),
                keyboardType: TextInputType.number,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(8),
                  fieldHeight: 52,
                  fieldWidth: 44,
                  activeFillColor: AppColors.surface,
                  inactiveFillColor: AppColors.surface,
                  selectedFillColor: AppColors.surfaceVariant,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.divider,
                  selectedColor: AppColors.primary,
                ),
                enableActiveFill: true,
                backgroundColor: Colors.transparent,
              ),
              const SizedBox(height: 24),
              HireXButton(label: 'Verify OTP', onPressed: _verifyOtp, isLoading: _isLoading),
              const SizedBox(height: 16),
              Center(
                child: _countdown > 0
                    ? Text('Resend OTP in ${_countdown}s', style: AppTextStyles.bodyMedium)
                    : TextButton(
                        onPressed: _sendOtp,
                        child: Text('Resend OTP',
                            style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
