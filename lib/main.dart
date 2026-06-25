import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_strings.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  // No async setup, no plugins to await — render the first frame immediately.
  runApp(const ProviderScope(child: TolyMolyApp()));
}

class TolyMolyApp extends StatelessWidget {
  const TolyMolyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.light,
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}
