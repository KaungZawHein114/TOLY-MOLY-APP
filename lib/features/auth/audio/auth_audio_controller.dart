import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'auth_audio_map.dart';

/// Owns the ONE [AudioPlayer] used to play pre-recorded auth clips, and
/// guarantees only a single clip is ever audible at a time.
///
/// A process-wide singleton ([instance]) so that every speaker button on every
/// auth screen shares the same playback state: tapping a second button stops
/// the first, and a [NavigatorObserver] (see `auth_audio_nav_observer.dart`)
/// can stop playback the instant the user leaves an auth screen.
///
/// It is a [ChangeNotifier] so speaker buttons can rebuild their play/stop
/// icon in lock-step with what is actually playing.
class AuthAudioController extends ChangeNotifier {
  AuthAudioController._();

  /// Shared instance used by all auth speaker buttons and the nav observer.
  static final AuthAudioController instance = AuthAudioController._();

  // A dedicated player with an empty-prefix cache, so `AssetSource('recordings
  // /auth/foo.m4a')` resolves to that exact bundled asset instead of the
  // audioplayers default of `assets/recordings/auth/foo.m4a`.
  final AudioPlayer _player = AudioPlayer()..audioCache = AudioCache(prefix: '');

  bool _wired = false;
  String? _playingKey;

  /// The key currently playing, or `null` when nothing is playing.
  String? get playingKey => _playingKey;

  /// Whether [key] is the clip currently playing (drives the button icon).
  bool isPlaying(String? key) => key != null && _playingKey == key;

  void _wireOnce() {
    if (_wired) return;
    _wired = true;
    // Reset to idle when a clip finishes on its own.
    _player.onPlayerComplete.listen((_) {
      _playingKey = null;
      notifyListeners();
    });
  }

  /// Tap handler for a speaker button: if this key is already playing, stop it
  /// (tap-again-to-stop); otherwise start it (stopping any other clip first).
  Future<void> toggle(String key) async {
    if (isPlaying(key)) {
      await stop();
    } else {
      await play(key);
    }
  }

  /// Plays the clip mapped to [key]. If there is no recording for the key, this
  /// is a silent no-op (never a crash, never a TTS fallback). Any playback
  /// error is swallowed and the button falls back to its idle state.
  Future<void> play(String key) async {
    final path = authAudioPath(key);
    if (path == null) return; // no recording for this key → stay silent

    _wireOnce();
    // Enforce "only one at a time": stop whatever was playing before starting.
    try {
      await _player.stop();
    } catch (_) {/* ignore */}

    _playingKey = key;
    notifyListeners();

    try {
      await _player.play(AssetSource(path));
    } catch (_) {
      // Missing/corrupt asset or unsupported codec on this platform: reset to
      // a silent idle state instead of surfacing an error.
      if (_playingKey == key) {
        _playingKey = null;
        notifyListeners();
      }
    }
  }

  /// Stops any current playback and returns the UI to idle. Safe to call when
  /// nothing is playing (cheap no-op).
  Future<void> stop() async {
    if (_playingKey == null) return;
    _playingKey = null;
    notifyListeners();
    try {
      await _player.stop();
    } catch (_) {/* ignore */}
  }

  /// Best-effort preload of every clip into the audio cache for smoother first
  /// playback. Safe to call from app startup; failures are ignored.
  Future<void> preload() async {
    _wireOnce();
    try {
      await _player.audioCache.loadAll(authAudioMap.values.toList());
    } catch (_) {/* preloading is best-effort only */}
  }
}
