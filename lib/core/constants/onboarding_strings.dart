/// Static Burmese-first copy for the onboarding flow (Welcome through the
/// client/tasker completion screens). Kept alongside [AppStrings] but in its
/// own file since the onboarding flow owns a large amount of copy.
class OnboardingStrings {
  OnboardingStrings._();

  // ── Welcome ────────────────────────────────────────────────────────────
  static const String welcomeHeadline = "ယုံကြည်စိတ်ချရသော အိမ်အကူဝန်ဆောင်မှု";
  static const String welcomeMessage =
      "မင်္ဂလာပါ။ Pho Wa Yoke က အကူအညီပေးပါမယ်နော်။ စတင်ကြရအောင်။";
  // TODO(native-speaker-review): drafted warmer copy for the redesign slice
  // in docs/superpowers/specs/2026-06-22-onboarding-redesign-design.md §7.
  // Needs a Burmese speaker to review tone/wording before this replaces
  // welcomeMessage above.
  static const String welcomeMessageV2 =
      "မင်္ဂလာပါနော်! ကျွန်တော် ဖိုးဝရုပ် ပါ။ သင့်အတွက် အကောင်းဆုံး လုပ်သားတွေ / အလုပ်တွေ ကိုရှာပေးမှာပါ — လက်ဆွဲပြီး လမ်းညွှန်ပေးမယ်နော်။";
  static const String getStarted = "စတင်မည်";

  // ── Create account ───────────────────────────────────────────────────
  static const String createAccountTab = "အကောင့်ဖွင့်မည်";
  static const String loginTab = "အကောင့်ဝင်မည်";
  static const String chooseRolePrompt = "သင်၏ ရည်ရွယ်ချက်ကို ရွေးချယ်ပါ။";
  // TODO(native-speaker-review): see welcomeMessageV2 above for context.
  static const String chooseRolePromptV2 =
      "ဘယ်တွေလိုအပ်လဲဆိုတာ ပြောပြပါ။ အကူအညီ လိုချင်လား၊ ဝန်ဆောင်မှု ပေးချင်လား။";
  static const String roleClientLabel = "အကူအညီ ငှားမည်";
  static const String roleClientSublabel = "အလုပ်သမား ရှာဖွေရန်";
  static const String roleTaskerLabel = "အလုပ် လုပ်မည်";
  static const String roleTaskerSublabel = "ဝန်ဆောင်မှု ပေးရန်";
  static const String nameLabel = "အမည်";
  static const String namePlaceholder = "အမည်အပြည့်အစုံ";
  static const String phoneLabel = "ဖုန်းနံပါတ်";
  static const String passwordLabel = "စကားဝှက်";
  static const String passwordPlaceholder = "••••••••";
  static const String showPasswordLabel = "စကားဝှက် ပြရန်";
  static const String hidePasswordLabel = "စကားဝှက် ဖျောက်ရန်";
  static const String continueButton = "ဆက်လက်လုပ်ဆောင်မည်";
  static const String submittingLabel = "ခဏစောင့်ပါ...";
  static const String orDivider = "သို့မဟုတ်";
  static const String googleSignup = "Google ဖြင့် ဝင်ရောက်မည်";
  static const String loginNotSupported =
      "Demo အတွက် အကောင့်ဝင်ရောက်ခြင်းကို ပံ့ပိုးမထားပါသေးပါ။ အကောင့်အသစ်ဖွင့်ပါ။";
  // Dev shortcut login (Phase 1 has no auth): fill the two fields, then pick a
  // role to jump straight into that shell.
  // TODO(native-speaker-review): confirm tone/wording with a Burmese speaker.
  static const String loginFieldsRequiredError =
      "ဖုန်းနံပါတ်နှင့် စကားဝှက် ဖြည့်ပေးပါနော်";
  static const String loginButton = "အကောင့်ဝင်မည်";
  static const String googleNotSupported =
      "Demo အတွက် Google ဖြင့်ဝင်ရောက်ခြင်းကို ပံ့ပိုးမထားပါသေးပါ။";
  static const String nameRequiredError = "အမည် ထည့်ပေးပါနော်";
  static const String phoneRequiredError = "ဖုန်းနံပါတ် ထည့်ပေးပါနော်";
  static const String passwordRequiredError = "စကားဝှက် ထည့်ပေးပါနော်";
  static const String roleRequiredError = "ရည်ရွယ်ချက်ကို ရွေးချယ်ပေးပါနော်";
  static const String signupInstructions =
      "သင့်အကောင့်အသစ် ဖွင့်ရန် ရည်ရွယ်ချက်ကို ရွေးချယ်ပေးပါ။";
  static const String loginInstructions =
      "အကောင့်ဝင်ရန် ဖုန်းနံပါတ်နှင့် စကားဝှက် ဖြည့်ပေးပါ။";

