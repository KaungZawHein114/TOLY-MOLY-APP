import '../models/profile_models.dart';
import 'profile_api.dart';
import 'profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileApi _api;

  ProfileRepositoryImpl({ProfileApi? api}) : _api = api ?? ProfileApi();

  @override
  Future<UserProfileData> getProfile() async {
    final json = await _api.getProfile();
    return UserProfileData.fromJson(json);
  }

  @override
  Future<UserProfileData> updateAgeGender(
    UserProfileData current, {
    int? age,
    String? gender,
  }) async {
    final json = await _api.updateProfile(age: age, gender: gender);
    return current.copyWith(
      age: json["age"] as int?,
      gender: json["gender"] as String?,
    );
  }

  @override
  Future<void> updatePhone(String phoneNumber) {
    return _api.updatePhone(phoneNumber);
  }
}
