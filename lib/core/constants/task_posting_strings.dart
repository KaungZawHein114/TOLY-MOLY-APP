/// Static Burmese-first copy for the Task Posting Flow (Screen 1 through the
/// review/publish success modal). Kept alongside [OnboardingStrings] but in
/// its own file since this flow owns a large amount of copy, mirroring that
/// file's convention.
class TaskPostingStrings {
  TaskPostingStrings._();

  // ── Shared ───────────────────────────────────────────────────────────────
  static const String previousButton = "နောက်သို့";
  static const String continueButton = "ဆက်လက်လုပ်ဆောင်မည်";
  static const String saveButton = "သိမ်းဆည်းပြီး ပြန်သွားမည်";
  static const String discardDraftTitle = "အလုပ်တင်ခြင်းကို ရပ်ဆိုင်းမလား";
  static const String discardDraftMessage =
      "ဖြည့်ထားသော အချက်အလက်များ ပျောက်ဆုံးသွားနိုင်ပါသည်။";
  static const String discardDraftConfirm = "ရပ်ဆိုင်းမည်";
  static const String discardDraftCancel = "ဆက်လုပ်မည်";
  static const String dropdownHint = "ရွေးချယ်ပါ";

  // ── Screen 1: Task Title + Category Selection ───────────────────────────
  static const String categoryTitle = "ဘာအကူအညီ လိုအပ်ပါသလဲ";
  static const String taskTitleLabel = "အလုပ် ခေါင်းစဉ်";
  static const String taskTitleHint = "ဥပမာ - ပန်ကာ တပ်ဆင်ရန်";
  static const String aiSuggestionPrefix = "AI က ထောက်ပြသည်: ";
  static const String aiSuggestionConfirm = "အတည်ပြုမည်";
  static const String orDivider = "သို့မဟုတ်";
  static const String manualCategoryPrompt = "ဝန်ဆောင်မှု အမျိုးအစား ရွေးချယ်ပါ";
  static const String categoryVoicePrompt = "အမျိုးအစားကို အသံဖြင့် ပြောပါ";
  static const String categoryRequiredError = "ဝန်ဆောင်မှု အမျိုးအစား ရွေးချယ်ပေးပါနော်";
  static const String otherCategoryLabel = "အခြား";
  static const String specifyCategoryLabel = "အမျိုးအစား ဖော်ပြပါ";
  static const String specifyCategoryHint = "ဥပမာ - အိမ်ပြောင်းရွှေ့ခြင်း";
  static const String specifyCategoryRequiredError = "အမျိုးအစားကို ဖော်ပြပေးပါနော်";

  // ── Screen 2: Task Location & Work Mode ──────────────────────────────────
  static const String typeLocationTitle = "အလုပ်နေရာ ရွေးချယ်ပါ";
  static const String taskTypeOnSiteLabel = "နေရာသို့ လာရမည်";
  static const String taskTypeRemoteLabel = "အဝေးမှ လုပ်နိုင်သည်";
  static const String townshipLabel = "မြို့နယ်";
  static const String townshipHint = "မြို့နယ် ရွေးချယ်ပါ";
  static const String addressLabel = "လိပ်စာ";
  static const String addressPlaceholder = "အိမ်အမှတ်၊ လမ်း ထည့်ပါ";
  static const String mapPickerButton = "မြေပုံမှ ရွေးမည်";
  static const String mapSheetTitle = "တည်နေရာ ရွေးချယ်နည်း";
  static const String mapUseCurrentLocation = "လက်ရှိ တည်နေရာ သုံးမည်";
  static const String mapUseCurrentLocationSub = "သင့်ဖုန်း၏ GPS ကို အသုံးပြုမည်";
  static const String mapPinDifferent = "အခြားနေရာ ရွေးမည်";
  static const String mapPinDifferentSub = "မြေပုံပေါ်တွင် နေရာ ရွေးချယ်မည်";
  static const String mapCurrentLocationFilled = "လက်ရှိ တည်နေရာကို ဖြည့်ပြီးပါပြီ";
  static const String mapNotSupported = "ဒီ Demo တွင် မြေပုံ မရှိသေးပါ";
  static const String taskTypeRequiredError = "အလုပ်နေရာ အမျိုးအစား ရွေးချယ်ပေးပါနော်";
  static const String locationRequiredError = "မြို့နယ်နှင့် လိပ်စာ ဖြည့်ပေးပါနော်";