  // ── Basic info (signup step 2) ───────────────────────────────────────
  static const String basicInfoTitle = "အကောင့်အချက်အလက်";
  static const String basicInfoMascotMessage =
      "အမည်၊ ဖုန်းနံပါတ်နှင့် စကားဝှက် ဖြည့်ပေးပါနော်။";
  // TODO(native-speaker-review): see welcomeMessageV2 above for context.
  static const String basicInfoMascotMessageV2 =
      "အမည်လေးနှင့် ဆက်သွယ်ရန် အချက်အလက်လေး ပေးလိုက်ရင် ပြီးပါပြီနော်။";
  static const String basicInfoInstructions =
      "အမည်၊ ဖုန်းနံပါတ်နှင့် စကားဝှက် ဖြည့်ပေးပါ။";

  // ── Personal information (shared shape, both flows) ─────────────────
  static const String personalInfoTitle = "ကိုယ်ရေးအချက်အလက်";
  static const String genderLabel = "လိင်";
  static const String ageLabel = "အသက်";
  static const String agePlaceholder = "အသက် (၁၈ - ၈၀)";
  static const String ageRangeError = "အသက်ကို ၁၈ နှင့် ၈၀ ကြားတွင် ထည့်ပေးပါ";
  static const String clientPersonalMascotMessage =
      "ဒီအချက်အလက်လေး ဖြည့်ပေးပါနော်";
  static const String taskerPersonalMascotMessage =
      "သင့်အမည်ကို ပြောလိုက်ပါနော်";
  static const String speakButton = "ပြောမည်";

  // ── Phone verification (shared widget) ───────────────────────────────
  static const String phoneVerificationTitle = "ဖုန်းနံပါတ် အတည်ပြုခြင်း";
  static const String sendOtpButton = "OTP ပို့မည်";
  static const String verifyOtpButton = "အတည်ပြုမည်";
  static const String otpLabel = "OTP ကုဒ်";
  static const String otpSentMessage = "OTP ကို ပို့ပြီးပါပြီ (Demo OTP: 12345)";
  static const String otpInvalidError = "OTP ကုဒ် မှားနေပါသည်";
  static const String otpVerifiedMessage = "ဖုန်းနံပါတ် အတည်ပြုပြီးပါပြီ";
  static const String demoOtp = "12345";

  // ── Skills (tasker step 3) ───────────────────────────────────────────
  static const String skillsTitle = "ကျွမ်းကျင်မှုများ";
  static const String skillsMascotMessage = "သင်တတ်ကျွမ်းတဲ့ အလုပ်ကို ပြောလိုက်ပါနော်";
  static const String experienceQuestion = "အတွေ့အကြုံ ဘယ်လောက်ရှိပါသလဲ";
  static const String experienceDropdownPlaceholder = "ရွေးပါ";
  static const String customSkillLabel = "အခြား ကျွမ်းကျင်မှု ထည့်မည်";
  static const String skillsRequiredError = "ကျွမ်းကျင်မှု အနည်းဆုံး တစ်ခု ရွေးပေးပါနော်";

  static const String readAloudButton = "ဖတ်ပြမည်";

  // ── Rules (both flows) ────────────────────────────────────────────────
  static const String rulesTitle = "စည်းမျဉ်းစည်းကမ်းများ";
  static const String rulesAgreeClientLabel =
      "စည်းမျဉ်းစည်းကမ်းများကို ဖတ်ရှုပြီး သဘောတူပါသည်";
  static const String rulesAgreeTaskerLabel = "စည်းမျဉ်းစည်းကမ်းများကို သဘောတူပါသည်";
  static const String rulesAgreeRequiredError =
      "ဆက်လက်ရန် စည်းမျဉ်းစည်းကမ်းများကို သဘောတူရန် လိုအပ်ပါသည်";
  static const String rulesBodyText =
      "TOLY MOLY ကို အသုံးပြုသူအားလုံးအတွက်:\n\n"
      "• မှန်ကန်သော အချက်အလက်များကိုသာ ဖြည့်သွင်းပါ။\n"
      "• သတ်မှတ်ထားသော အချိန်အတိုင်း လုပ်ငန်းများကို လေးစားပါ။\n"
      "• အခြားသုံးစွဲသူများကို ရိုသေလေးစားစွာ ဆက်ဆံပါ။\n"
      "• လုံခြုံမှုနှင့် ယုံကြည်စိတ်ချရမှုကို ဦးစားပေးပါ။\n"
      "• မမှန်ကန်သော အသုံးပြုမှုများကို တွေ့ရှိပါက အကောင့်ကို ရပ်ဆိုင်းနိုင်ပါသည်။\n\n"
      "ဆက်လက်ရန် အောက်ပါ အကွက်ကို သေချာစွာ ဖတ်ရှုပြီး သဘောတူညီကြောင်း အမှန်ခြစ်ပေးပါ။";

