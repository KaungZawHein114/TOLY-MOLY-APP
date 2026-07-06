import 'package:flutter/widgets.dart';

import 'auth_audio_controller.dart';

/// Stops any playing auth clip the instant the user navigates — whether that's
/// moving deeper into the flow (push), stepping back (pop), or a stack reset
/// (replace/remove). Wired into the router's shell navigator so a clip never
/// keeps playing over a screen the user has already left.
///
/// It only ever touches [AuthAudioController], which is idle outside the auth
/// flow, so non-auth navigation triggers a cheap no-op and the rest of the
/// app's TTS is completely unaffected.
class AuthAudioNavObserver extends NavigatorObserver {
  void _stop() => AuthAudioController.instance.stop();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _stop();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _stop();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => _stop();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => _stop();
}
