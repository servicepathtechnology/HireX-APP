import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/avatar_crop_page.dart';
import '../../../../shared/widgets/hirex_button.dart';
import '../../../../shared/widgets/hirex_snackbar.dart';
import '../../../../shared/widgets/hirex_tag.dart';
import '../../../../shared/widgets/hirex_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../providers/profile_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _headlineCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _githubCtrl;
  late TextEditingController _linkedinCtrl;
  late TextEditingController _portfolioCtrl;
  late TextEditingController _companyCtrl;
  late TextEditingController _roleAtCompanyCtrl;
  late TextEditingController _customSkillCtrl;

  String? _companySize;
  List<String> _skills = [];
  bool _isDirty = false;
  bool _isUploadingAvatar = false;
  Uint8List? _pendingAvatarBytes;

  static const _companySizes = ['1–10', '11–50', '51–200', '200+'];
  static const _presetSkills = [
    'Flutter', 'React', 'Node.js', 'Python', 'Java', 'Kotlin', 'Swift',
    'TypeScript', 'Go', 'Rust', 'AWS', 'Docker', 'Kubernetes', 'GraphQL',
    'PostgreSQL', 'MongoDB', 'Redis', 'Figma', 'UI/UX Design',
    'Product Management', 'Data Science', 'Machine Learning', 'DevOps',
    'iOS', 'Android', 'Vue.js', 'Angular', 'Django', 'FastAPI',
    'Spring Boot', 'React Native', 'Firebase', 'Next.js', 'Tailwind CSS',
    'Git', 'CI/CD', 'Agile', 'Scrum',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final user = ref.read(profileProvider);
    final cp = user?.candidateProfile;
    final rp = user?.recruiterProfile;

    _nameCtrl = TextEditingController(text: user?.fullName ?? '');
    _headlineCtrl = TextEditingController(text: cp?.headline ?? '');
    _cityCtrl = TextEditingController(text: cp?.city ?? '');
    _bioCtrl = TextEditingController(text: cp?.bio ?? '');
    _githubCtrl = TextEditingController(text: cp?.githubUrl ?? '');
    _linkedinCtrl = TextEditingController(text: cp?.linkedinUrl ?? '');
    _portfolioCtrl = TextEditingController(text: cp?.portfolioUrl ?? '');
    _companyCtrl = TextEditingController(text: rp?.companyName ?? '');
    _roleAtCompanyCtrl = TextEditingController(text: rp?.roleAtCompany ?? '');
    _customSkillCtrl = TextEditingController();
    _companySize = rp?.companySize;
    _skills = List<String>.from(cp?.skillTags ?? []);

    for (final c in [
      _nameCtrl, _headlineCtrl, _cityCtrl, _bioCtrl,
      _githubCtrl, _linkedinCtrl, _portfolioCtrl,
      _companyCtrl, _roleAtCompanyCtrl,
    ]) {
      c.addListener(() => setState(() => _isDirty = true));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customSkillCtrl.dispose();
    for (final c in [
      _nameCtrl, _headlineCtrl, _cityCtrl, _bioCtrl,
      _githubCtrl, _linkedinCtrl, _portfolioCtrl,
      _companyCtrl, _roleAtCompanyCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _toggleSkill(String skill) {
    setState(() {
      _isDirty = true;
      if (_skills.contains(skill)) {
        _skills.remove(skill);
      } else if (_skills.length < 15) {
        _skills.add(skill);
      }
    });
  }

  void _addCustomSkill() {
    final s = _customSkillCtrl.text.trim();
    if (s.isEmpty || _skills.contains(s)) return;
    setState(() {
      _skills.add(s);
      _isDirty = true;
    });
    _customSkillCtrl.clear();
  }

  Future<void> _pickAvatar() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: Text('Take a photo', style: AppTextStyles.bodyLarge),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: Text('Choose from gallery', style: AppTextStyles.bodyLarge),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 90);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      final cropped = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => AvatarCropPage(imageBytes: bytes),
        ),
      );
      if (cropped != null && mounted) {
        setState(() {
          _pendingAvatarBytes = cropped;
          _isDirty = true;
        });
      }
    } catch (_) {
      if (mounted) HireXSnackbar.show(context, message: 'Failed to pick image.', type: SnackbarType.error);
    }
  }

  Future<String?> _uploadAvatar(Uint8List bytes) async {
    try {
      setState(() => _isUploadingAvatar = true);
      final dio = ref.read(dioClientProvider).instance;
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: DioMediaType('image', 'jpeg'),
        ),
      });
      final response = await dio.post(
        '/api/v1/upload/avatar',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          connectTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      return response.data['url'] as String?;
    } catch (e) {
      if (mounted) {
        HireXSnackbar.show(
          context,
          message: 'Photo upload failed. Please try again.',
          type: SnackbarType.error,
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _save() async {
    // Validate form only if it's mounted (may be null if Skills tab is active
    // and Profile tab hasn't rendered yet, or vice versa)
    if (_formKey.currentState != null) {
      if (!_formKey.currentState!.validate()) return;
    } else {
      // Form not mounted — at minimum ensure name isn't empty
      if (_nameCtrl.text.trim().isEmpty) {
        HireXSnackbar.show(context, message: 'Full name is required.', type: SnackbarType.error);
        return;
      }
    }

    final user = ref.read(profileProvider);
    final isCandidate = user?.isCandidate ?? true;

    String? avatarUrl;
    if (_pendingAvatarBytes != null) {
      avatarUrl = await _uploadAvatar(_pendingAvatarBytes!);
      // If upload failed, _uploadAvatar already showed the error — don't save without the photo
      if (avatarUrl == null) return;
    }

    final fields = <String, dynamic>{
      'full_name': _nameCtrl.text.trim(),
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (isCandidate) ...{
        'headline': _headlineCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'github_url': _githubCtrl.text.trim(),
        'linkedin_url': _linkedinCtrl.text.trim(),
        'portfolio_url': _portfolioCtrl.text.trim(),
        'skill_tags': _skills,
      } else ...{
        'company_name': _companyCtrl.text.trim(),
        'role_at_company': _roleAtCompanyCtrl.text.trim(),
        if (_companySize != null) 'company_size': _companySize,
      },
    };

    await ref.read(profileEditProvider.notifier).save(fields);
    if (!mounted) return;
    final editState = ref.read(profileEditProvider);
    if (editState.hasError) {
      HireXSnackbar.show(context, message: editState.error.toString(), type: SnackbarType.error);
    } else {
      ref.invalidate(powProfileProvider);
      HireXSnackbar.show(context, message: 'Profile updated.', type: SnackbarType.success);
      setState(() { _isDirty = false; _pendingAvatarBytes = null; });
      context.pop();
    }
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Unsaved changes', style: AppTextStyles.headlineMedium),
        content: Text('Discard unsaved changes?', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(onPressed: () => dialogCtx.pop(false), child: const Text('Keep editing')),
          TextButton(
            onPressed: () => dialogCtx.pop(true),
            child: Text('Discard', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(profileProvider);
    final isCandidate = user?.isCandidate ?? true;
    final isSaving = ref.watch(profileEditProvider).isLoading || _isUploadingAvatar;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final should = await _onWillPop();
          if (should && context.mounted) context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text('Edit Profile', style: AppTextStyles.titleMedium),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: isSaving ? null : _save,
              child: Text(
                'Save',
                style: AppTextStyles.labelLarge.copyWith(
                  color: isSaving ? AppColors.onSurface.withValues(alpha: 0.4) : AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          bottom: isCandidate
              ? TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.onSurface.withValues(alpha: 0.5),
                  tabs: const [
                    Tab(text: 'Profile'),
                    Tab(text: 'Skills'),
                  ],
                )
              : null,
        ),
        body: isCandidate
            ? TabBarView(
                controller: _tabController,
                children: [
                  _ProfileTab(
                    formKey: _formKey,
                    user: user,
                    nameCtrl: _nameCtrl,
                    headlineCtrl: _headlineCtrl,
                    cityCtrl: _cityCtrl,
                    bioCtrl: _bioCtrl,
                    githubCtrl: _githubCtrl,
                    linkedinCtrl: _linkedinCtrl,
                    portfolioCtrl: _portfolioCtrl,
                    pendingAvatarBytes: _pendingAvatarBytes,
                    isUploadingAvatar: _isUploadingAvatar,
                    onPickAvatar: _pickAvatar,
                    isSaving: isSaving,
                    onSave: _save,
                  ),
                  _SkillsTab(
                    skills: _skills,
                    presetSkills: _presetSkills,
                    customSkillCtrl: _customSkillCtrl,
                    onToggle: _toggleSkill,
                    onAddCustom: _addCustomSkill,
                    isSaving: isSaving,
                    onSave: _save,
                  ),
                ],
              )
            : _RecruiterTab(
                formKey: _formKey,
                user: user,
                nameCtrl: _nameCtrl,
                companyCtrl: _companyCtrl,
                roleAtCompanyCtrl: _roleAtCompanyCtrl,
                companySize: _companySize,
                companySizes: _companySizes,
                pendingAvatarBytes: _pendingAvatarBytes,
                isUploadingAvatar: _isUploadingAvatar,
                onPickAvatar: _pickAvatar,
                isSaving: isSaving,
                onSave: _save,
                onCompanySizeChanged: (v) => setState(() { _companySize = v; _isDirty = true; }),
              ),
      ),
    );
  }
}

// ── Avatar Header ─────────────────────────────────────────────────────────────

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({
    required this.user,
    required this.pendingAvatarBytes,
    required this.isUploading,
    required this.onTap,
  });
  final dynamic user;
  final Uint8List? pendingAvatarBytes;
  final bool isUploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = user?.fullName ?? '';
    final avatarUrl = user?.avatarUrl as String?;
    final initials = name.trim().split(' ') is List
        ? (name.trim().split(' ').length >= 2
            ? '${name.trim().split(' ')[0][0]}${name.trim().split(' ')[1][0]}'.toUpperCase()
            : name.isNotEmpty ? name[0].toUpperCase() : '?')
        : '?';

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  backgroundImage: pendingAvatarBytes != null
                      ? MemoryImage(pendingAvatarBytes!) as ImageProvider
                      : (avatarUrl != null && avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null),
                  child: (pendingAvatarBytes == null && (avatarUrl == null || avatarUrl.isEmpty))
                      ? Text(initials, style: AppTextStyles.headlineLarge.copyWith(color: AppColors.primary))
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                    child: isUploading
                        ? const Padding(
                            padding: EdgeInsets.all(6),
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Change photo',
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ── Profile Tab ───────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.formKey,
    required this.user,
    required this.nameCtrl,
    required this.headlineCtrl,
    required this.cityCtrl,
    required this.bioCtrl,
    required this.githubCtrl,
    required this.linkedinCtrl,
    required this.portfolioCtrl,
    required this.pendingAvatarBytes,
    required this.isUploadingAvatar,
    required this.onPickAvatar,
    required this.isSaving,
    required this.onSave,
  });
  final GlobalKey<FormState> formKey;
  final dynamic user;
  final TextEditingController nameCtrl, headlineCtrl, cityCtrl, bioCtrl;
  final TextEditingController githubCtrl, linkedinCtrl, portfolioCtrl;
  final Uint8List? pendingAvatarBytes;
  final bool isUploadingAvatar;
  final VoidCallback onPickAvatar;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AvatarSection(
              user: user,
              pendingAvatarBytes: pendingAvatarBytes,
              isUploading: isUploadingAvatar,
              onTap: onPickAvatar,
            ),
            const SizedBox(height: 28),
            _SectionLabel('Basic Info'),
            const SizedBox(height: 12),
            HireXTextField(
              label: 'Full Name',
              controller: nameCtrl,
              validator: Validators.fullName,
              prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.onSurface),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            HireXTextField(
              label: 'Professional Headline',
              hint: 'e.g. Flutter Developer | 2 yrs exp',
              controller: headlineCtrl,
              prefixIcon: const Icon(Icons.work_outline_rounded, color: AppColors.onSurface),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            HireXTextField(
              label: 'City / Location',
              controller: cityCtrl,
              prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.onSurface),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            HireXTextField(
              label: 'Bio',
              hint: 'Tell recruiters about yourself...',
              controller: bioCtrl,
              maxLines: 4,
              maxLength: 300,
              prefixIcon: const Icon(Icons.notes_rounded, color: AppColors.onSurface),
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: 20),
            _SectionLabel('Links'),
            const SizedBox(height: 12),
            HireXTextField(
              label: 'GitHub URL',
              controller: githubCtrl,
              prefixIcon: const Icon(Icons.code_rounded, color: AppColors.onSurface),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            HireXTextField(
              label: 'LinkedIn URL',
              controller: linkedinCtrl,
              prefixIcon: const Icon(Icons.link_rounded, color: AppColors.onSurface),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            HireXTextField(
              label: 'Portfolio URL',
              controller: portfolioCtrl,
              prefixIcon: const Icon(Icons.web_rounded, color: AppColors.onSurface),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 32),
            HireXButton(label: 'Save Changes', onPressed: onSave, isLoading: isSaving),
          ],
        ),
      ),
    );
  }
}