  // Remote work-mode fields.
  static const String remoteDetailsTitle = "အဝေးမှ လုပ်ဆောင်မှု အသေးစိတ်";
  static const String remoteWorkMethodLabel = "လုပ်ဆောင်ပုံ";
  static const String remoteCompletionLabel = "ပြီးစီးပုံ";
  static const String remoteDeliverableLabel = "ရရှိလိုသည့် ရလဒ်";
  static const String remoteMethodRequiredError = "လုပ်ဆောင်ပုံ ရွေးချယ်ပေးပါနော်";
  static const String remoteFlexible = "ပြောင်းလွယ်ပြင်လွယ်";
  static const String remoteMethodLiveMeeting = "တိုက်ရိုက် တွေ့ဆုံ";
  static const String remoteMethodChat = "Chat ဖြင့်";
  static const String remoteMethodPhone = "ဖုန်းဖြင့်";
  static const String remoteMethodDocument = "စာရွက်စာတမ်း တင်သွင်း";
  static const String remoteCompletionDuringMeeting = "တွေ့ဆုံစဉ် ပြီးစီးရမည်";
  static const String remoteCompletionBeforeDeadline = "သတ်မှတ်ရက် မတိုင်မီ တင်ရမည်";
  static const String remoteDeliverableText = "စာသား";
  static const String remoteDeliverableFile = "ဖိုင် တင်သွင်း";
  static const String remoteDeliverableDesign = "ဒီဇိုင်း";
  static const String remoteDeliverableCode = "ကုဒ်";
  static const String remoteDeliverableConsultation = "အကြံဉာဏ်";
  static const String remoteDeliverableOther = "အခြား";

  // ── Screen 3: Date, Time & Urgent Task ───────────────────────────────────
  static const String dateTimeTitle = "ဘယ်အချိန် လိုအပ်ပါသလဲ";
  static const String pickDateButton = "ရက်စွဲ ရွေးမည်";
  static const String customTimeButton = "အချိန်ရွေးမည်";
  static const String dateRequiredError = "ရက်စွဲ ရွေးချယ်ပေးပါနော်";
  static const String timeRequiredError = "အချိန် ရွေးချယ်ပေးပါနော်";
  static const String urgentToggleLabel = "အရေးပေါ် အလုပ်";
  static const String urgentCardSubtitle =
      "သင့်အလုပ်ကို ဦးစားပေး မြှင့်တင်ပြီး မီးမောင်းထိုးပြပါမည်။";
  static const String urgentBenefitsTitle = "အကျိုးကျေးဇူးများ";
  static const String urgentBenefit1 = "အနီးအနားရှိ အလုပ်သမားများထံ မီးမောင်းထိုးပြခြင်း";
  static const String urgentBenefit2 = "ဝန်ဆောင်မှု အဖွဲ့မှ အနီးအနားရှိ အလုပ်သမားများကို တိုက်ရိုက် ဆက်သွယ်ပေးခြင်း";
  static const String urgentBenefit3 = "ပိုမြန်သော အလုပ်သမား ရှာဖွေတွဲဖက်ပေးခြင်း";
  static const String urgentBenefit4 = "ပိုမို မြင်သာသော ဖော်ပြမှု";
  static const String urgentFeeLabel = "ထပ်ဆောင်း ဝန်ဆောင်ခ";
  static const String urgentFeeValue = "၃,၀၀၀ ကျပ် (တစ်ကြိမ်)";
  static const String urgentStaffNote =
      "တိုလီမိုလီ ဝန်ဆောင်မှု အဖွဲ့သားများက အနီးအနားရှိ အလုပ်သမားများကို တိုက်ရိုက် ဆက်သွယ်ပြီး အလုပ်ပြီးမြောက်ရန် အရှိန်မြှင့်ပေးပါမည်။";

