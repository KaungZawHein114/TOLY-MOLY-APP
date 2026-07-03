/// Static UI strings (English + a little Burmese). No runtime loading.
class AppStrings {
  AppStrings._();

  static const String appName = "TOLY MOLY";
  static const String tagline = "Hire for the task, pay for the work, done in a day.";
  static const String taglineMm = "အလုပ်အတွက် ငှားပါ၊ အလုပ်အတွက် ပေးပါ၊ တစ်ရက်နဲ့ ပြီးပါ။";

  static const String chooseRole = "How would you like to start?";
  static const String customer = "Customer";
  static const String customerMm = "ဝန်ဆောင်မှု ရယူသူ";
  static const String worker = "Worker";
  static const String workerMm = "ဝန်ဆောင်မှု ပေးသူ";

  static const String nearbyWorkers = "Nearby Workers";
  static const String categories = "Categories";
  static const String bookNow = "Book Now";
  static const String confirmBooking = "Confirm Booking";
  static const String bookingConfirmed = "Booking Confirmed!";

  // ── Tasker Explore & Discovery ──────────────────────────────────────────
  static const String exploreAllWorkers = "အလုပ်သမား အားလုံး";
  static const String exploreFilterTrustLevel = "ယုံကြည်မှု အဆင့်";
  static const String exploreFilterRating = "အဆင့်သတ်မှတ်ချက်";
  static const String exploreFilterTownship = "မြို့နယ်";
  static const String exploreAvailableNow = "ယခုရရှိနိုင်သည်";
  static const String exploreSortNearest = "အနီးဆုံး";
  static const String exploreSortTopRated = "အဆင့်အမြင့်ဆုံး";
  static const String exploreSortTrustTier = "ယုံကြည်မှု အမြင့်ဆုံး";
  static const String exploreSortMostCompleted = "ပြီးစီးအများဆုံး";
  static const String exploreNoResults = "ဤစစ်ထုးမှုများနှင့် ကိုက်ညီသော အလုပ်သမား မရှိပါ";
  static const String exploreResetFilters = "စစ်ထုးမှုများ ပြန်လည်သတ်မှတ်မည်";
  static const String exploreSearchHint = "ဝန်ဆောင်မှုကို ရှာဖွေပါ...";
  static const String exploreFilterCategory = "အမျိုးအစား";
  static const String exploreFilterSort = "စီစဉ်ပုံ";
  static const String exploreFilterAvailability = "ရရှိနိုင်မှု";
  static const String exploreAllCategories = "အမျိုးအစား အားလုံး";
  static const String exploreAllWorkersOption = "အလုပ်သမား အားလုံး";
  static const String exploreClearAllFilters = "အားလုံး ရှင်းမည်";
  static const String badgeCommunityHelper = "ရပ်ရွာ အကူအညီပေးသူ";
  static const String badgeVerifiedProfessional = "အတည်ပြုထားသော ကျွမ်းကျင်သူ";
  static const String badgeCommunityAmbassador = "ရပ်ရွာ ကိုယ်စားလှယ်";
  static const String verifiedLabel = "အတည်ပြုပြီး";
  static const String tasksCompletedSuffix = "ပြီးစီးအလုပ်များ";
  static const String availableNowLabel = "ယခုရရှိနိုင်သည်";
  static const String availableLaterLabel = "ယနေ့ နောက်ပိုင်း ရရှိနိုင်သည်";
  static const String scheduleWorkerCta = "အလုပ်အပ်မည်";
  static const String scheduleWorkerTitle = "အလုပ်အပ်မည်";
  static const String scheduleCategoryLabel = "လုပ်ငန်းအမျိုးအစား";
  static const String scheduleLocationLabel = "တည်နေရာ";
  static const String scheduleTownshipPlaceholder = "မြို့နယ်";
  static const String scheduleAddressPlaceholder = "လိပ်စာ အသေးစိတ်";
  static const String scheduleDateLabel = "ရက်စွဲ";
  static const String scheduleTimeLabel = "အချိန်";
  static const String scheduleDescriptionLabel = "ဖော်ပြချက်";
  static const String scheduleDescriptionPlaceholder = "ဘာအကူအညီ လိုအပ်ပါသလဲ";
  static const String scheduleSubmitCta = "တောင်းဆိုမည်";
  static const String scheduleRequiredError = "ဤအချက်အလက် လိုအပ်ပါသည်";
  static const String taskRequestSentTitle = "Task Request Sent!";
  static const String taskRequestSentMessage =
      "သင့်တောင်းဆိုချက်ကို အလုပ်သမားထံ ပေးပို့ပြီးပါပြီ။ မကြာမီ ပြန်လည်ဆက်သွယ်ပါမည်။";

