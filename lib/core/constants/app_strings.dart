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
  static const String exploreAllWorkers = "All Workers";
  static const String exploreFilterTrustLevel = "Trust Level";
  static const String exploreFilterRating = "Rating";
  static const String exploreFilterTownship = "Township";
  static const String exploreAvailableNow = "Available now";
  static const String exploreSortNearest = "Nearest";
  static const String exploreSortTopRated = "Top rated";
  static const String exploreSortTrustTier = "Highest trust";
  static const String exploreSortMostCompleted = "Most completed";
  static const String exploreNoResults = "No workers match these filters";
  static const String exploreResetFilters = "Reset filters";
  static const String exploreSearchHint = "ဝန်ဆောင်မှုကို ရှာဖွေပါ...";
  static const String exploreFilterCategory = "Category";
  static const String exploreFilterSort = "Sort";
  static const String exploreFilterAvailability = "Availability";
  static const String exploreAllCategories = "All Categories";
  static const String exploreAllWorkersOption = "All Workers";
  static const String exploreClearAllFilters = "Clear All";
  static const String badgeCommunityHelper = "Community Helper";
  static const String badgeVerifiedProfessional = "Verified Professional";
  static const String badgeCommunityAmbassador = "Community Ambassador";
  static const String verifiedLabel = "Verified";
  static const String tasksCompletedSuffix = "Tasks Completed";
  static const String availableNowLabel = "Available now";
  static const String availableLaterLabel = "Available later today";
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
  static const String profileTabLabel = "ပရိုဖိုင်";
  static const String comingSoonTitle = "မကြာမီ လာမည်";
  static const String comingSoonMessage = "ဒီအပိုင်းကို မကြာမီ ထည့်သွင်းပေးပါမယ်နော်";

  static const String availableForBookings = "Available for bookings";
  static const String todaysEarnings = "Today's Earnings";

  // ── Tasker Dashboard ─────────────────────────────────────────────────────
  static const String dashboardCheckIn = "Check In";
  static const String dashboardCheckOut = "Check Out";
  static const String dashboardCheckedInSince = "Checked in since";
  static const String dashboardCheckedOut = "Checked out";
  static const String dashboardHoursToday = "Hours today";
  static const String dashboardMonthlyIncome = "Monthly Income";
  static const String dashboardCompletedJobs = "Completed Jobs";
  static const String dashboardJobSearchHint = "ဘယ်အလုပ် ရှာနေပါသလဲ";
  static const String dashboardNearbyJobs = "Nearby Jobs";
  static const String dashboardAllJobs = "All Jobs";
  static const String dashboardUrgentOnly = "Urgent only";
  static const String dashboardNoJobsFound = "No matching jobs right now";
  static const String dashboardAiEstimatedBudget = "AI Estimated Budget";
  static const String dashboardInterestedCta = "စိတ်ဝင်စားသည်";
  static const String dashboardInterestReceived = "Interest Received";
  static const String dashboardMessageClientCta = "စာပို့မည်";
  static const String dashboardRequiredTierPrefix = "Requires: ";
  static const String dashboardCheckInToSeeJobs =
      "အလုပ်များကို မြင်ရန် Check In ပြုလုပ်ပါ";

  // ── Digital Task Check-In (per-task execution, distinct from the
  // Availability Management check-in/out above) ──────────────────────────
  static const String executionSectionTitle = "Digital Check-In / Check-Out";
  static const String executionStartProcess = "Start Process";
  static const String executionTodaysTask = "Today's Task";
  static const String executionLiveBadge = "On-site";
  static const String executionPageTitle = "Digital Check-In / Check-Out";
  static const String executionLeavingCta = "🚶 အလုပ်သို့ ထွက်ခွာပြီ";
  static const String executionStartedCta = "📍 ရောက်ရှိပြီး အလုပ်စတင်ပြီ";
  static const String executionCompletedCta = "✅ အလုပ်ပြီးစီးပါပြီ";
  static const String executionWaitingClientConfirmation =
      "အလုပ်ပြီးစီးပါပြီ — ဖောက်သည် အတည်ပြုရန် စောင့်ဆိုင်းနေသည်";
  static const String executionTimelineTitle = "Timeline";
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