  // ── Screen 4: Tasker Tier Selection ──────────────────────────────────────
  static const String workersTierTitle = "အလုပ်သမား အဆင့် ရွေးချယ်ပါ";
  static const String workerTierSectionTitle = "အလုပ်သမား အဆင့်";
  static const String workerTierInfoButton = "အဆင့်များ အကြောင်း";
  static const String workerTierInfoSheetTitle = "အလုပ်သမား အဆင့်များ ဆိုသည်မှာ";
  static const String workerTierInfoSheetClose = "ရပြီ";
  static const String workerTierRequiredError = "အလုပ်သမား အဆင့် ရွေးချယ်ပေးပါနော်";
  // Tier ladder — friendly labels on cards; the "Tier N" number shows only in
  // the info sheet (see [WorkerTierInfo.number]).
  static const String tier1Label = "အသစ် စတင်သူ";
  static const String tier1Description = "အသစ် စတင်သော အလုပ်သမားများ";
  static const String tier2Label = "အခြေခံ အတွေ့အကြုံ";
  static const String tier2Description = "အခြေခံ အတွေ့အကြုံ ရှိသူများ";
  static const String tier3Label = "အတည်ပြုပြီး လုပ်သား";
  static const String tier3Description = "အတည်ပြုပြီး ယုံကြည်ရသူများ";
  static const String tier4Label = "ရမှတ်မြင့် တည်ငြိမ်";
  static const String tier4Description = "ရမှတ်ကောင်း အမြဲ ရရှိသူများ";
  static const String tier5Label = "အဆင့်မြင့် ကျွမ်းကျင်";
  static const String tier5Description = "အဆင့်မြင့် အလုပ်သမားများ";
  static const String tier6Label = "ကျွမ်းကျင် အထူးပြု";
  static const String tier6Description = "အထူး ကျွမ်းကျင်သူများ";
  static const String tier7Label = "ထိပ်တန်း လုပ်သား";
  static const String tier7Description = "ထိပ်တန်း အရည်အချင်းရှင်များ";

  // ── Screen 5: Task Description ───────────────────────────────────────────
  static const String descriptionTitle = "အလုပ်အကြောင်း ဖော်ပြပါ";
  static const String descriptionPlaceholder = "ဥပမာ - ရေယိုနေတယ်";
  static const String aiWriteButton = "AI က ရေးပေးမည်";
  static const String descriptionRequiredError = "အလုပ်အကြောင်း ဖော်ပြပေးပါနော်";

  // ── Screen 6: Budget & AI Price Evaluation ───────────────────────────────
  static const String budgetTitle = "ဈေးနှုန်း သတ်မှတ်ပါ";
  static const String budgetInputLabel = "သင် ပေးလိုသော ဈေးနှုန်း (ကျပ်)";
  static const String budgetInputHint = "ဥပမာ - ၁၀၀၀၀";
  static const String budgetCurrency = "ကျပ်";
  static const String budgetRequiredError = "ဈေးနှုန်း ထည့်သွင်းပေးပါနော်";
  static const String budgetEvalTitle = "AI ၏ အကြံပြုချက်";
  static const String budgetVerdictLow = "ဈေးနှုန်း သတ်မှတ်ထားသည်ထက် နည်းနေနိုင်ပါသည်။";
  static const String budgetVerdictReasonable = "ဈေးနှုန်း သင့်တင့်မျှတ ပါသည်။";
  static const String budgetVerdictHigh = "ဈေးနှုန်း သတ်မှတ်ထားသည်ထက် များနေနိုင်ပါသည်။";
  static const String budgetGuidanceNote =
      "AI သည် အကြံပြုရုံသာ ဖြစ်ပါသည်။ နောက်ဆုံး ဈေးနှုန်းကို သင်ကိုယ်တိုင် ဆုံးဖြတ်ပါသည်။";

