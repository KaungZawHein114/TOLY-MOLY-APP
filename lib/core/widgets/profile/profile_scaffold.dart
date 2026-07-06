import 'package:flutter/material.dart';

import '../../constants/profile_strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../onboarding/staggered_entrance.dart';

/// Shared visual shell for both profile screens, echoing the onboarding
/// language (branded purple gradient header with a rounded white panel
/// overlapping it). The header holds the editable avatar, name, role and a
/// trust badge; screens supply the scrolling [sections] only — never their own
/// chrome — so the Client and Tasker screens stay visually identical.
class ProfileScaffold extends StatelessWidget {
  final String name;
  final String roleLabel;

  /// Trust badge pill rendered under the name (verification state).
  final Widget badge;
  final String? profilePicturePath;

  /// Mock "change photo" action (dummy in Phase 1 — never uploaded/persisted).
  final VoidCallback onEditPhoto;

  /// The ordered cards rendered in the white scroll panel.
  final List<Widget> sections;

  const ProfileScaffold({
    super.key,
    required this.name,
    required this.roleLabel,
    required this.badge,
    required this.profilePicturePath,
    required this.onEditPhoto,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.purple900,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(gradient: AppColors.purpleGradient),
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
              child: Column(
                children: [
                  _EditableAvatar(
                    picked: profilePicturePath != null,
                    onEditPhoto: onEditPhoto,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(color: AppColors.onBrand, fontSize: 24),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    roleLabel,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.onBrandMuted),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  badge,
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.lightSurface,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl,
                      AppSpacing.xl, AppSpacing.xl, AppSpacing.xxl),
                  children: [
                    StaggeredEntrance(children: sections),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// White circular avatar with a small camera badge for the mock photo edit.
class _EditableAvatar extends StatelessWidget {
  final bool picked;
  final VoidCallback onEditPhoto;
  const _EditableAvatar({required this.picked, required this.onEditPhoto});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: picked
          ? "ရွေးချယ်ထားသော ဓာတ်ပုံ (Demo)"
          : ProfileStrings.editPhoto,
      button: true,
      image: true,
      child: Stack(
        children: [
          Container(
            width: AppSizes.avatarLarge,
            height: AppSizes.avatarLarge,
            decoration: const BoxDecoration(
              color: AppColors.onBrand,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              picked ? Icons.check_circle : Icons.person,
              size: 52,
              color: AppColors.purple700,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: AppColors.purple500,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onEditPhoto,
                child: const SizedBox(
                  width: 32,
                  height: 32,
                  child: Icon(Icons.photo_camera_outlined,
                      color: AppColors.onBrand, size: AppSizes.iconSm),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
