import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/hirex_button.dart';
import '../../../../shared/widgets/hirex_snackbar.dart';
import '../../../../shared/widgets/hirex_text_field.dart';
import '../providers/onboarding_provider.dart';

/// Step 3 — Basic info. Fields differ by role.
class OnboardingBasicInfoPage extends ConsumerStatefulWidget {
  const OnboardingBasicInfoPage({super.key});

  @override
  ConsumerState<OnboardingBasicInfoPage> createState() => _OnboardingBasicInfoPageState();
}

class _OnboardingBasicInfoPageState extends ConsumerState<OnboardingBasicInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _headlineCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  String? _companySize;

  static const _companySizes = ['1–10', '11–50', '51–200', '200+'];

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingProvider);
    _nameCtrl.text = state.fullName ?? '';
    _cityCtrl.text = state.city ?? '';
    _headlineCtrl.text = state.headline ?? '';
    _companyCtrl.text = state.companyName ?? '';
    _roleCtrl.text = state.roleAtCompany ?? '';
    _companySize = state.companySize;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _headlineCtrl.dispose();
    _companyCtrl.dispose();
    _roleCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(onboardingProvider.notifier);
    final isCandidate = ref.read(onboardingProvider).isCandidate;

    notifier.setBasicInfo(
      fullName: _nameCtrl.text.trim(),
      city: isCandidate ? _cityCtrl.text.trim() : null,
      headline: isCandidate ? _headlineCtrl.text.trim() : null,
      companyName: !isCandidate ? _companyCtrl.text.trim() : null,
      companySize: !isCandidate ? _companySize : null,
      roleAtCompany: !isCandidate ? _roleCtrl.text.trim() : null,
    );

    await notifier.saveBasicInfoToBackend();
    if (!mounted) return;
    final state = ref.read(onboardingProvider);
    if (state.error != null) {
      HireXSnackbar.show(context, message: state.error!, type: SnackbarType.error);
      return;
    }
    notifier.nextStep();
  }

  @override
  Widget build(BuildContext context) {
    final isCandidate = ref.watch(onboardingProvider).isCandidate;
    final isLoading = ref.watch(onboardingProvider).isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Tell us about yourself', style: AppTextStyles.displayMedium),
            const SizedBox(height: 8),
            Text('This helps us personalise your experience.', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 32),
            HireXTextField(
              label: 'Full Name',
              controller: _nameCtrl,
              validator: Validators.fullName,
              prefixIcon: const Icon(Icons.person_outline, color: AppColors.onSurface),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            if (isCandidate) ...[
              HireXTextField(
                label: 'City / Location (optional)',
                controller: _cityCtrl,
                prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.onSurface),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              HireXTextField(
                label: 'Professional Headline (optional)',
                hint: 'e.g. Flutter Developer | 2 yrs exp',
                controller: _headlineCtrl,
                prefixIcon: const Icon(Icons.work_outline, color: AppColors.onSurface),
                textInputAction: TextInputAction.done,
              ),
            ] else ...[
              HireXTextField(
                label: 'Company Name',
                controller: _companyCtrl,
                validator: (v) => Validators.required(v, field: 'Company name'),
                prefixIcon: const Icon(Icons.business_outlined, color: AppColors.onSurface),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              HireXTextField(
                label: 'Your Role at Company',
                hint: 'e.g. Talent Lead, Founder',
                controller: _roleCtrl,
                validator: (v) => Validators.required(v, field: 'Your role'),
                prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.onSurface),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _companySize,
                decoration: const InputDecoration(labelText: 'Company Size (optional)'),
                dropdownColor: AppColors.surface,
                style: AppTextStyles.bodyLarge,
                items: _companySizes
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _companySize = v),
              ),
            ],
            const SizedBox(height: 40),
            HireXButton(label: 'Continue', onPressed: _submit, isLoading: isLoading),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
