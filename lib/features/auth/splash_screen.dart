import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Splash screen. Renders the full branded screen instantly, then a plain
/// (non-async) Timer auto-navigates to Role Selection after 1.5s.
/// There is NO loading spinner and NO async work — the screen is fully drawn
/// on the first frame.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Plain Timer (not async, not Future.delayed): just fires navigation.
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) context.go(Routes.role);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.tealGradient),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.onBrand,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text("🧰", style: TextStyle(fontSize: 56)),
            ),
            const SizedBox(height: AppSpacing.xxl + 4),
            Text(
              AppStrings.appName,
              style: AppTextStyles.displayLarge.copyWith(color: AppColors.onBrand),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.huge),
              child: Text(
                AppStrings.tagline,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onBrandMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.huge),
            // Tap anywhere to skip the wait — instant navigation, no blocking.
            TextButton(
              onPressed: () => context.go(Routes.role),
              child: Text(
                "Tap to continue",
                style: AppTextStyles.label.copyWith(color: AppColors.onBrandMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