  // ── Screen 7: Review & Submit ────────────────────────────────────────────
  static const String reviewTitle = "အချက်အလက်များ စစ်ဆေးပါ";
  static const String reviewCategoryLabel = "အလုပ်အမျိုးအစား";
  static const String reviewLocationLabel = "နေရာ";
  static const String reviewWorkMethodLabel = "လုပ်ဆောင်ပုံ";
  static const String reviewDateLabel = "ရက်စွဲ";
  static const String reviewTimeLabel = "အချိန်";
  static const String reviewUrgentLabel = "အရေးပေါ် အလုပ်";
  static const String reviewUrgentYes = "ဟုတ် (+၃,၀၀၀ ကျပ်)";
  static const String reviewUrgentNo = "မဟုတ်";
  static const String reviewTierLabel = "အလုပ်သမား အဆင့်";
  static const String reviewBudgetLabel = "ဈေးနှုန်း";
  static const String reviewDescriptionLabel = "အသေးစိတ်ဖော်ပြချက်";
  static const String reviewNotesLabel = "ထပ်ဆောင်း မှတ်ချက် (ရွေးချယ်နိုင်)";
  static const String reviewNotesHint = "ပြောင်းလဲလိုသည်များ သို့မဟုတ် မှတ်ချက် ပြောပါ";
  static const String editLink = "ပြင်မည်";
  static const String publishButton = "အလုပ်တင်မည်";
  static const String remoteLocationValue = "အဝေးမှ လုပ်ဆောင်မည်";

  // ── Success modal ─────────────────────────────────────────────────────────
  static const String successTitle = "အလုပ်တင်ပြီးပါပြီ";
  static const String successMessage =
      "သင့်အတွက် သင့်တော်သော အလုပ်သမားများကို ရှာဖွေပေးနေပါသည်";
  static const String successGoToActivity = "လုပ်ဆောင်ချက်များ သို့ သွားမည်";
  static const String successGoHome = "ပင်မသို့ ပြန်မည်";

  // ── AI Task Scoper (live OpenAI via Firebase, offline-mock fallback) ─────
  static const String aiOfflineBadge = "အော့ဖ်လိုင်း";
  static const String aiThinking = "AI စဉ်းစားနေသည်...";
  // Screen 1
  static const String suggestCategoryButton = "AI ဖြင့် အမျိုးအစား ရှာမည်";
  static const String suggestCategoryNeedTitle = "အလုပ် ခေါင်းစဉ် အရင် ထည့်ပါနော်";
  // Screen 6 — AI price band
  static const String aiPriceRangeTitle = "AI အကြံပြု ဈေးနှုန်း";
  static const String aiPriceRangeRetry = "ပြန်ကြိုးစားမည်";
  // Review — Task Attractiveness Score
  static const String attractivenessTitle = "အလုပ် ဆွဲဆောင်မှု ရမှတ်";
  static const String attractivenessScoreSuffix = "/၁၀၀";
  static const String attractivenessStrengths = "အားသာချက်များ";
  static const String attractivenessWeaknesses = "အားနည်းချက်များ";
  static const String attractivenessMissing = "ဖြည့်သင့်သည်များ";
  // Mock evaluation phrases (offline fallback).
  static const String evalStrengthLocation = "နေရာ အချက်အလက် ပြည့်စုံသည်";
  static const String evalStrengthBudget = "ဈေးနှုန်း သတ်မှတ်ထားသည်";
  static const String evalStrengthUrgent = "အရေးပေါ်ဖြစ်၍ မြန်ဆန်စွာ တွဲဖက်နိုင်သည်";
  static const String evalStrengthGeneric = "အခြေခံ အချက်အလက်များ ပြည့်စုံသည်";
  static const String evalWeaknessShortDesc = "အသေးစိတ်ဖော်ပြချက် တိုလွန်းသည်";
  static const String evalMissingBudget = "ဈေးနှုန်း ထည့်သွင်းပါ";
  static const String evalMissingSchedule = "ရက်စွဲနှင့် အချိန် ထည့်သွင်းပါ";

