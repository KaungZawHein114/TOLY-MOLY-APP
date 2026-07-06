import 'dart:io';

import 'package:flutter/foundation.dart';

import 'local_config.dart';

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
    // The Android emulator exposes the host machine on 10.0.2.2.
    // Physical devices cannot use that alias — they need the real LAN IP.
    // We distinguish the two by checking for the emulator's hostname, which
    // the OS always sets to "generic*" / "sdk_*" / "localhost".
    final host = Platform.localHostname.toLowerCase();
    final isEmulator = host.contains('generic') ||
        host.contains('sdk') ||
        host == 'localhost' ||
        host.isEmpty;
    return isEmulator ? 'http://10.0.2.2:8000' : physicalDeviceUrl;
  }
  return physicalDeviceUrl;
}