// ── Skills Tab ────────────────────────────────────────────────────────────────

class _SkillsTab extends StatelessWidget {
  const _SkillsTab({
    required this.skills,
    required this.presetSkills,
    required this.customSkillCtrl,
    required this.onToggle,
    required this.onAddCustom,
    required this.isSaving,
    required this.onSave,
  });
  final List<String> skills;
  final List<String> presetSkills;
  final TextEditingController customSkillCtrl;
  final ValueChanged<String> onToggle;
  final VoidCallback onAddCustom;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Your Skills', style: AppTextStyles.titleMedium),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${skills.length}/15',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Select up to 15 skills that best represent you',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 16),

          // Selected skills
          if (skills.isNotEmpty) ...[
            Text('Selected', style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.onSurface.withValues(alpha: 0.55),
            )),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.map((s) => GestureDetector(
                onTap: () => onToggle(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(s, style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      )),
                      const SizedBox(width: 4),
                      Icon(Icons.close_rounded, size: 13, color: AppColors.primary),
                    ],
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),
          ],

          // Custom skill input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: customSkillCtrl,
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Add a custom skill...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.onSurface.withValues(alpha: 0.4),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.divider),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onSubmitted: (_) => onAddCustom(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onAddCustom,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Preset skills
          Text('Suggested', style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.onSurface.withValues(alpha: 0.55),
          )),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presetSkills.map((s) {
              final selected = skills.contains(s);
              return GestureDetector(
                onTap: () => onToggle(s),
                child: HireXTag(label: s, isSelected: selected),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          HireXButton(label: 'Save Skills', onPressed: onSave, isLoading: isSaving),
        ],
      ),
    );
  }
}