  // ── Tasker-Finding mode (AI match shortlist — Slice 1, spec §4.3) ────────
  // Pho Wa Yoke pre-filters + scores taskers in Dart; the model only ranks and
  // explains. Every number shown is real app data, never model output.
  static const String matchCtaTitle = "AI ဖြင့် အကောင်းဆုံး အလုပ်သမား ရှာမည်";
  static const String matchCtaSubtitle =
      "ဖိုးဝရုပ်က သင့်အတွက် အသင့်တော်ဆုံး ၃ ဦးကို ရွေးပေးပါမည်။";
  static const String matchSheetTitle = "ဖိုးဝရုပ် ရွေးချယ်ပေးထားသူများ";
  static const String matchThinking = "အကောင်းဆုံး အလုပ်သမားများ ရှာနေပါသည်…";
  static const String matchThinkingHint = "ခဏစောင့်ပေးပါနော်။";
  static const String matchReadyMessage =
      "ဒါက အသင့်တော်ဆုံး အလုပ်သမားများပါ။ တစ်ဦးကို ရွေးနိုင်ပါပြီ။";
  static const String matchPickButton = "ဒီသူကို ရွေးမည်";
  static const String matchEmptyTitle = "ကိုက်ညီသူ မတွေ့သေးပါ";
  static const String matchEmptyMessage =
      "စစ်ထုတ်မှုများကို လျှော့ချပြီး ပြန်ကြိုးစားကြည့်ပါ။";
  static const String matchSpeakServicePrompt = "ဘယ်လို အလုပ်သမား လိုချင်လဲ ပြောပါ";
  static const String matchOfflineNote = "အော့ဖ်လိုင်း — အနီးအနား အလုပ်သမားများမှ ရွေးထားသည်";
  // Templated Burmese reason clauses (offline fallback). Composed into a short,
  // one-line "why I picked them" that the read-aloud button can speak.
  static const String matchReasonSkill = "လိုအပ်တဲ့ ကျွမ်းကျင်မှုနဲ့ ကိုက်ညီ";
  static const String matchReasonRatingSuffix = "★ ရမှတ်ကောင်း";
  static const String matchReasonNearbySuffix = "km အနီးမှာ";
  static const String matchReasonAvailable = "ယခု အားနေသည်";
  static const String matchReasonExperiencedSuffix = "ကြိမ် အောင်မြင်ပြီး";
  static const String matchReasonTopTier = "ယုံကြည်ရသော အဆင့်မြင့်";
  static const String matchReasonVerified = "အတည်ပြုပြီးသား";

  // ── Task-Handling mode (Slice 4, spec §4.4/§4.8) ─────────────────────────
  // Gentle, non-blocking. AI SUGGESTS; rules/reviews and the user decide.
  // Stale-post nudge (client, §4.4 Phase 1).
  static const String stalePostTitle = "အလုပ်တင်ထားတာ ကြာနေပါပြီ";
  static const String stalePostSubtitle =
      "ဖိုးဝရုပ်က မြန်မြန်ဆို အလုပ်သမား ရအောင် အကြံပြုပေးပါမယ်။";
  static const String stalePostTipsTitle = "အကြံပြုချက်များ";
  static const String stalePostFlagButton = "ဝန်ဆောင်မှုအဖွဲ့ကို အကူအညီတောင်းမည်";
  static const String stalePostFlaggedMessage =
      "TOLY MOLY အဖွဲ့ကို အကြောင်းကြားပြီးပါပြီ — အနီးအနားရှိ အလုပ်သမားများကို ကူညီရှာပေးပါမည်။";
  static const String stalePostDismiss = "ရပြီ";
  // Templated tips (offline fallback).
  static const String tipRaiseBudget = "ဈေးနှုန်းကို အနည်းငယ် တိုးပေးကြည့်ပါ။";
  static const String tipWidenTier = "အလုပ်သမား အဆင့် ရွေးချယ်မှုကို ကျယ်ကျယ် ခွင့်ပြုပါ။";
  static const String tipAddDetail = "အသေးစိတ်နှင့် ဓာတ်ပုံ ထပ်ထည့်ပါ။";
  static const String tipMarkUrgent = "အရေးပေါ်အဖြစ် သတ်မှတ်ပါက ပိုမြင်သာပါမည်။";

