import 'dart:io';

import 'package:flutter/foundation.dart';

import 'local_config.dart.example';

/// Resolves the correct backend base URL for the current runtime environment.
///
/// - Web / iOS simulator / desktop → localhost (same machine as the server)
/// - Android emulator → 10.0.2.2 (Android's built-in alias for the host)
/// - Physical Android device → [physicalDeviceUrl] from local_config.dart
///   (the only value that varies per developer — edit that file once)
String get apiBaseUrl {
  if (kIsWeb) return 'http://127.0.0.1:8000';
  if (Platform.isIOS || Platform.isMacOS) return 'http://127.0.0.1:8000';
  if (Platform.isWindows || Platform.isLinux) return 'http://127.0.0.1:8000';
  if (Platform.isAndroid) {
    // Treat the configured value as the source of truth on Android.
    // If it still points at the emulator alias, use that; otherwise use the
    // LAN IP entered in local_config.dart for a physical phone.
    if (physicalDeviceUrl.contains('10.0.2.2') ||
        physicalDeviceUrl.contains('127.0.0.1') ||
        physicalDeviceUrl.contains('localhost')) {
      return 'http://10.0.2.2:8000';
    }
    return physicalDeviceUrl;
  }
  return physicalDeviceUrl;
}
