import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/onboarding_strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Optional profile-picture placeholder with mock camera/file-picker buttons.
/// No real camera or gallery integration — selecting either just stores a
/// stable mock reference string so the UI can show a "picked" state.
class ProfilePicturePicker extends StatelessWidget {
  final String? pickedPath;
  final ValueChanged<String> onPicked;

  const ProfilePicturePicker({
    super.key,
    required this.pickedPath,
    required this.onPicked,
  });

  void _mockPick(BuildContext context, String source) {
    HapticFeedback.lightImpact();
    onPicked("mock://profile-photo/$source");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(OnboardingStrings.mockPhotoSelectedMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhoto = pickedPath != null;
    return Column(
      children: [
        Text(OnboardingStrings.profilePhotoLabel, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          label: hasPhoto
              ? "ရွေးချယ်ထားသော ဓာတ်ပုံ (Demo)"
              : "ဓာတ်ပုံ မရွေးချယ်ရသေးပါ",
          image: true,
          child: CircleAvatar(
            radius: AppSizes.avatarLarge / 2,
            backgroundColor: AppColors.purple100,
            child: Icon(
              hasPhoto ? Icons.check_circle : Icons.person_outline,
              size: 48,
              color: AppColors.purple700,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _PickButton(
                icon: Icons.photo_camera_outlined,
                label: OnboardingStrings.cameraButton,
                onTap: () => _mockPick(context, "camera"),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _PickButton(
                icon: Icons.folder_open_outlined,
                label: OnboardingStrings.chooseFileButton,
                onTap: () => _mockPick(context, "gallery"),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.md);
    return Semantics(
      label: label,
      button: true,
      child: Material(
        color: AppColors.blue100,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            height: 56,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.purple700, size: AppSizes.iconMd),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.purple700, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
