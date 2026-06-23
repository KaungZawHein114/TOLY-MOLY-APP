/// Static Burmese-first copy for the Task Posting Flow (Screen 1 through the
/// review/publish success modal). Kept alongside [OnboardingStrings] but in
/// its own file since this flow owns a large amount of copy, mirroring that
/// file's convention.
class TaskPostingStrings {
  TaskPostingStrings._();

  // ── Shared ───────────────────────────────────────────────────────────────
  static const String previousButton = "နောက်သို့";
  static const String continueButton = "ဆက်လက်လုပ်ဆောင်မည်";
  static const String discardDraftTitle = "အလုပ်တင်ခြင်းကို ရပ်ဆိုင်းမလား";
  static const String discardDraftMessage =
      "ဖြည့်ထားသော အချက်အလက်များ ပျောက်ဆုံးသွားနိုင်ပါသည်။";
  static const String discardDraftConfirm = "ရပ်ဆိုင်းမည်";
  static const String discardDraftCancel = "ဆက်လုပ်မည်";

  // ── Screen 1: AI Task Assistant + Category Selection ────────────────────
  static const String categoryTitle = "ဘာအကူအညီ လိုအပ်ပါသလဲ";
  static const String aiInputHint = "ဥပမာ - ရေယိုနေတယ်";
  static const String aiSuggestionPrefix = "AI က ထောက်ပြသည်: ";
  static const String aiSuggestionConfirm = "အတည်ပြုမည်";
  static const String orDivider = "သို့မဟုတ်";
  static const String manualCategoryPrompt = "ဝန်ဆောင်မှု အမျိုးအစား ရွေးချယ်ပါ";
  static const String categoryRequiredError = "ဝန်ဆောင်မှု အမျိုးအစား ရွေးချယ်ပေးပါနော်";

  // ── Screen 2: Task Type & Location ───────────────────────────────────────
  static const String typeLocationTitle = "အလုပ်နေရာ ရွေးချယ်ပါ";
  static const String taskTypeOnSiteLabel = "နေရာသို့ လာရမည်";
  static const String taskTypeRemoteLabel = "အဝေးမှ လုပ်နိုင်သည်";
  static const String townshipLabel = "မြို့နယ်";
  static const String townshipPlaceholder = "မြို့နယ် ထည့်ပါ";
  static const String addressLabel = "လိပ်စာ";
  static const String addressPlaceholder = "အိမ်အမှတ်၊ လမ်း ထည့်ပါ";
  static const String mapPickerButton = "မြေပုံမှ ရွေးမည်";
  static const String mapNotSupported = "ဒီ Demo တွင် မြေပုံ မရှိသေးပါ";
  static const String taskTypeRequiredError = "အလုပ်နေရာ အမျိုးအစား ရွေးချယ်ပေးပါနော်";
  static const String locationRequiredError = "မြို့နယ်နှင့် လိပ်စာ ဖြည့်ပေးပါနော်";

  // ── Screen 3: Date & Time ─────────────────────────────────────────────────
  static const String dateTimeTitle = "ဘယ်အချိန် လိုအပ်ပါသလဲ";
  static const String pickDateButton = "ရက်စွဲ ရွေးမည်";
  static const String customTimeButton = "အချိန်ရွေးမည်";
  static const String dateRequiredError = "ရက်စွဲ ရွေးချယ်ပေးပါနော်";
  static const String timeRequiredError = "အချိန် ရွေးချယ်ပေးပါနော်";
  static const String urgentExplanation =
      "အရေးပေါ်လုပ်ငန်းအတွက် ငွေပိုကောက်ခံပါမည်။ အလုပ်သမားများ ပိုမြင်နိုင်ပြီး ဦးစားပေး ရရှိပါမည်။";