  // ── Client Home Screen (Burmese-first, per the home screen spec) ───────
  static const String homeGreeting = "မင်္ဂလာပါ 👋";
  static const String homeDemoClientName = "မအေးအေး";
  static const String workerHomeGreeting = "မင်္ဂလာပါ";
  static const String homeNotificationsEmpty = "အကြောင်းကြားစာ မရှိသေးပါ";
  static const String homePostTaskAction = "အလုပ်တင်မည်";
  static const String homeFindWorkerAction = "အလုပ်သမားရှာမည်";
  static const String homeBrowseServicesTitle = "ဝန်ဆောင်မှုများ ရှာဖွေမည်";
  static const String homeCategoriesTitle = "ဝန်ဆောင်မှု အမျိုးအစားများ";
  static const String homeCategoriesSubtitle = "သင်လိုအပ်သော ဝန်ဆောင်မှုကို ရွေးချယ်ပါ";
  static const String homeCategoriesSearchHint = "လုပ်ငန်းအမျိုးအစား ရှာရန်...";
  static const String homeCategoriesSearchEmpty = "ရှာဖွေမှုနှင့် ကိုက်ညီသော ဝန်ဆောင်မှု မရှိပါ";
  static const String homeTabLabel = "ပင်မ";
  static const String activityTabLabel = "လုပ်ဆောင်ချက်များ";
  static const String chatTabLabel = "စကားပြော";
  static const String pendingTabLabel = "စောင့်ဆိုင်း";
  static const String profileTabLabel = "ပရိုဖိုင်";
  static const String comingSoonTitle = "မကြာမီ လာမည်";
  static const String comingSoonMessage = "ဒီအပိုင်းကို မကြာမီ ထည့်သွင်းပေးပါမယ်နော်";

  static const String availableForBookings = "ဝန်ဆောင်မှု လက်ခံရန် အသင့်ရှိသည်";
  static const String todaysEarnings = "ယနေ့ ဝင်ငွေ";

  // ── Tasker Dashboard ─────────────────────────────────────────────────────
  static const String dashboardCheckIn = "အလုပ်ဝင်မည်";
  static const String dashboardCheckOut = "အလုပ်ထွက်မည်";
  static const String dashboardCheckedInSince = "ဝင်ရောက်ချိန်";
  static const String dashboardCheckedOut = "ထွက်ရောက်ပြီး";
  static const String dashboardHoursToday = "ယနေ့ အလုပ်ချိန်";
  static const String dashboardMonthlyIncome = "လစဉ်ဝင်ငွေ";
  static const String dashboardCompletedJobs = "ပြီးစီးအလုပ်များ";
  static const String dashboardJobSearchHint = "ဘယ်အလုပ် ရှာနေပါသလဲ";
  static const String dashboardNearbyJobs = "အနီးအနားရှိ အလုပ်များ";
  static const String dashboardAllJobs = "အလုပ်အားလုံး";
  static const String dashboardUrgentOnly = "အရေးပေါ်သာ ပြရန်";
  static const String dashboardNoJobsFound = "ကိုက်ညီသော အလုပ် မရှိသေးပါ";
  static const String dashboardAiEstimatedBudget = "AI ခန့်မှန်းဘတ်ဂျက်";
  static const String dashboardInterestedCta = "အလုပ်လက်ခံမည်";
  static const String dashboardInterestReceived = "လက်ခံပြီးပါပြီ";
  static const String dashboardMessageClientCta = "စာပို့မည်";
  static const String dashboardViewDetailsCta = "အသေးစိတ်ကြည့်မည်";
  static const String dashboardRequiredTierPrefix = "လိုအပ်ချက်: ";
  static const String dashboardCheckInToSeeJobs =
      "အလုပ်များကို မြင်ရန် 'အလုပ်ဝင်မည်' ကို နှိပ်ပါ";

