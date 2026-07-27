import 'dart:io';

import 'package:flutter/foundation.dart';

import 'local_config.dart';

const String _androidEmulatorUrl = 'http://10.0.2.2:8000';

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
    // Keep Android deterministic: if local_config.dart is still at the template
    // value, treat it as "emulator mode"; otherwise honor the developer's LAN
    // URL for both USB-debugged phones and Wi-Fi phones.
    return physicalDeviceUrl == _androidEmulatorUrl
        ? _androidEmulatorUrl
        : physicalDeviceUrl;
  }
  return physicalDeviceUrl;
}
