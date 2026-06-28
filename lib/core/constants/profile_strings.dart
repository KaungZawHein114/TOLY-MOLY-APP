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
  // (No location/address here by design — see the Address verification step.)
  static const String publicInfoTitle = "ကိုယ်ရေးအချက်အလက်";
  static const String skillsLabel = "ကျွမ်းကျင်မှုများ";

  // ── Verification section ────────────────────────────────────────────────
  static const String verificationTitle = "အတည်ပြုမှု အခြေအနေ";
  // TODO(native-speaker-review): confirm tone/wording with a Burmese speaker.
  static const String verificationClientHint =
      "အလုပ်မတင်မီ အောက်ပါအဆင့်များ ဖြည့်စွက်ရန် လိုအပ်ပါသည်။";
  static const String verificationTaskerHint =
      "အလုပ်မလက်ခံမီ အောက်ပါအဆင့်များ ဖြည့်စွက်ရန် လိုအပ်ပါသည်။";
  static const String mockUploadedMessage = "(Demo) တင်ပြီးပါပြီ";
  // Progress text is assembled in code via [progressLabel] so the numbers can
  // be rendered in Burmese digits.
  static const String progressDoneSuffix = "ပြီးစီး";

  // ── Per-document instructions (title comes from VerificationDoc.label) ────
  // TODO(native-speaker-review): confirm tone/wording with a Burmese speaker.
  static const String descNrc =
      "မှတ်ပုံတင် ရှေ့/နောက် နှစ်ဖက်လုံး ရှင်းရှင်းလင်းလင်း ဖတ်လို့ရအောင် တင်ပေးပါ။";
  static const String descFace =
      "မျက်နှာကို အလင်းရောင်ကောင်းကောင်းနှင့် ရှင်းရှင်းလင်းလင်း မြင်ရပါစေ။";
  static const String descAddress =
      "အတည်ပြုရန် သင်၏ လက်ရှိတည်နေရာ (GPS) ကို အသုံးပြုပါ။";
  static const String descPitchingVideo =
      "မိမိကိုယ်ကို မိတ်ဆက်ပြီး ကျွမ်းကျင်မှုများကို စက္ကန့် ၃၀–၆၀ အတွင်း ရှင်းပြပါ။";

  // ── Per-document action buttons ──────────────────────────────────────────
  // TODO(native-speaker-review): confirm tone/wording with a Burmese speaker.
  static const String actionNrc = "မှတ်ပုံတင် တင်မည်"; // Upload NRC
  static const String actionFace = "ဆယ်ဖီ ရိုက်မည်"; // Take Selfie
  static const String actionAddress = "တည်နေရာ ရွေးမည်"; // Select Location
  static const String actionPitchingVideo = "ဗီဒီယို တင်မည်"; // Upload Video

  // ── Placeholder captions ─────────────────────────────────────────────────
  // TODO(native-speaker-review): confirm tone/wording with a Burmese speaker.
  static const String placeholderNrcFront = "ရှေ့ဘက်"; // front
  static const String placeholderNrcBack = "နောက်ဘက်"; // back
  static const String placeholderFace = "မျက်နှာ ပုံ"; // face preview
  static const String placeholderMap = "မြေပုံ အစမ်းကြည့်ရှုခြင်း"; // map preview
  static const String placeholderVideo = "စက္ကန့် ၃၀–၆၀"; // video length hint
  static const String placeholderCaptured = "ထည့်သွင်းပြီး (Demo)"; // captured

  // ── Gated CTAs ───────────────────────────────────────────────────────────
  static const String postTaskCta = "အလုပ်တင်မည်";
  static const String acceptTaskCta = "အလုပ်လက်ခံမည်";
  // TODO(native-speaker-review): confirm tone/wording with a Burmese speaker.
  static const String becomeTaskerTitle = "ဝန်ဆောင်မှုပေးချင်လား?";
  static const String becomeTaskerSubtitle = "အလုပ်လုပ်ပြီး ဝင်ငွေရယူနိုင်ပါတယ်";
  static const String becomeTaskerCta = "အလုပ်သမားအဖြစ် လျှောက်မည်";
  // TODO(native-speaker-review): confirm tone/wording with a Burmese speaker.
  static const String becomeClientTitle = "ဝန်ဆောင်မှု ရယူလိုပါသလား?";
  static const String becomeClientSubtitle = "အလုပ်ရှာပြီး ဝန်ဆောင်မှု တောင်းခံလိုက်ပါ";
  static const String becomeClientCta = "အလုပ်ပေးသူအဖြစ် ပြောင်းမည်";
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

  // ── Logout ───────────────────────────────────────────────────────────────
  // TODO(native-speaker-review): confirm tone/wording with a Burmese speaker.
  static const String logoutButton = "အကောင့်မှ ထွက်မည်";
  static const String logoutConfirmTitle = "ထွက်မှာ သေချာပါသလား";
  static const String logoutConfirmMessage = "သင့်အကောင့်မှ ထွက်ပါတော့မည်။";
  static const String logoutConfirmCta = "ထွက်မည်";
  static const String logoutCancel = "မလုပ်တော့ပါ";

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
