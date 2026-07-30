/// Static Burmese-first copy for the Task Posting Flow (method picker, the
/// voice conversation, the manual steps and the shared summary). Kept alongside
/// [OnboardingStrings] but in its own file since this flow owns a large amount
/// of copy, mirroring that file's convention.
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

  // ── Posting method picker (the flow's entry screen) ──────────────────────
  static const String methodTitle = "အလုပ်တင်နည်း ရွေးချယ်ပါ";
  static const String methodMascotMessage =
      "နှစ်မျိုးလုံး ရပါတယ်။ သင့်အတွက် အဆင်ပြေတာ ရွေးလိုက်ပါနော်။";
  static const String methodVoiceLabel = "အသံဖြင့် ပြောမည်";
  static const String methodVoiceSubtitle = "ဖိုးဝရုပ်နှင့် ပြောရင်း တင်မည်";
  static const String methodManualLabel = "ကိုယ်တိုင် ဖြည့်မည်";
  static const String methodManualSubtitle = "အဆင့် ၅ ဆင့် ဖြည့်မည်";
  static const String methodHelperNote =
      "နှစ်မျိုးလုံး နောက်ဆုံးမှာ အနှစ်ချုပ် စာမျက်နှာသို့ ရောက်ပါမည်။";

  // ── AI Task Assistant conversation ───────────────────────────────────────
  // Real multi-turn AI (backend/apps/tasks, POST /api/tasks/ai/analyze) with
  // a local fallback engine that takes over seamlessly if the backend is
  // ever unreachable — see AiService.taskAssistant + ai_mock.dart's
  // taskAssistantFallbackTurn. The UI shell (bubbles, mic, quick replies) is
  // unchanged from the old scripted demo.
  static const String voiceChatTitle = "ဖိုးဝရုပ်နှင့် ပြောဆိုပါ";
  static const String voiceChatMascotMessage =
      "မိုက်ကို နှိပ်ပြီး ပြောပါ။ စာရိုက်ချင်လည်း ရပါတယ်။";
  static const String voiceChatInputHint = "စာရိုက်ပါ သို့မဟုတ် မိုက်ကို နှိပ်ပါ";
  static const String voiceChatMicPrompt = "မိုက်ကို နှိပ်ပြီး ပြောပါ";
  static const String voiceChatListening = "နားထောင်နေပါသည်…";
  static const String voiceChatSendLabel = "ပို့မည်";
  static const String voiceChatRestart = "အစမှ ပြန်စမည်";
  static const String voiceChatDemoNote =
      "ဒီမိုအတွက် ပြင်ဆင်ထားသော စကားဝိုင်း ဖြစ်ပါသည်။";

  // Opening greeting — open-ended, no category picker shown yet.
  static const String taskAssistantGreeting =
      "မင်္ဂလာပါ။ ဘာအကူအညီ လိုအပ်လဲ ပြောပြပါနော်။";
  // Mic tap (demo only — no real speech recognition) always hands back this
  // one fixed line, per the locked design (§6.3): text is the only dynamic
  // input surface, voice stays a fixed demo affordance.
  static const String taskAssistantMicTranscript =
      "ရေပိုက် ယိုနေလို့ ပြင်ချင်ပါတယ်";

  // Local fallback engine's questions (mirrors the live prompt's rules, not
  // a replay of the old fixed script — see ai_mock.dart).
  static const String fallbackAskLocation = "ဘယ်မြို့နယ်မှာလဲ ပြောပေးပါ။";
  static const String fallbackAskSchedule = "ဘယ်အချိန် လိုအပ်ပါသလဲ။";
  static const String fallbackAskUrgency = "ဒါက အရေးပေါ် အလုပ်လား။";
  static const String fallbackAskDetail =
      "နောက်ထပ် အသေးစိတ် ပြောပြပေးပါ — ဥပမာ အရွယ်အစား၊ အခြေအနေ။";

  // Confirmation stage — same UX for live and fallback conversations.
  static const String taskAssistantConfirmPrefix = "ဒါဆို — ";
  static const String taskAssistantConfirmSuffix = " — မှန်ကန်ပါသလား။";
  static const String taskAssistantConfirmYes = "ဟုတ်ကဲ့၊ မှန်ပါတယ်";
  static const String taskAssistantConfirmNo = "မမှန်ပါ၊ ပြင်ချင်ပါတယ်";
  static const String taskAssistantConfirmNoPrompt =
      "ဘယ်အချက်ကို ပြင်ချင်လဲ ပြောပြပါ။";

  // Deterministic media turn, inserted client-side after "Yes" — never part
  // of the model's own turn contract (see design doc §6.4).
  static const String taskAssistantMediaPrompt =
      "ဓာတ်ပုံ သို့မဟုတ် ဗီဒီယို ထည့်ချင်ပါသလား? ကျော်လို့လည်း ရပါတယ်။";
  static const String taskAssistantMediaContinue = "ဆက်သွားမည်";
  static const String taskAssistantWrapUpMessage =
      "ကျေးဇူးတင်ပါတယ်။ အချက်အလက်တွေ စုစည်းပြီးပါပြီ — အနှစ်ချုပ်ကို ပြပါမယ်နော်။";

  // ── Screen 1: Task Title + Category Selection ───────────────────────────
  static const String categoryTitle = "ဘာအကူအညီ လိုအပ်ပါသလဲ";
  static const String taskTitleLabel = "အလုပ် ခေါင်းစဉ်";
  static const String taskTitleHint = "ဥပမာ - ပန်ကာ တပ်ဆင်ရန်";
  static const String manualCategoryPrompt = "ဝန်ဆောင်မှု အမျိုးအစား ရွေးချယ်ပါ";
  static const String categoryVoicePrompt = "အမျိုးအစားကို အသံဖြင့် ပြောပါ";
  static const String categoryRequiredError = "ဝန်ဆောင်မှု အမျိုးအစား ရွေးချယ်ပေးပါနော်";
  static const String otherCategoryLabel = "အခြား";
  static const String specifyCategoryLabel = "အမျိုးအစား ဖော်ပြပါ";
  static const String specifyCategoryHint = "ဥပမာ - အိမ်ပြောင်းရွှေ့ခြင်း";
  static const String specifyCategoryRequiredError = "အမျိုးအစားကို ဖော်ပြပေးပါနော်";

  // ── Media attachments (photo/video, both posting methods) ────────────────
  // Manual: a skippable step between Category and When&Where. Voice: an
  // attach control in the chat input bar. Files are local paths only — never
  // uploaded, Phase 1 has no backend.
  static const String mediaStepTitle = "ဓာတ်ပုံ (သို့) ဗီဒီယို ပူးတွဲမည်";
  static const String mediaStepMascotMessage =
      "ဓာတ်ပုံ ပူးတွဲပေးရင် အလုပ်သမားက ပိုနားလည်ပါလိမ့်မယ်။ မလိုချင်ရင် ကျော်လို့ရပါတယ်။";
  static const String mediaHelperNote =
      "အများဆုံး ၃ ခု ပူးတွဲနိုင်ပါသည် — ဓာတ်ပုံ သို့မဟုတ် ဗီဒီယို။";
  static const String mediaMaxReachedNote = "အများဆုံး ၃ ခု ပူးတွဲပြီးပါပြီ။";
  static const String mediaSheetTitle = "ဓာတ်ပုံ/ဗီဒီယို ထည့်နည်း";
  static const String mediaTakePhoto = "ဓာတ်ပုံ ရိုက်မည်";
  static const String mediaChoosePhoto = "ပြခန်းမှ ဓာတ်ပုံ ရွေးမည်";
  static const String mediaRecordVideo = "ဗီဒီယို ရိုက်မည်";
  static const String mediaChooseVideo = "ပြခန်းမှ ဗီဒီယို ရွေးမည်";
  static const String mediaPickFailed = "ဓာတ်ပုံ/ဗီဒီယို ရွေးချယ်၍ မရပါ";
  static const String mediaRemoveLabel = "ဖယ်ရှားမည်";
  static const String mediaSkipButton = "ကျော်မည်";
  static const String mediaAttachTooltip = "ဓာတ်ပုံ/ဗီဒီယို ပူးတွဲမည်";
  static const String reviewMediaLabel = "ဓာတ်ပုံ/ဗီဒီယို";
  static const String reviewMediaNone = "မပူးတွဲထားပါ";
  static String reviewMediaCount(int count) => "$count ခု ပူးတွဲထားသည်";

  // ── Screen 2: When & Where (date, time, place, urgent) ───────────────────
  static const String whenWhereTitle = "ဘယ်အချိန် ဘယ်နေရာ လိုအပ်ပါသလဲ";
  static const String scheduleSectionTitle = "ရက်စွဲနှင့် အချိန်";
  static const String placeSectionTitle = "အလုပ်လုပ်မည့် နေရာ";
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

  // ── Screen 3: Tasker Level + AI-estimated budget ─────────────────────────
  // The client no longer types a price. Each level card carries the AI's
  // estimate for that level, and the selected one becomes the task's budget.
  static const String estimatedBudgetTitle = "ခန့်မှန်း ဈေးနှုန်း";
  static const String estimatedByAi = "AI က ခန့်မှန်းထားသည်";
  static const String estimatedBudgetNote =
      "ဈေးနှုန်းကို သင်ရွေးထားသော အလုပ်သမား အဆင့်အလိုက် AI က တွက်ချက်ပေးပါသည်။";
  static const String estimatedBudgetPlaceholder =
      "အဆင့် ရွေးလိုက်ရင် ဈေးနှုန်း ပေါ်လာပါမည်";
  static String tierPriceSublabel(String price) => "ခန့်မှန်း $price";

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
  static const String descriptionRequiredError = "အလုပ်အကြောင်း ဖော်ပြပေးပါနော်";

  static const String budgetCurrency = "ကျပ်";

  // ── Summary: Review & Submit (shared by the voice and manual flows) ──────
  static const String reviewTitle = "အချက်အလက်များ စစ်ဆေးပါ";
  static const String reviewTitleLabel = "အလုပ် ခေါင်းစဉ်";
  static const String reviewCategoryLabel = "အလုပ်အမျိုးအစား";
  static const String reviewLocationLabel = "နေရာ";
  static const String reviewWorkMethodLabel = "လုပ်ဆောင်ပုံ";
  static const String reviewDateLabel = "ရက်စွဲ";
  static const String reviewTimeLabel = "အချိန်";
  static const String reviewUrgentLabel = "အရေးပေါ် အလုပ်";
  static const String reviewUrgentYes = "ဟုတ် (+၃,၀၀၀ ကျပ်)";
  static const String reviewUrgentNo = "မဟုတ်";
  static const String reviewTierLabel = "အလုပ်သမား အဆင့်";
  static const String reviewBudgetLabel = "ခန့်မှန်း ဈေးနှုန်း (AI)";
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

  // ── AI Task Scoper (fully local demo simulation — no network) ────────────
  static const String aiOfflineBadge = "အော့ဖ်လိုင်း";
  static const String aiThinking = "AI စဉ်းစားနေသည်...";
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
