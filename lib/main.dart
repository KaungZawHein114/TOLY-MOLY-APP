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
  // The AI Task Scoper (Task Posting only) proxies OpenAI through Firebase.
  // This init is best-effort and guarded: if Firebase isn't configured yet,
  // the app still runs fully offline and every AI call falls back to the
  // synchronous mock.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {
    // No Firebase config present — continue in offline/mock mode.
  }
  // Warm the auth voice clips so the first speaker tap plays instantly.
  // Best-effort: failures are swallowed inside the controller.
  unawaited(AuthAudioController.instance.preload());
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
