import '../models/profile_models.dart';

/// Talks to the Django profile backend. Screens depend on this interface,
/// never on [ProfileApi] directly — same seam pattern as
/// lib/features/auth/data/auth_repository.dart.
abstract class ProfileRepository {
  Future<UserProfileData> getProfile();

  /// The PUT response only carries the fields the profile model itself owns
  /// (name/gender/age) — phone/status live on the User row — so this takes
  /// the previously-loaded [current] snapshot and returns it merged with
  /// whatever the server echoes back.
  Future<UserProfileData> updateAgeGender(
    UserProfileData current, {
    int? age,
    String? gender,
  });

  Future<void> updatePhone(String phoneNumber);
}
