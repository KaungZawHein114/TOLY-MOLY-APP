/// Burmese-first copy for the Client and Tasker profile screens, kept in its
/// own file (mirroring [OnboardingStrings]) since the profile flow owns a fair
/// amount of new copy. Reuse [OnboardingStrings] / [AppStrings] where a string
/// already exists rather than duplicating it here.
///
/// NOTE: strings drafted for this slice are marked with a
/// `TODO(native-speaker-review)` so a Burmese speaker can confirm tone/wording
/// before launch — same convention onboarding_strings.dart uses.
class ProfileStrings {
  ProfileStrings._();

  // ── Header / role ────────────────────────────────────────────────────────
  // TODO(native-speaker-review): confirm tone/wording with a Burmese speaker.
  static const String clientRoleLabel = "ဝန်ဆောင်မှု ရယူသူ"; // Client
  static const String taskerRoleLabel = "ဝန်ဆောင်မှု ပေးသူ"; // Tasker
  static const String editProfile = "ပြင်ဆင်မည်";
  static const String editPhoto = "ဓာတ်ပုံ ပြောင်းမည်";
  static const String editNotSupported =
      "ဤ Demo တွင် Profile ပြင်ဆင်ခြင်းကို ပံ့ပိုးမထားပါသေးပါ";

  // ── Public info section ──────────────────────────────────────────────────
  static const String publicInfoTitle = "ကိုယ်ရေးအချက်အလက်";
  static const String locationLabel = "နေထိုင်ရာ ဒေသ";
  static const String skillsLabel = "ကျွမ်းကျင်မှုများ";

  // ── Verification section ────────────────────────────────────────────────
  static const String verificationTitle = "အတည်ပြုမှု အခြေအနေ";
  // TODO(native-speaker-review): confirm tone/wording with a Burmese speaker.
  static const String verificationClientHint =
      "အလုပ်မတင်မီ အောက်ပါအဆင့်များ ဖြည့်စွက်ရန် လိုအပ်ပါသည်။";
  static const String verificationTaskerHint =
      "အလုပ်မလက်ခံမီ အောက်ပါအဆင့်များ ဖြည့်စွက်ရန် လိုအပ်ပါသည်။";
  static const String uploadCta = "တင်မည်";
  static const String uploadedLabel = "ပြီးပြီ";
  static const String mockUploadedMessage = "(Demo) တင်ပြီးပါပြီ";
  // Progress text is assembled in code via [progressLabel] so the numbers can
  // be rendered in Burmese digits.
  static const String progressDoneSuffix = "ပြီးစီး";

  // ── Gated CTAs ───────────────────────────────────────────────────────────
  static const String postTaskCta = "အလုပ်တင်မည်";
  static const String acceptTaskCta = "အလုပ်လက်ခံမည်";
  // TODO(native-speaker-review): confirm tone/wording with a Burmese speaker.
  static const String postTaskLockedHint =
      "အတည်ပြုပြီးမှ အလုပ်တင်နိုင်ပါမည်";
  static const String acceptTaskLockedHint =
      "အတည်ပြုပြီးမှ အလုပ်လက်ခံနိုင်ပါမည်";

  // ── Stats section ────────────────────────────────────────────────────────
  static const String statsTitle = "စာရင်းအချက်အလက်";
  static const String statTasksPosted = "တင်ထားသော အလုပ်";
  static const String statTasksCompleted = "ပြီးစီးအလုပ်";
  static const String statRating = "အဆင့်သတ်မှတ်ချက်";
  static const String statCompletionRate = "ပြီးမြောက်နှုန်း";
  static const String statResponseTime = "တုံ့ပြန်ချိန်";
  static const String ratingNotAvailable = "မရှိသေး"; // N/A

  // ── Availability section (tasker) ────────────────────────────────────────
  static const String availabilityTitle = "ရရှိနိုင်သည့်အချိန်";
  static const String availabilityWeekdays = "အလုပ်ရက်များ"; // Mon–Fri
  static const String availabilityWeekends = "စနေ၊ တနင်္ဂနွေ"; // weekends

  // ── Mascot guidance (Pho Wa Yoke) ────────────────────────────────────────
  // TODO(native-speaker-review): confirm tone/wording with a Burmese speaker.
  static const String mascotClientUnverified =
      "အကောင့်အတည်ပြုပြီးမှ အလုပ်တင်လို့ရပါမယ်နော်။ အဆင့်လေးတွေ ဖြည့်လိုက်ရအောင်။";
  static const String mascotClientVerified =
      "အားလုံး ပြည့်စုံပါပြီ! ယခု အလုပ်တင်နိုင်ပါပြီနော်။";
  static const String mascotTaskerUnverified =
      "အကောင့်အတည်ပြုပြီးမှ အလုပ်လက်ခံလို့ရပါမယ်နော်။ အဆင့်လေးတွေ ဖြည့်လိုက်ရအောင်။";
  static const String mascotTaskerVerified =
      "အရမ်းကောင်းပါတယ်! သင် အလုပ်လက်ခံဖို့ အသင့်ဖြစ်ပါပြီနော်။";

  /// "{done} / {total} ပြီးစီး" with Burmese digits — pass the localizer.
  static String progressLabel(String done, String total) =>
      "$done / $total $progressDoneSuffix";
}
