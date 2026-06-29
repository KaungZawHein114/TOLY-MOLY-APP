import '../models/auth_user.dart';
import 'auth_api.dart';
import 'auth_repository.dart';
import 'token_storage.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApi _api;
  final TokenStorage _tokens;

  AuthRepositoryImpl({AuthApi? api, TokenStorage? tokenStorage})
      : _api = api ?? AuthApi(),
        _tokens = tokenStorage ?? TokenStorage();

  @override
  Future<void> register({
    required String name,
    required String phoneNumber,
    required String password,
    required String gender,
    required int age,
    required String role,
  }) async {
    await _api.register(
      name: name,
      phoneNumber: phoneNumber,
      password: password,
      gender: gender,
      age: age,
      role: role,
    );
  }

  @override
  Future<OtpSendResult> sendOtp(String phoneNumber) async {
    final json = await _api.sendOtp(phoneNumber);
    return OtpSendResult(devCode: json["dev_otp_code"] as String?);
  }

  @override
  Future<AuthSession> verifyOtp({required String phoneNumber, required String code}) async {
    final json = await _api.verifyOtp(phoneNumber: phoneNumber, code: code);
    return _saveSessionAndReturn(json);
  }

  @override
  Future<AuthSession> login({required String phoneNumber, required String password}) async {
    final json = await _api.login(phoneNumber: phoneNumber, password: password);
    return _saveSessionAndReturn(json);
  }

  @override
  Future<void> logout() async {
    final access = await _tokens.readAccessToken();
    final refresh = await _tokens.readRefreshToken();
    if (access != null && refresh != null) {
      try {
        await _api.logout(accessToken: access, refreshToken: refresh);
      } catch (_) {
        // Best-effort server-side blacklist — still clear local tokens
        // below even if the network call failed (e.g. already expired).
      }
    }
    await _tokens.clear();
  }

  @override
  Future<AuthUser> me() async {
    final access = await _refreshedAccessToken();
    final json = await _api.me(access);
    return AuthUser.fromJson(json);
  }

  @override
  Future<bool> isLoggedIn() async {
    final access = await _tokens.readAccessToken();
    return access != null;
  }

  Future<AuthSession> _saveSessionAndReturn(Map<String, dynamic> json) async {
    await _tokens.save(
      accessToken: json["access_token"] as String,
      refreshToken: json["refresh_token"] as String,
    );
    return AuthSession(AuthUser.fromJson(Map<String, dynamic>.from(json["user"] as Map)));
  }

  /// `/me` needs a *valid* access token; this app doesn't auto-refresh on a
  /// 401 mid-flight (no interceptor), so refresh proactively before the one
  /// authenticated call this repository makes outside login/verify-otp.
  Future<String> _refreshedAccessToken() async {
    final refreshToken = await _tokens.readRefreshToken();
    if (refreshToken == null) {
      throw StateError("Not logged in — no refresh token stored.");
    }
    final json = await _api.refresh(refreshToken);
    final newAccess = json["access_token"] as String;
    await _tokens.saveAccessToken(newAccess);
    return newAccess;
  }
}
