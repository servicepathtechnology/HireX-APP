import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/hirex_button.dart';
import '../../../../shared/widgets/hirex_snackbar.dart';
import '../providers/onboarding_provider.dart';

/// Step 5 — Profile photo upload (optional).
class OnboardingPhotoPage extends ConsumerStatefulWidget {
  const OnboardingPhotoPage({super.key});

  @override
  ConsumerState<OnboardingPhotoPage> createState() => _OnboardingPhotoPageState();
}

class _OnboardingPhotoPageState extends ConsumerState<OnboardingPhotoPage> {
  File? _imageFile;
  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Photo',
            toolbarColor: const Color(0xFF1A1A2E),
            statusBarColor: const Color(0xFF1A1A2E),
            toolbarWidgetColor: Colors.white,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: AppColors.primary,
            dimmedLayerColor: Colors.black87,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
            showCropGrid: true,
          ),
          IOSUiSettings(
            title: 'Crop Photo',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );

      if (cropped != null) {
        setState(() => _imageFile = File(cropped.path));
        ref.read(onboardingProvider.notifier).setAvatarFile(_imageFile!);
      }
    } catch (e) {
      if (mounted) HireXSnackbar.show(context, message: 'Failed to pick image.', type: SnackbarType.error);
    }
  }

  void _showPickerSheet() {
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

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(onboardingProvider).isLoading;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text('Add a profile photo', style: AppTextStyles.displayMedium),
          const SizedBox(height: 8),
          Text('A photo helps recruiters recognise you.', style: AppTextStyles.bodyMedium),
          const Spacer(),
          GestureDetector(
            onTap: _showPickerSheet,
            child: CircleAvatar(
              radius: 72,
              backgroundColor: AppColors.surfaceVariant,
              backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
              child: _imageFile == null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_a_photo, color: AppColors.primary, size: 36),
                        const SizedBox(height: 8),
                        Text('Add Photo', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                      ],
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 24),
          if (_imageFile != null)
            TextButton(
              onPressed: _showPickerSheet,
              child: Text('Change photo', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
            ),
          const Spacer(),
          HireXButton(
            label: _imageFile != null ? 'Continue' : 'Skip',
            onPressed: () => ref.read(onboardingProvider.notifier).nextStep(),
            isLoading: isLoading || _isUploading,
            variant: _imageFile != null ? HireXButtonVariant.primary : HireXButtonVariant.secondary,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
