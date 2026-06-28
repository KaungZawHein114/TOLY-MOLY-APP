import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../theme/app_colors.dart';

/// Bottom-right floating button that opens the in-app AI assistant.
/// Shared by the client and tasker dashboards so the two stay identical.
/// Indigo per the design system's "AI / intelligence" accent.
class ChatbotFab extends StatelessWidget {
  final VoidCallback onTap;
  const ChatbotFab({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onTap,
      backgroundColor: AppColors.indigo700,
      foregroundColor: AppColors.onBrand,
      tooltip: AppStrings.chatbotFabLabel,
      child: Semantics(
        label: AppStrings.chatbotFabLabel,
        button: true,
        child: ClipOval(
          child: Image.asset("assets/img.png", width: 40, height: 40, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