  // ── Welcome / completion (both flows) ─────────────────────────────────
  static const String completionTitle = "ကြိုဆိုပါသည် 🎉";
  static const String completionUnverifiedMessage =
      "လက်ရှိတွင် သင့်အကောင့်ကို အတည်ပြုထားခြင်း မရှိသေးပါ။";
  static const String completionContinuePrompt = "Profile ကို ဆက်လက်ဖြည့်သွင်းမလား";
  static const String completionOrPrompt = "သို့မဟုတ်";
  static const String completionUseNowPrompt = "ယခုချက်ချင်း စတင်အသုံးပြုမလား";
  static const String completionContinueButton = "Profile ဆက်ဖြည့်မည်";
  static const String completionUseNowButton = "ယခုအသုံးပြုမည်";

  // ── Onboarding voice mode (Slice 2, spec §4.1/§4.6) ──────────────────────
  // Pho Wa Yoke greets, shows a sample script, listens, extracts the fields,
  // and shows them PRE-FILLED for confirmation. Never submits blind; manual
  // entry stays available.
  static const String voiceFillCta = "အသံနဲ့ ဖြည့်မယ်";
  static const String voiceFillCtaSubtitle =
      "ဖိုးဝရုပ်ကို ကိုယ့်အကြောင်း ပြောပြလိုက်ရုံပါပဲ။";
  static const String voiceOnboardingTitle = "အသံဖြင့် အချက်အလက် ဖြည့်ခြင်း";
  static const String voiceOnboardingGreeting =
      "မင်္ဂလာပါ။ ကိုယ့်အကြောင်း ပြောပြပေးပါနော် — ကျွန်တော်ဖြည့်ပေးပါမယ်။";
  static const String voiceOnboardingScriptLabel = "ဒီလို ပြောနိုင်ပါတယ် —";
  static const String voiceScriptClient =
      "\"ကျွန်တော် အောင်အောင်ပါ။ အသက် ၂၅ နှစ်၊ ကျားပါ။ ဖုန်းက ၀၉၇၈၉၁၂၃၄၅၆ ပါ။\"";
  static const String voiceScriptTasker =
      "\"ကျွန်တော် အောင်အောင်ပါ။ အသက် ၂၅ နှစ်၊ ကျားပါ။ ဖုန်းက ၀၉၇၈၉၁၂၃၄၅၆ ပါ။ "
      "သန့်ရှင်းရေးနဲ့ ပိုက်ပြင်တာ လုပ်တတ်ပါတယ်။\"";
  static const String voiceListeningHint = "မိုက်ကို နှိပ်ပြီး ပြောပါ";
  static const String voiceExtracting = "အချက်အလက်တွေ ဖတ်နေပါတယ်…";
  static const String voiceReviewPrompt =
      "ကြားရတာတွေ ဒီမှာပါ။ မှန်ရင် အတည်ပြုပါ၊ မှားရင် ပြန်ပြောနိုင်ပါတယ်။";
  static const String voiceNothingHeard =
      "ကောင်းကောင်း မကြားလိုက်ပါ။ ထပ်ပြောကြည့်ပါ သို့မဟုတ် ကိုယ်တိုင် ဖြည့်ပါ။";
  static const String voiceNotGiven = "မပြောရသေးပါ";
  static const String voiceConfirmButton = "မှန်ပါတယ်၊ ဆက်သွားမည်";
  static const String voiceRetryButton = "ပြန်ပြောမည်";
  static const String voiceManualButton = "ကိုယ်တိုင် ဖြည့်မည်";
  static const String voiceFieldName = "အမည်";
  static const String voiceFieldGender = "လိင်";
  static const String voiceFieldAge = "အသက်";
  static const String voiceFieldPhone = "ဖုန်းနံပါတ်";
  static const String voiceFieldSkills = "ကျွမ်းကျင်မှုများ";
  static const String voiceAppliedMessage = "🎙️ အသံဖြင့် ဖြည့်ပြီးပါပြီ — စစ်ဆေးပြီး ဆက်သွားပါ";
  static const String voiceOfflineNote = "အော့ဖ်လိုင်း — ကြားနိုင်သမျှ ဖြည့်ထားပါသည်";

  // ── Generic ───────────────────────────────────────────────────────────
  static const String backButtonSemantic = "နောက်သို့";
  static const String continueGeneric = "ရှေ့ဆက်မည်";
  static const String mockVoiceCapturedMessage = "🎙️ အသံဖြင့် ထည့်သွင်းပြီးပါပြီ";
  static const String mockReadingAloudMessage = "🔊 ဖတ်ပြနေသည်...";
}