  // Tasker per-task brief (§4.8).
  static const String briefTitle = "ဖိုးဝရုပ်၏ အကြို ရှင်းလင်းချက်";
  static const String briefWhatClientWants = "ဖောက်သည် လိုချင်တာ";
  static const String briefPrepTitle = "ပြင်ဆင်ရန် / ကိရိယာများ";
  static const String briefThinking = "အလုပ်အကြောင်း ပြင်ဆင်နေပါသည်…";
  // Offline fallback brief.
  static const String briefPrepGeneric = "လိုအပ်သော ကိရိယာများ ယူဆောင်လာပါ။";
  static const String briefPrepArriveEarly = "အချိန်မီ ရောက်အောင် ကြိုထွက်ပါ။";
  static const String briefPrepConfirm = "အလုပ်မစတင်မီ ဖောက်သည်နှင့် အတည်ပြုပါ။";

  // Gentle tasker reminder (§4.8).
  static const String reminderTitle = "သတိပေးချက်";
  static String reminderBody(String timeSlot) =>
      "ဒီအလုပ်ကို သတ်မှတ်ချိန် ($timeSlot) အတွင်း ပြီးအောင် လုပ်ပေးပါနော်။";

  // Completion summary + suggested tier (§4.4 Phase 3).
  static const String completionTitle = "ပြီးစီးမှု အနှစ်ချုပ်";
  static const String completionThinking = "အနှစ်ချုပ် ပြင်ဆင်နေပါသည်…";
  static const String completionSuggestedTierTitle = "အဆင့် အကြံပြုချက်";
  static const String tierSuggestUp = "အဆင့် တစ်ဆင့် တက်သင့်သည် ⬆";
  static const String tierSuggestSame = "အဆင့် ဆက်ထိန်းသင့်သည်";
  static const String tierSuggestDown = "အဆင့် ပြန်လည် သုံးသပ်သင့်သည် ⬇";
  static const String tierSuggestNote =
      "ဒါက AI ၏ အကြံပြုချက်သာ ဖြစ်ပါသည်။ တကယ့်အဆင့်ကို စည်းမျဉ်းများနှင့် ဖောက်သည်၏ အဆင့်သတ်မှတ်ချက်က ဆုံးဖြတ်ပါသည်။";
  // Offline fallback.
  static const String completionSummaryGeneric = "အလုပ်ကို အောင်မြင်စွာ ပြီးမြောက်ခဲ့ပါသည်။";
  static const String completionOnTime = "သတ်မှတ်ချိန်အတွင်း ပြီးစီးသဖြင့် အဆင့်တိုးရန် အကြံပြုသည်။";
  static const String completionRatingLow =
      "ဖောက်သည် အဆင့်သတ်မှတ်ချက် နိမ့်သဖြင့် ပြန်လည်သုံးသပ်ရန် အကြံပြုသည်။";

  // ── Yangon townships (on-site location dropdown) ─────────────────────────
  static const List<String> yangonTownships = [
    "လှိုင်",
    "ကမာရွတ်",
    "မရမ်းကုန်း",
    "ရန်ကင်း",
    "သင်္ဃန်းကျွန်း",
    "တာမွေ",
    "ဗဟန်း",
    "စမ်းချောင်း",
    "အင်းစိန်",
    "မြောက်ဒဂုံ",
    "တောင်ဒဂုံ",
    "ဒဂုံဆိပ်ကမ်း",
    "မင်္ဂလာဒုံ",
    "အလုံ",
    "လမ်းမတော်",
    "ကျောက်တံတား",
    "ပုဇွန်တောင်",
    "သာကေတ",
  ];
}