  // ── Screen 4: Workers Needed + Trust Level + Urgency ─────────────────────
  static const String workersTierTitle = "အလုပ်သမား လိုအပ်ချက်";
  static const String workersNeededLabel = "လိုအပ်သော အလုပ်သမား အရေအတွက်";
  static const String workerTierSectionTitle = "အလုပ်သမား အဆင့် ရွေးချယ်ပါ";
  static const String workerTierBasicLabel = "အခြေခံ အလုပ်သမား";
  static const String workerTierBasicDescription = "နေ့စဉ် အလုပ်များ";
  static const String workerTierTrustedLabel = "ယုံကြည်ရသော အလုပ်သမား";
  static const String workerTierTrustedDescription = "အိမ်တွင်း အလုပ်များ";
  static const String workerTierExpertLabel = "ကျွမ်းကျင် အဆင့်မြင့် အလုပ်သမား";
  static const String workerTierExpertDescription = "နည်းပညာ ကျွမ်းကျင်မှု လိုအပ်သော အလုပ်များ";
  static const String urgentToggleLabel = "အရေးပေါ် အလုပ်";
  static const String workerTierRequiredError = "အလုပ်သမား အဆင့် ရွေးချယ်ပေးပါနော်";

  // ── Screen 5: Task Description ───────────────────────────────────────────
  static const String descriptionTitle = "အလုပ်အကြောင်း ဖော်ပြပါ";
  static const String descriptionPlaceholder = "ဥပမာ - ရေယိုနေတယ်";
  static const String aiWriteButton = "AI က ရေးပေးမည်";
  static const String descriptionRequiredError = "အလုပ်အကြောင်း ဖော်ပြပေးပါနော်";

  // ── Screen 6: Budget Suggestion ───────────────────────────────────────────
  static const String budgetTitle = "ခန့်မှန်း ဈေးနှုန်း";
  static const String budgetAnalysisTitle = "AI ခွဲခြမ်းစစ်ဆေးမှု";
  static const String budgetSuggestedLabel = "အကြံပြု ဈေးနှုန်း";
  static const String budgetCurrency = "ကျပ်";
  static const String budgetMarketInsightPrefix = "တူညီသော အလုပ်များ၏ ";
  static const String budgetMarketInsightSuffix =
      "% ကို ဤဈေးနှုန်းဖြင့် ပြီးစီးခဲ့ပါသည်";
  static const String budgetAutoSetNote =
      "ဈေးနှုန်းကို Supply/Demand အလိုက် အလိုအလျောက် သတ်မှတ်ပေးပါသည်။ "
      "နောက်ပိုင်းတွင် Chat ဖြင့် အလုပ်သမားနှင့် ညှိနှိုင်းနိုင်ပါသည်။";

  // ── Screen 7: Review & Publish ───────────────────────────────────────────
  static const String reviewTitle = "အချက်အလက်များ စစ်ဆေးပါ";
  static const String reviewCategoryLabel = "အလုပ်အမျိုးအစား";
  static const String reviewLocationLabel = "နေရာ";
  static const String reviewDateLabel = "ရက်စွဲ";
  static const String reviewTimeLabel = "အချိန်";
  static const String reviewWorkersLabel = "အလုပ်သမား အရေအတွက်";
  static const String reviewTierLabel = "အလုပ်သမား အဆင့်";
  static const String reviewBudgetLabel = "ဈေးနှုန်း";
  static const String reviewDescriptionLabel = "အသေးစိတ်ဖော်ပြချက်";
  static const String editLink = "ပြင်မည်";
  static const String publishButton = "အလုပ်တင်မည်";
  static const String remoteLocationValue = "အဝေးမှ လုပ်ဆောင်မည်";

  // ── Success modal ─────────────────────────────────────────────────────────
  static const String successTitle = "အလုပ်တင်ပြီးပါပြီ";
  static const String successMessage =
      "သင့်အတွက် သင့်တော်သော အလုပ်သမားများကို ရှာဖွေပေးနေပါသည်";
  static const String successGoToActivity = "လုပ်ဆောင်ချက်များ သို့ သွားမည်";
  static const String successGoHome = "ပင်မသို့ ပြန်မည်";
}
