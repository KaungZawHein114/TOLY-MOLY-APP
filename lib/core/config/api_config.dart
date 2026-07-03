import 'package:flutter/foundation.dart';

/// Central API base URL configuration.
///
/// Priority:
///   1. --dart-define=API_BASE_URL=http://... (overrides everything)
///   2. Platform auto-detection
///   3. Fallback: http://localhost:8000
///
/// Usage examples:
///   flutter run                                              # auto-detect
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000  # real phone
///
/// Platform defaults (used when API_BASE_URL is not set):
///   Web (Chrome / Edge)    → http://localhost:8000
///   Android emulator       → http://10.0.2.2:8000  (special loopback alias)
///   Real Android device    → http://192.168.8.102:8000  (dev PC LAN IP — update when Wi-Fi changes)
///   iOS simulator          → http://localhost:8000
const String _dartDefineUrl = String.fromEnvironment('API_BASE_URL');

/// The LAN IP of the development PC — used for real Android/iOS devices.
/// Run `ipconfig` (Windows) or `ifconfig` (Mac/Linux) to get your current IP.
const String _lanIp = '192.168.8.102';

String get apiBaseUrl {
  // 1. Honour explicit override from --dart-define.
  if (_dartDefineUrl.isNotEmpty) return _dartDefineUrl;

  // 2. Web (Chrome, Edge, any browser) — same origin as the dev server.
  if (kIsWeb) return 'http://localhost:8000';

  // 3. Native platform detection.
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      // 10.0.2.2 is the Android emulator's alias for the host machine.
      // On a real device the host is reached via LAN IP.
      //
      // To distinguish emulator vs real device without dart:io we rely on the
      // --dart-define override above (pass API_BASE_URL when running on a
      // real phone). The emulator default is the safe fallback here.
      return 'http://10.0.2.2:8000';
    case TargetPlatform.iOS:
      return 'http://localhost:8000';
    default:
      // macOS, Windows, Linux desktop — loopback works.
      return 'http://localhost:8000';
  }
}

/// Convenience: the LAN IP for real-device runs.
///
/// Use this when running on a physical phone:
///   flutter run --dart-define=API_BASE_URL=http://$_lanIp:8000
// ignore: unused_element
String get lanApiBaseUrl => 'http://$_lanIp:8000';
