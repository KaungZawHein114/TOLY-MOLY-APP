import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_strings.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/audio/auth_audio_controller.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: TolyMolyApp()));

  // Keep startup cheap: render the first frame first, then do best-effort
  // Firebase/audio warmup in the background so a slow plugin init cannot block
  // the app launch on Android.
  unawaited(Future<void>(() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {
      // No Firebase config present — continue in offline/mock mode.
    }
    // Best-effort: failures are swallowed inside the controller.
    await AuthAudioController.instance.preload();
  }));
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
