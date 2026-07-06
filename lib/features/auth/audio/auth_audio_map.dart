/// Centralized mapping from a stable *audio key* to a pre-recorded clip in
/// `recordings/auth/`.
///
/// These clips REPLACE the device Text-To-Speech engine — but ONLY on the
/// authentication (onboarding) screens. Every other screen in the app keeps
/// using the live TTS `ReadAloudButton` unchanged. See [AuthAudioButton] and
/// [AuthAudioController] for how a speaker button consumes this map.
///
/// The recordings are `.m4a` audio files. They live at the repo root under
/// `recordings/auth/` (declared in `pubspec.yaml` under `flutter: assets:`),
/// and are loaded through an [AudioCache] configured with an empty prefix so
/// the path below resolves exactly as written (instead of the default
/// `assets/...` prefix).
///
/// To add a new clip later: drop the file in `recordings/auth/`, add one line
/// to [authAudioMap], and reference the new key from a screen. Nothing else
/// needs to change.
library;

/// Directory (relative to the app bundle root) that holds every auth clip.
const String _authAudioDir = 'recordings/auth';

/// Stable keys used by screens — avoids scattering raw file paths or magic
/// strings across the auth UI. Each maps to one entry in [authAudioMap].
class AuthAudioKeys {
  AuthAudioKeys._();

  static const String name = 'name';
  static const String phone = 'phone';
  static const String password = 'password';
  static const String age = 'age';
  static const String gender = 'gender';
  static const String experience = 'experience';
  static const String otp = 'otp';
  static const String phoneVerification = 'phone_verification';
  static const String login = 'login';
  static const String rules = 'rules';

  // Reserved auth spots that don't have a recording yet. They intentionally
  // have NO entry in [authAudioMap], so their speaker button hides itself
  // (rather than falling back to TTS). Drop a file in `recordings/auth/` and
  // add a map entry to light them up.
  static const String signup = 'signup';
  static const String customSkill = 'custom_skill';
}

/// key → asset path. The single source of truth for which recording plays for
/// a given UI text block. Keep this the ONLY place file names appear.
const Map<String, String> authAudioMap = {
  AuthAudioKeys.name: '$_authAudioDir/Name.m4a',
  AuthAudioKeys.phone: '$_authAudioDir/Ph no.m4a',
  AuthAudioKeys.password: '$_authAudioDir/Password.m4a',
  AuthAudioKeys.age: '$_authAudioDir/Age.m4a',
  AuthAudioKeys.gender: '$_authAudioDir/Gender.m4a',
  AuthAudioKeys.experience: '$_authAudioDir/Experience.m4a',
  AuthAudioKeys.otp: '$_authAudioDir/OTP message.m4a',
  AuthAudioKeys.phoneVerification: '$_authAudioDir/First step verification.m4a',
  AuthAudioKeys.login: '$_authAudioDir/Login back.m4a',
  AuthAudioKeys.rules: '$_authAudioDir/Rules confirmation.m4a',
};

/// Whether a recording exists for [key]. Screens use this to decide whether to
/// show a speaker affordance at all — a spot with no recording simply shows no
/// button (graceful, no crash) rather than falling back to TTS.
bool authAudioHasKey(String? key) => key != null && authAudioMap.containsKey(key);

/// Resolves [key] to its asset path, or `null` when there is no recording.
String? authAudioPath(String? key) => key == null ? null : authAudioMap[key];