// ── Recruiter Tab ─────────────────────────────────────────────────────────────

class _RecruiterTab extends StatelessWidget {
  const _RecruiterTab({
    required this.formKey,
    required this.user,
    required this.nameCtrl,
    required this.companyCtrl,
    required this.roleAtCompanyCtrl,
    required this.companySize,
    required this.companySizes,
    required this.pendingAvatarBytes,
    required this.isUploadingAvatar,
    required this.onPickAvatar,
    required this.isSaving,
    required this.onSave,
    required this.onCompanySizeChanged,
  });
  final GlobalKey<FormState> formKey;
  final dynamic user;
  final TextEditingController nameCtrl, companyCtrl, roleAtCompanyCtrl;
  final String? companySize;
  final List<String> companySizes;
  final Uint8List? pendingAvatarBytes;
  final bool isUploadingAvatar;
  final VoidCallback onPickAvatar;
  final bool isSaving;
  final VoidCallback onSave;
  final ValueChanged<String?> onCompanySizeChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AvatarSection(
              user: user,
              pendingAvatarBytes: pendingAvatarBytes,
              isUploading: isUploadingAvatar,
              onTap: onPickAvatar,
            ),
            const SizedBox(height: 28),
            _SectionLabel('Personal'),
            const SizedBox(height: 12),
            HireXTextField(
              label: 'Full Name',
              controller: nameCtrl,
              validator: Validators.fullName,
              prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.onSurface),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),
            _SectionLabel('Company'),
            const SizedBox(height: 12),
            HireXTextField(
              label: 'Company Name',
              controller: companyCtrl,
              prefixIcon: const Icon(Icons.business_outlined, color: AppColors.onSurface),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            HireXTextField(
              label: 'Your Role at Company',
              controller: roleAtCompanyCtrl,
              prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.onSurface),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: companySize,
              decoration: const InputDecoration(labelText: 'Company Size'),
              dropdownColor: AppColors.surface,
              style: AppTextStyles.bodyLarge,
              items: companySizes.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: onCompanySizeChanged,
            ),
            const SizedBox(height: 32),
            HireXButton(label: 'Save Changes', onPressed: onSave, isLoading: isSaving),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.onSurface.withValues(alpha: 0.55),
          letterSpacing: 0.5,
        ),
      );
}