  // ── Job Board search + filters ──────────────────────────────────────────
  static const String jobBoardTitle = "အလုပ်များ စာရင်း";
  static const String jobBoardSearchHint = "အလုပ်ကို ရှာဖွေပါ...";
  static const String jobBoardVoiceSearchLabel = "အသံဖြင့် ရှာဖွေမည်";
  static const String jobBoardFilterLabel = "စစ်ထုးမှုများ";
  static const String jobBoardCategoryLabel = "အမျိုးအစား";
  static const String jobBoardCategoryAll = "အလုပ်အားလုံး";
  static const String jobBoardDistanceLabel = "အကွာအဝေး";
  static const String jobBoardDistanceNearby = "အနီးအနား";
  static const String jobBoardSortLabel = "စီစဉ်ပုံ";
  static const String jobBoardSortRecommended = "အကြံပြုထားသည်";
  static const String jobBoardSortNearest = "အနီးဆုံး";
  static const String jobBoardSortHighestBudget = "ဘတ်ဂျက်အမြင့်ဆုံး";
  static const String jobBoardSortNewest = "အသစ်ဆုံး";
  static const String jobBoardSortUrgentFirst = "အရေးပေါ်အရင်";
  static const String jobBoardBudgetLabel = "ဘတ်ဂျက်";
  static const String jobBoardBudgetAny = "ဘတ်ဂျက် မည်သည်ဖြစ်စေ";
  static const String jobBoardBudgetUnder20k = "၂၀,၀၀၀ ကျပ်အောက်";
  static const String jobBoardBudget20to50k = "၂၀,၀၀၀–၅၀,၀၀၀ ကျပ်";
  static const String jobBoardBudgetAbove50k = "၅၀,၀၀၀ ကျပ်အထက်";
  static const String jobBoardTownshipLabel = "မြို့နယ်";
  static const String jobBoardUrgentOnlyChip = "အရေးပေါ်သာ";
  static const String jobBoardClearAllFilters = "အားလုံး ရှင်းမည်";
  static const String jobBoardPostedPrefix = "တင်ထားချိန်: ";

  // ── Digital Task Check-In (per-task execution, distinct from the
  // Availability Management check-in/out above) ──────────────────────────
  static const String executionSectionTitle = "အလုပ်ချိန် မှတ်တမ်းတင်ခြင်း";
  static const String executionStartProcess = "လုပ်ငန်းစတင်မည်";
  static const String executionTodaysTask = "ယနေ့ အလုပ်";
  static const String executionLiveBadge = "လုပ်ငန်းခွင်";
  static const String executionPageTitle = "အလုပ်ချိန် မှတ်တမ်းတင်ခြင်း";
  static const String executionLeavingCta = "🚶 အလုပ်သို့ ထွက်ခွာပြီ";
  static const String executionStartedCta = "📍 ရောက်ရှိပြီး အလုပ်စတင်ပြီ";
  static const String executionCompletedCta = "✅ အလုပ်ပြီးစီးပါပြီ";
  static const String executionWaitingClientConfirmation =
      "အလုပ်ပြီးစီးပါပြီ — ဖောက်သည် အတည်ပြုရန် စောင့်ဆိုင်းနေသည်";
  static const String executionTimelineTitle = "လုပ်ငန်းအဆင့်များ";
  static const String executionLeaveLabel = "ထွက်ခွာပြီ";
  static const String executionArrivalLabel = "ရောက်ရှိပြီး စတင်ပြီ";
  static const String executionCompletionLabel = "ပြီးစီးပါပြီ";

  // ── AI Assistant chatbot (app-scoped, intent-aware) ─────────────────────
  static const String chatbotTitle = "TOLY MOLY အကူအညီ";
  static const String chatbotFabLabel = "အကူအညီ မေးမည်"; // FAB tooltip / semantics
  static const String chatbotInputHint = "မက်ဆေ့ချ် ရိုက်ထည့်ပါ…";
  static const String chatbotWelcome =
      "မင်္ဂလာပါ။ 👋 ကျွန်တော် TOLY MOLY အကူအညီပေးသူပါ။ "
      "ဘာများ လိုအပ်လဲ ပြောပြပါ — ဥပမာ \"sink ပြင်ဖို့ လူရှာချင်တယ်\"။";
  static const String chatbotTyping = "ရိုက်နေသည်…";
  static const String chatbotPostTaskCta = "အလုပ်တင်မည် (Post a Task)";
  static const String chatbotFindTaskCta = "အလုပ်ရှာမည် (Find a Task)";
  static const String chatbotOfflineHint = "အော့ဖ်လိုင်း"; // shown when reply came from mock

  static const String currency = "MMK";
}
