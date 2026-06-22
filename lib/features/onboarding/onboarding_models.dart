// ============================================================================
// ONBOARDING MODELS — plain Dart, no async, no persistence.
// Internal identifiers stay English; user-facing labels are Burmese-first.
// ============================================================================

/// How the signing-up user wants to use TOLY MOLY.
enum UserRole { client, tasker }

enum Gender { male, female, other }

extension GenderLabel on Gender {
  String get label {
    switch (this) {
      case Gender.male:
        return "ကျား";
      case Gender.female:
        return "မ";
      case Gender.other:
        return "အခြား";
    }
  }

  String get emoji {
    switch (this) {
      case Gender.male:
        return "👨";
      case Gender.female:
        return "👩";
      case Gender.other:
        return "🧑";
    }
  }
}

/// Tracks mock-only verification checklist items shown on the welcome step.
enum VerificationStatus { notStarted, inProgress, completed }

enum HearAboutSource { facebook, friend, school, community, other }

extension HearAboutSourceLabel on HearAboutSource {
  String get label {
    switch (this) {
      case HearAboutSource.facebook:
        return "Facebook";
      case HearAboutSource.friend:
        return "သူငယ်ချင်း";
      case HearAboutSource.school:
        return "ကျောင်း";
      case HearAboutSource.community:
        return "Community";
      case HearAboutSource.other:
        return "အခြား";
    }
  }

  String get emoji {
    switch (this) {
      case HearAboutSource.facebook:
        return "📘";
      case HearAboutSource.friend:
        return "🧑‍🤝‍🧑";
      case HearAboutSource.school:
        return "🏫";
      case HearAboutSource.community:
        return "🌐";
      case HearAboutSource.other:
        return "✨";
    }
  }
}

enum TaskerSkill {
  cleaning,
  electrical,
  plumbing,
  delivery,
  petCare,
  moving,
  painting,
}

extension TaskerSkillLabel on TaskerSkill {
  String get label {
    switch (this) {
      case TaskerSkill.cleaning:
        return "သန့်ရှင်းရေး";
      case TaskerSkill.electrical:
        return "လျှပ်စစ်ပြုပြင်ခြင်း";
      case TaskerSkill.plumbing:
        return "ပိုက်ပြင်ခြင်း";
      case TaskerSkill.delivery:
        return "ပို့ဆောင်ရေး";
      case TaskerSkill.petCare:
        return "အိမ်မွေးတိရစ္ဆာန် စောင့်ရှောက်မှု";
      case TaskerSkill.moving:
        return "ပစ္စည်းရွှေ့ပြောင်းခြင်း";
      case TaskerSkill.painting:
        return "ဆေးသုတ်ခြင်း";
    }
  }

  String get emoji {
    switch (this) {
      case TaskerSkill.cleaning:
        return "🧼";
      case TaskerSkill.electrical:
        return "⚡";
      case TaskerSkill.plumbing:
        return "🔧";
      case TaskerSkill.delivery:
        return "🚚";
      case TaskerSkill.petCare:
        return "🐾";
      case TaskerSkill.moving:
        return "📦";
      case TaskerSkill.painting:
        return "🎨";
    }
  }
}

enum ExperienceLevel { underOneYear, oneYear, twoYears, threeYearsPlus, fiveYearsPlus }

extension ExperienceLevelLabel on ExperienceLevel {
  String get label {
    switch (this) {
      case ExperienceLevel.underOneYear:
        return "၁ နှစ်အောက်";
      case ExperienceLevel.oneYear:
        return "၁ နှစ်";
      case ExperienceLevel.twoYears:
        return "၂ နှစ်";
      case ExperienceLevel.threeYearsPlus:
        return "၃ နှစ်အထက်";
      case ExperienceLevel.fiveYearsPlus:
        return "၅ နှစ်အထက်";
    }
  }
}

/// Converts a non-negative int to Burmese numerals, e.g. 12 -> "၁၂".
String toBurmeseDigits(int value) {
  const digits = ["၀", "၁", "၂", "၃", "၄", "၅", "၆", "၇", "၈", "၉"];
  return value.toString().split("").map((c) {
    final d = int.tryParse(c);
    return d == null ? c : digits[d];
  }).join();
}

/// A single step's position within an onboarding flow.
class OnboardingProgress {
  final int step; // 1-based
  final int totalSteps;

  const OnboardingProgress({required this.step, required this.totalSteps});

  double get percent => totalSteps == 0 ? 0 : step / totalSteps;

  String get stepLabel =>
      "အဆင့် ${toBurmeseDigits(step)} / ${toBurmeseDigits(totalSteps)}";
}

/// Mutable-by-replacement draft for the client (service-seeker) onboarding flow.
/// Riverpod StateProvider holds an instance; screens call copyWith to update it.
class ClientProfileDraft {
  final String name;
  final Gender? gender;
  final int? age;
  final String phone;
  final bool otpVerified;
  final String? profilePicturePath;
  final HearAboutSource? hearAboutSource;
  final bool rulesAgreed;

  const ClientProfileDraft({
    this.name = "",
    this.gender,
    this.age,
    this.phone = "",
    this.otpVerified = false,
    this.profilePicturePath,
    this.hearAboutSource,
    this.rulesAgreed = false,
  });

  factory ClientProfileDraft.empty() => const ClientProfileDraft();

  ClientProfileDraft copyWith({
    String? name,
    Gender? gender,
    int? age,
    String? phone,
    bool? otpVerified,
    String? profilePicturePath,
    HearAboutSource? hearAboutSource,
    bool? rulesAgreed,
  }) {
    return ClientProfileDraft(
      name: name ?? this.name,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      phone: phone ?? this.phone,
      otpVerified: otpVerified ?? this.otpVerified,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
      hearAboutSource: hearAboutSource ?? this.hearAboutSource,
      rulesAgreed: rulesAgreed ?? this.rulesAgreed,
    );
  }
}

/// Mutable-by-replacement draft for the tasker (service-provider) onboarding flow.
class TaskerProfileDraft {
  final String name;
  final Gender? gender;
  final int? age;
  final String phone;
  final bool otpVerified;
  final Set<TaskerSkill> skills;
  final ExperienceLevel? experienceLevel;
  final String customSkill;
  final String? profilePicturePath;
  final HearAboutSource? hearAboutSource;
  final bool rulesAgreed;

  const TaskerProfileDraft({
    this.name = "",
    this.gender,
    this.age,
    this.phone = "",
    this.otpVerified = false,
    this.skills = const {},
    this.experienceLevel,
    this.customSkill = "",
    this.profilePicturePath,
    this.hearAboutSource,
    this.rulesAgreed = false,
  });

  factory TaskerProfileDraft.empty() => const TaskerProfileDraft();

  TaskerProfileDraft copyWith({
    String? name,
    Gender? gender,
    int? age,
    String? phone,
    bool? otpVerified,
    Set<TaskerSkill>? skills,
    ExperienceLevel? experienceLevel,
    String? customSkill,
    String? profilePicturePath,
    HearAboutSource? hearAboutSource,
    bool? rulesAgreed,
  }) {
    return TaskerProfileDraft(
      name: name ?? this.name,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      phone: phone ?? this.phone,
      otpVerified: otpVerified ?? this.otpVerified,
      skills: skills ?? this.skills,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      customSkill: customSkill ?? this.customSkill,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
      hearAboutSource: hearAboutSource ?? this.hearAboutSource,
      rulesAgreed: rulesAgreed ?? this.rulesAgreed,
    );
  }
}
