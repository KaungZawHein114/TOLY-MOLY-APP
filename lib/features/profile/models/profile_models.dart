/// Mirrors `GET /api/profile/`'s merged shape (profile fields + the
/// user-row-level phone_number/status — see backend/apps/profiles/views.py).
/// Shared by both the Client and Tasker profile screens — the backend
/// returns the same shape for either role (see `_profile_and_serializer_class`
/// in apps/profiles/views.py).
class UserProfileData {
  final String name;
  final String gender;
  final int age;
  final String phoneNumber;
  final String accountStatus; // UNVERIFIED | PENDING_VERIFICATION | VERIFIED | SUSPENDED

  const UserProfileData({
    required this.name,
    required this.gender,
    required this.age,
    required this.phoneNumber,
    required this.accountStatus,
  });

  factory UserProfileData.fromJson(Map<String, dynamic> json) => UserProfileData(
        name: json["name"] as String,
        gender: json["gender"] as String,
        age: json["age"] as int,
        phoneNumber: json["phone_number"] as String,
        accountStatus: json["status"] as String,
      );

  UserProfileData copyWith({
    String? name,
    String? gender,
    int? age,
    String? phoneNumber,
    String? accountStatus,
  }) =>
      UserProfileData(
        name: name ?? this.name,
        gender: gender ?? this.gender,
        age: age ?? this.age,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        accountStatus: accountStatus ?? this.accountStatus,
      );
}

/// Mirrors one row from `/api/tasker/skills` (apps.taskers.models.Skill).
class TaskerSkillEntry {
  final int id;
  final String skillName;
  final int experienceYears;

  const TaskerSkillEntry({
    required this.id,
    required this.skillName,
    required this.experienceYears,
  });

  factory TaskerSkillEntry.fromJson(Map<String, dynamic> json) => TaskerSkillEntry(
        id: json["id"] as int,
        skillName: json["skill_name"] as String,
        experienceYears: json["experience_years"] as int,
      );
}
