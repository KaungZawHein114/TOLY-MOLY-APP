// ============================================================================
// CORE FILE 1 of 2 — HARDCODED DART CONSTANTS ONLY
// ----------------------------------------------------------------------------
// NO JSON file loading. NO File.readAsString(). NO jsonDecode() at runtime.
// Every value below is a compile-time `const` — zero async, zero I/O.
// ============================================================================

import '../../features/customer/task_posting/task_posting_models.dart';
// Profile models reuse the onboarding enums (Gender, HearAboutSource,
// TaskerSkill) so a profile and the onboarding draft that produced it speak
// the same vocabulary — no parallel/duplicate enums to keep in sync.
import '../../features/onboarding/onboarding_models.dart';

class Worker {
  final int id;
  final String name;
  final String skill;
  final String emoji; // avatar emoji (offline, no network images)
  final double rating;
  final int reviews;
  final String experience;
  final double distanceMiles;
  final bool isAvailableNow;
  final String bio;
  final int currentTier; // 1-7, static demo value — drives the trust badge only
  final String township;
  final int completedTasks;
  final bool isVerified;

  const Worker({
    required this.id,
    required this.name,
    required this.skill,
    required this.emoji,
    required this.rating,
    required this.reviews,
    required this.experience,
    required this.distanceMiles,
    required this.isAvailableNow,
    required this.bio,
    required this.currentTier,
    required this.township,
    required this.completedTasks,
    required this.isVerified,
  });
}

/// Client-facing trust badge, derived from a worker's tier band. Clients
/// never see raw tier numbers or trust-point calculations — only this label.
String trustBadgeFor(int tier) {
  if (tier <= 2) return "Community Helper";
  if (tier <= 5) return "Verified Professional";
  return "Community Ambassador";
}

/// Maps a worker's raw tier (1-7) to the same friendly trust-level bucket
/// used by the Task Posting Flow's worker-tier filter (basic/trusted/expert).
WorkerTier tierBucketFor(int tier) {
  if (tier <= 2) return WorkerTier.basic;
  if (tier <= 5) return WorkerTier.trusted;
  return WorkerTier.expert;
}

class Category {
  final int id;
  final String name;
  final String icon;
  final String burmese;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.burmese,
  });
}

/// A matched, confirmed job. All bookings in this app are on-site (Phase 1
/// has no remote-booking concept), so the Digital Task Check-In flow
/// (lib/features/worker/task_execution_screen.dart) applies to any booking
/// with status == "Active" without a separate taskType field to check.
class Booking {
  final int id;
  final String customerName;
  final String workerName;
  final String skill;
  final String status; // Completed | Active | Pending
  final String date;
  final String timeSlot;
  final String township;
  final int totalMmk;

  const Booking({
    required this.id,
    required this.customerName,
    required this.workerName,
    required this.skill,
    required this.status,
    required this.date,
    required this.timeSlot,
    required this.township,
    required this.totalMmk,
  });
}

/// A customer-created task post, published from the Task Posting Flow.
/// Distinct from [Booking] (which represents an already-matched job with a
/// known worker) — a fresh task post has no worker assigned yet.
class TaskPost {
  final int id;
  final String category;
  final TaskType taskType;
  final String township;
  final String address;
  final DateTime date;
  final String timeSlot;
  final bool urgent;
  final int workersNeeded;
  final WorkerTier workerTier;
  final String description;
  final int budgetMmk;
  final DateTime createdAt;

  const TaskPost({
    required this.id,
    required this.category,
    required this.taskType,
    required this.township,
    required this.address,
    required this.date,
    required this.timeSlot,
    required this.urgent,
    required this.workersNeeded,
    required this.workerTier,
    required this.description,
    required this.budgetMmk,
    required this.createdAt,
  });
}

/// A direct request to a specific worker, created from the Schedule Worker
/// screen. Distinct from [TaskPost] (an open marketplace task with no
/// chosen worker) — fields here are the smaller set the Tasker Explore
/// spec calls for: no workersNeeded/workerTier/urgency, since the worker
/// is already chosen.
class TaskRequest {
  final int id;
  final int workerId;
  final String category;
  final String township;
  final String address;
  final DateTime date;
  final String timeSlot;
  final String description;
  final DateTime createdAt;

  const TaskRequest({
    required this.id,
    required this.workerId,
    required this.category,
    required this.township,
    required this.address,
    required this.date,
    required this.timeSlot,
    required this.description,
    required this.createdAt,
  });
}

/// Digital Task Check-In stage for a confirmed, on-site [Booking]. Tracks
/// only the worker-side milestones — client confirmation/rating/tip are a
/// separate, future-slice flow with no worker-app screen of their own yet.
enum ExecutionStatus { pending, leavingForTask, started, completed }

class TaskExecution {
  final int taskId;
  final ExecutionStatus status;
  final DateTime? leaveTime;
  final DateTime? arrivalTime;
  final DateTime? completionTime;

  const TaskExecution({
    required this.taskId,
    this.status = ExecutionStatus.pending,
    this.leaveTime,
    this.arrivalTime,
    this.completionTime,
  });

  TaskExecution copyWith({
    ExecutionStatus? status,
    DateTime? leaveTime,
    DateTime? arrivalTime,
    DateTime? completionTime,
  }) =>
      TaskExecution(
        taskId: taskId,
        status: status ?? this.status,
        leaveTime: leaveTime ?? this.leaveTime,
        arrivalTime: arrivalTime ?? this.arrivalTime,
        completionTime: completionTime ?? this.completionTime,
      );
}

class ChatMessage {
  final String text;
  final bool fromUser;

  const ChatMessage({required this.text, required this.fromUser});
}

/// An open marketplace job a tasker can browse and express interest in —
/// distinct from [TaskRequest] (already addressed to one specific worker).
/// `requiredTier` gates visibility: a worker only sees jobs at or below
/// their own [Worker.currentTier].
class Job {
  final int id;
  final String category;
  final String township;
  final double distanceMiles;
  final bool isUrgent;
  final int aiSuggestedBudgetMmk;
  final int requiredTier;
  final DateTime dateTime;
  final String description;
  final DateTime createdAt;
  final String status; // "pending" | "Interest Received"

  const Job({
    required this.id,
    required this.category,
    required this.township,
    required this.distanceMiles,
    required this.isUrgent,
    required this.aiSuggestedBudgetMmk,
    required this.requiredTier,
    required this.dateTime,
    required this.description,
    required this.createdAt,
    this.status = "pending",
  });

  Job copyWith({String? status}) => Job(
        id: id,
        category: category,
        township: township,
        distanceMiles: distanceMiles,
        isUrgent: isUrgent,
        aiSuggestedBudgetMmk: aiSuggestedBudgetMmk,
        requiredTier: requiredTier,
        dateTime: dateTime,
        description: description,
        createdAt: createdAt,
        status: status ?? this.status,
      );
}

/// Recorded when a worker taps "စိတ်ဝင်စားသည်" (Interested) on a [Job].
class WorkerInterest {
  final int workerId;
  final int jobId;
  final DateTime createdAt;

  const WorkerInterest({
    required this.workerId,
    required this.jobId,
    required this.createdAt,
  });
}

// ----------------------------------------------------------------------------
// WORKERS (16) — const list, loaded at compile time.
// ----------------------------------------------------------------------------
const List<Worker> workers = [
  Worker(
    id: 1,
    name: "Ko Aung",
    skill: "Electrician",
    emoji: "👨‍🔧",
    rating: 4.9,
    reviews: 212,
    experience: "7 years",
    distanceMiles: 1.2,
    isAvailableNow: true,
    bio: "Licensed electrician. Wiring, fans, breakers and lighting for homes and shops.",
    currentTier: 6,
    township: "လှိုင်",
    completedTasks: 84,
    isVerified: true,
  ),
  Worker(
    id: 2,
    name: "Ko Min",
    skill: "Plumber",
    emoji: "🔧",
    rating: 4.8,
    reviews: 188,
    experience: "5 years",
    distanceMiles: 0.8,
    isAvailableNow: true,
    bio: "Fast leak fixes, pipe fitting, sink and toilet repair. Comes with own tools.",
    currentTier: 5,
    township: "ကမာရွတ်",
    completedTasks: 150,
    isVerified: true,
  ),
  Worker(
    id: 3,
    name: "Ma Su",
    skill: "Cleaner",
    emoji: "🧹",
    rating: 4.7,
    reviews: 143,
    experience: "3 years",
    distanceMiles: 2.1,
    isAvailableNow: false,
    bio: "Deep cleaning for apartments and offices. Eco-friendly supplies on request.",
    currentTier: 4,
    township: "မရမ်းကုန်း",
    completedTasks: 95,
    isVerified: true,
  ),
  Worker(
    id: 4,
    name: "Ko Zaw",
    skill: "Carpenter",
    emoji: "🪚",
    rating: 4.6,
    reviews: 97,
    experience: "9 years",
    distanceMiles: 3.4,
    isAvailableNow: true,
    bio: "Custom furniture, door repair and shelving. Teak specialist.",
    currentTier: 4,
    township: "အင်းစိန်",
    completedTasks: 130,
    isVerified: true,
  ),
  Worker(
    id: 5,
    name: "Ko Thant",
    skill: "AC Technician",
    emoji: "❄️",
    rating: 4.9,
    reviews: 256,
    experience: "6 years",
    distanceMiles: 1.9,
    isAvailableNow: true,
    bio: "AC install, gas refill and servicing for all major brands.",
    currentTier: 6,
    township: "လှိုင်",
    completedTasks: 200,
    isVerified: true,
  ),
  Worker(
    id: 6,
    name: "Daw Hla",
    skill: "Tutor",
    emoji: "📚",
    rating: 4.8,
    reviews: 64,
    experience: "10 years",
    distanceMiles: 0.5,
    isAvailableNow: false,
    bio: "Maths and English tutoring, grades 5–10. Patient and exam focused.",
    currentTier: 5,
    township: "ကမာရွတ်",
    completedTasks: 70,
    isVerified: true,
  ),
  Worker(
    id: 7,
    name: "Ko Naing",
    skill: "Handyman",
    emoji: "🛠️",
    rating: 4.5,
    reviews: 121,
    experience: "4 years",
    distanceMiles: 2.7,
    isAvailableNow: true,
    bio: "Odd jobs, mounting, small repairs around the house. No task too small.",
    currentTier: 3,
    township: "မရမ်းကုန်း",
    completedTasks: 88,
    isVerified: true,
  ),
  Worker(
    id: 8,
    name: "Ma Thiri",
    skill: "Cleaner",
    emoji: "🧼",
    rating: 4.9,
    reviews: 178,
    experience: "5 years",
    distanceMiles: 1.1,
    isAvailableNow: true,
    bio: "Move-in / move-out cleaning and laundry. Reliable and on time.",
    currentTier: 6,
    township: "အင်းစိန်",
    completedTasks: 160,
    isVerified: true,
  ),
  Worker(
    id: 9,
    name: "Ko Phyo",
    skill: "Plumber",
    emoji: "🚰",
    rating: 4.4,
    reviews: 88,
    experience: "2 years",
    distanceMiles: 4.2,
    isAvailableNow: false,
    bio: "Water tank, pump and pipe installation. Quick estimates.",
    currentTier: 2,
    township: "လှိုင်",
    completedTasks: 40,
    isVerified: false,
  ),
  Worker(
    id: 10,
    name: "Ko Kyaw",
    skill: "Electrician",
    emoji: "⚡",
    rating: 4.7,
    reviews: 134,
    experience: "8 years",
    distanceMiles: 2.0,
    isAvailableNow: true,
    bio: "Solar setup, inverters and full house rewiring.",
    currentTier: 5,
    township: "ကမာရွတ်",
    completedTasks: 110,
    isVerified: true,
  ),
  Worker(
    id: 11,
    name: "Ma Ei",
    skill: "Gardener",
    emoji: "🌱",
    rating: 4.6,
    reviews: 52,
    experience: "3 years",
    distanceMiles: 5.0,
    isAvailableNow: true,
    bio: "Lawn care, planting and garden maintenance.",
    currentTier: 3,
    township: "မရမ်းကုန်း",
    completedTasks: 35,
    isVerified: true,
  ),
  Worker(
    id: 12,
    name: "Ko Htet",
    skill: "Carpenter",
    emoji: "🔨",
    rating: 4.8,
    reviews: 109,
    experience: "11 years",
    distanceMiles: 1.6,
    isAvailableNow: false,
    bio: "Cabinet making and flooring. Detailed finish work.",
    currentTier: 6,
    township: "အင်းစိန်",
    completedTasks: 140,
    isVerified: true,
  ),
  Worker(
    id: 13,
    name: "Ko Wai",
    skill: "Delivery",
    emoji: "🚚",
    rating: 4.5,
    reviews: 301,
    experience: "4 years",
    distanceMiles: 0.9,
    isAvailableNow: true,
    bio: "Same-day delivery across Yangon. Bike and small van available.",
    currentTier: 3,
    township: "လှိုင်",
    completedTasks: 250,
    isVerified: true,
  ),
  Worker(
    id: 14,
    name: "Ma Yu",
    skill: "AC Technician",
    emoji: "🌬️",
    rating: 4.7,
    reviews: 142,
    experience: "5 years",
    distanceMiles: 2.4,
    isAvailableNow: true,
    bio: "AC diagnostics and preventive maintenance contracts.",
    currentTier: 5,
    township: "ကမာရွတ်",
    completedTasks: 105,
    isVerified: true,
  ),
  Worker(
    id: 15,
    name: "Ko Sai",
    skill: "Handyman",
    emoji: "🧰",
    rating: 4.3,
    reviews: 71,
    experience: "6 years",
    distanceMiles: 3.1,
    isAvailableNow: false,
    bio: "Painting, sealing and general fixes. Free quote on site.",
    currentTier: 2,
    township: "မရမ်းကုန်း",
    completedTasks: 45,
    isVerified: false,
  ),
  Worker(
    id: 16,
    name: "Daw Mya",
    skill: "Tutor",
    emoji: "✏️",
    rating: 5.0,
    reviews: 40,
    experience: "14 years",
    distanceMiles: 1.4,
    isAvailableNow: true,
    bio: "University entrance prep. Physics and chemistry.",
    currentTier: 7,
    township: "အင်းစိန်",
    completedTasks: 60,
    isVerified: true,
  ),
];

// ----------------------------------------------------------------------------
// LOGGED-IN WORKER (demo identity) — Phase 1 has no auth, so the Tasker
// Dashboard always represents this worker. Ko Min: Plumber, tier 5 — high
// enough to see most demo jobs but not all, so tier-eligibility filtering
// has something to actually filter.
// ----------------------------------------------------------------------------
final Worker loggedInWorker = workers[1];

// ----------------------------------------------------------------------------
// JOBS (10) — open marketplace jobs for the Tasker Dashboard's job board.
// ----------------------------------------------------------------------------
final List<Job> jobs = [
  Job(
    id: 1,
    category: "Plumber",
    township: "ကမာရွတ်",
    distanceMiles: 0.6,
    isUrgent: true,
    aiSuggestedBudgetMmk: 28000,
    requiredTier: 3,
    dateTime: DateTime.now().add(const Duration(hours: 2)),
    description: "Kitchen sink pipe burst, water leaking onto the floor.",
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  Job(
    id: 2,
    category: "Plumber",
    township: "လှိုင်",
    distanceMiles: 1.4,
    isUrgent: false,
    aiSuggestedBudgetMmk: 18000,
    requiredTier: 2,
    dateTime: DateTime.now().add(const Duration(days: 1)),
    description: "Bathroom tap replacement, two units in the apartment.",
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
  ),
  Job(
    id: 3,
    category: "Plumber",
    township: "အင်းစိန်",
    distanceMiles: 3.2,
    isUrgent: false,
    aiSuggestedBudgetMmk: 35000,
    requiredTier: 5,
    dateTime: DateTime.now().add(const Duration(days: 2)),
    description: "Water tank and pump installation for a new house.",
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  Job(
    id: 4,
    category: "Plumber",
    township: "မရမ်းကုန်း",
    distanceMiles: 2.1,
    isUrgent: true,
    aiSuggestedBudgetMmk: 42000,
    requiredTier: 7,
    dateTime: DateTime.now().add(const Duration(hours: 4)),
    description: "Commercial building full pipe re-route, licensed crew needed.",
    createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
  ),
  Job(
    id: 5,
    category: "Plumber",
    township: "ကမာရွတ်",
    distanceMiles: 0.9,
    isUrgent: false,
    aiSuggestedBudgetMmk: 15000,
    requiredTier: 1,
    dateTime: DateTime.now().add(const Duration(days: 3)),
    description: "Toilet flush valve fix, quick job.",
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  Job(
    id: 6,
    category: "Electrician",
    township: "လှိုင်",
    distanceMiles: 1.0,
    isUrgent: false,
    aiSuggestedBudgetMmk: 22000,
    requiredTier: 4,
    dateTime: DateTime.now().add(const Duration(days: 1)),
    description: "Ceiling fan wiring for three bedrooms.",
    createdAt: DateTime.now().subtract(const Duration(hours: 8)),
  ),
  Job(
    id: 7,
    category: "Cleaner",
    township: "မရမ်းကုန်း",
    distanceMiles: 2.6,
    isUrgent: false,
    aiSuggestedBudgetMmk: 12000,
    requiredTier: 2,
    dateTime: DateTime.now().add(const Duration(days: 1)),
    description: "Move-out deep cleaning, two-bedroom apartment.",
    createdAt: DateTime.now().subtract(const Duration(hours: 12)),
  ),
  Job(
    id: 8,
    category: "AC Technician",
    township: "အင်းစိန်",
    distanceMiles: 4.0,
    isUrgent: true,
    aiSuggestedBudgetMmk: 30000,
    requiredTier: 5,
    dateTime: DateTime.now().add(const Duration(hours: 6)),
    description: "AC not cooling, gas refill suspected.",
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  Job(
    id: 9,
    category: "Plumber",
    township: "အင်းစိန်",
    distanceMiles: 5.5,
    isUrgent: false,
    aiSuggestedBudgetMmk: 20000,
    requiredTier: 3,
    dateTime: DateTime.now().add(const Duration(days: 4)),
    description: "Outdoor garden tap and hose fitting installation.",
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
  Job(
    id: 10,
    category: "Carpenter",
    township: "ကမာရွတ်",
    distanceMiles: 1.8,
    isUrgent: false,
    aiSuggestedBudgetMmk: 26000,
    requiredTier: 4,
    dateTime: DateTime.now().add(const Duration(days: 2)),
    description: "Custom shelving for a small home office.",
    createdAt: DateTime.now().subtract(const Duration(hours: 20)),
  ),
];

// ----------------------------------------------------------------------------
// CATEGORIES (10)
// ----------------------------------------------------------------------------
const List<Category> categories = [
  Category(id: 1, name: "Home Cleaning", icon: "🧼", burmese: "အိမ်သန့်ရှင်းရေး"),
  Category(id: 2, name: "Plumbing", icon: "🔧", burmese: "ရေပိုက်ပြင်ဆင်ခြင်း"),
  Category(id: 3, name: "Electrical", icon: "⚡", burmese: "လျှပ်စစ်ပြင်ဆင်ခြင်း"),
  Category(id: 4, name: "AC Repair", icon: "❄️", burmese: "အဲယားကွန်းပြင်"),
  Category(id: 5, name: "Carpentry", icon: "🪚", burmese: "လက်သမားလုပ်ငန်း"),
  Category(id: 6, name: "Tutoring", icon: "📚", burmese: "ကျူရှင်သင်ကြားရေး"),
  Category(id: 7, name: "Delivery", icon: "🚚", burmese: "ပို့ဆောင်ရေး"),
  Category(id: 8, name: "Gardening", icon: "🌱", burmese: "သစ်ပင်စိုက်ပျိုးရေး"),
  Category(id: 9, name: "Laundry", icon: "👕", burmese: "အဝတ်လျှော်ဖွတ်ခြင်း"),
  Category(id: 10, name: "Handyman", icon: "🛠️", burmese: "အထွေထွေပြင်ဆင်ရေး"),
];

// Maps a customer category to the worker skill(s) it surfaces.
const Map<String, List<String>> categoryToSkills = {
  "Home Cleaning": ["Cleaner"],
  "Plumbing": ["Plumber"],
  "Electrical": ["Electrician"],
  "AC Repair": ["AC Technician"],
  "Carpentry": ["Carpenter"],
  "Tutoring": ["Tutor"],
  "Delivery": ["Delivery"],
  "Gardening": ["Gardener"],
  "Laundry": ["Cleaner"],
  "Handyman": ["Handyman"],
};

// ----------------------------------------------------------------------------
// SKILL BADGES for worker onboarding (tap to select 1–3)
// ----------------------------------------------------------------------------
const List<Category> skillBadges = [
  Category(id: 1, name: "Electrician", icon: "⚡", burmese: "လျှပ်စစ်"),
  Category(id: 2, name: "Plumber", icon: "🔧", burmese: "ရေပိုက်"),
  Category(id: 3, name: "Cleaner", icon: "🧼", burmese: "သန့်ရှင်းရေး"),
  Category(id: 4, name: "Carpenter", icon: "🪚", burmese: "လက်သမား"),
  Category(id: 5, name: "AC Technician", icon: "❄️", burmese: "အဲယားကွန်း"),
  Category(id: 6, name: "Tutor", icon: "📚", burmese: "ဆရာ"),
  Category(id: 7, name: "Handyman", icon: "🛠️", burmese: "အထွေထွေ"),
  Category(id: 8, name: "Gardener", icon: "🌱", burmese: "ဥယျာဉ်"),
  Category(id: 9, name: "Delivery", icon: "🚚", burmese: "ပို့ဆောင်"),
  Category(id: 10, name: "Painter", icon: "🎨", burmese: "ဆေးသုတ်"),
];

// ----------------------------------------------------------------------------
// BOOKINGS (5)
// ----------------------------------------------------------------------------
const List<Booking> bookings = [
  Booking(
    id: 1,
    customerName: "Ko Than",
    workerName: "Ko Min",
    skill: "Plumber",
    status: "Completed",
    date: "2026-06-15",
    timeSlot: "10:00 AM",
    township: "ကမာရွတ်",
    totalMmk: 35000,
  ),
  Booking(
    id: 2,
    customerName: "Ma Mai",
    workerName: "Ko Aung",
    skill: "Electrician",
    status: "Active",
    date: "2026-06-23",
    timeSlot: "3:00 PM",
    township: "လှိုင်",
    totalMmk: 48000,
  ),
  Booking(
    id: 3,
    customerName: "Ko Zin",
    workerName: "Ko Thant",
    skill: "AC Technician",
    status: "Pending",
    date: "2026-06-19",
    timeSlot: "1:00 PM",
    township: "အင်းစိန်",
    totalMmk: 30000,
  ),
  Booking(
    id: 4,
    customerName: "Daw Khin",
    workerName: "Ma Thiri",
    skill: "Cleaner",
    status: "Completed",
    date: "2026-06-12",
    timeSlot: "9:00 AM",
    township: "အင်းစိန်",
    totalMmk: 22000,
  ),
  Booking(
    id: 5,
    customerName: "Ko Soe",
    workerName: "Ko Zaw",
    skill: "Carpenter",
    status: "Completed",
    date: "2026-06-10",
    timeSlot: "11:00 AM",
    township: "ကမာရွတ်",
    totalMmk: 54000,
  ),
];

// ----------------------------------------------------------------------------
// FALLBACK CONSTANTS — used by screens if any list above is somehow empty.
// Screens import these so they ALWAYS have something valid to render.
// ----------------------------------------------------------------------------
const Worker fallbackWorker = Worker(
  id: 0,
  name: "Ko Min",
  skill: "Plumber",
  emoji: "🔧",
  rating: 4.8,
  reviews: 100,
  experience: "5 years",
  distanceMiles: 0.8,
  isAvailableNow: true,
  bio: "Fast leak fixes, pipe fitting, sink and toilet repair.",
  currentTier: 5,
  township: "ကမာရွတ်",
  completedTasks: 150,
  isVerified: true,
);

const List<Worker> fallbackWorkers = [fallbackWorker];

const List<Category> fallbackCategories = [
  Category(id: 1, name: "Plumbing", icon: "🔧", burmese: "ရေပိုက်ပြင်ဆင်ခြင်း"),
];

// ============================================================================
// USER PROFILES (static demo identities)
// ----------------------------------------------------------------------------
// Phase 1 has no backend, but these models are shaped the way a real API
// would split a user record so Phase 2 can lift them out almost verbatim:
//
//   • PUBLIC fields           -> rendered on the profile / dashboard.
//   • PrivateRegistration     -> auth + attribution; NEVER rendered.
//   • Verification*           -> trust gating before posting/accepting tasks.
//
// They deliberately reuse the onboarding enums (Gender, HearAboutSource,
// TaskerSkill) so the onboarding draft -> stored profile mapping is 1:1.
// ============================================================================

/// Which side of the marketplace an account belongs to. Stored privately with
/// the rest of the registration data; the screen it renders on already implies
/// the role, so this is never the sole signal in the UI.
enum AccountType { client, tasker }

/// Overall trust state shown on a profile. Distinct from per-document
/// completion (an account can have every document uploaded yet still be
/// `pending` review).
enum VerificationState { notVerified, pending, verified }

extension VerificationStateLabel on VerificationState {
  // TODO(native-speaker-review): confirm tone/wording with a Burmese speaker.
  String get label {
    switch (this) {
      case VerificationState.notVerified:
        return "အတည်ပြုရန် ကျန်ရှိသည်";
      case VerificationState.pending:
        return "စိစစ်နေဆဲ";
      case VerificationState.verified:
        return "အတည်ပြုပြီး";
    }
  }
}

/// A single verification requirement. Clients must complete [nrc],
/// [faceSelfie] and [permanentAddress]; taskers additionally need
/// [pitchingVideo] (the trust-critical intro clip).
enum VerificationDoc { nrc, faceSelfie, permanentAddress, pitchingVideo }

extension VerificationDocLabel on VerificationDoc {
  // TODO(native-speaker-review): confirm tone/wording with a Burmese speaker.
  String get label {
    switch (this) {
      case VerificationDoc.nrc:
        return "မှတ်ပုံတင် (NRC)";
      case VerificationDoc.faceSelfie:
        return "မျက်နှာ အတည်ပြုခြင်း";
      case VerificationDoc.permanentAddress:
        return "အမြဲတမ်း နေရပ်လိပ်စာ";
      case VerificationDoc.pitchingVideo:
        return "ကိုယ်ရေးမိတ်ဆက် ဗီဒီယို";
    }
  }
}

/// Coarse time-of-day windows a tasker can mark themselves available for.
enum AvailabilitySlot { morning, afternoon, evening }

extension AvailabilitySlotLabel on AvailabilitySlot {
  // TODO(native-speaker-review): confirm tone/wording with a Burmese speaker.
  String get label {
    switch (this) {
      case AvailabilitySlot.morning:
        return "မနက်ပိုင်း";
      case AvailabilitySlot.afternoon:
        return "နေ့လည်ပိုင်း";
      case AvailabilitySlot.evening:
        return "ညနေပိုင်း";
    }
  }
}

/// Registration data captured at sign-up that lives behind the profile but is
/// NEVER rendered. Mirrors the columns a real `users` table would protect
/// (credentials + attribution). [password] is a placeholder for a server-side
/// hash — it exists only to fix the model shape and must never be displayed.
class PrivateRegistration {
  final String phone;
  final bool phoneVerified;
  final String password; // NEVER displayed — stands in for a stored hash.
  final HearAboutSource hearAbout; // "Where did you hear about us?"
  final AccountType accountType;

  const PrivateRegistration({
    required this.phone,
    required this.phoneVerified,
    required this.password,
    required this.hearAbout,
    required this.accountType,
  });
}

/// Weekly + time-of-day availability for a tasker. UI-only in Phase 1.
class TaskerAvailability {
  final bool weekdays;
  final bool weekends;
  final Set<AvailabilitySlot> slots;

  const TaskerAvailability({
    this.weekdays = false,
    this.weekends = false,
    this.slots = const {},
  });

  TaskerAvailability copyWith({
    bool? weekdays,
    bool? weekends,
    Set<AvailabilitySlot>? slots,
  }) =>
      TaskerAvailability(
        weekdays: weekdays ?? this.weekdays,
        weekends: weekends ?? this.weekends,
        slots: slots ?? this.slots,
      );
}

/// A service-seeker's stored profile.
class ClientProfile {
  // ── Public (rendered) ──────────────────────────────────────────────────
  final String fullName;
  final int age;
  final Gender gender;
  final String? profilePicturePath; // null -> show the placeholder avatar.
  final String location; // general area only, never the detailed address.

  // ── Private (NEVER rendered — see PrivateRegistration) ──────────────────
  final PrivateRegistration registration;

  // ── Verification ────────────────────────────────────────────────────────
  final VerificationState verificationState;
  final Set<VerificationDoc> completedDocs;

  // ── Stats (static demo values) ──────────────────────────────────────────
  final int tasksPosted;
  final int tasksCompleted;
  final double? rating; // null -> shown as "N/A".

  const ClientProfile({
    required this.fullName,
    required this.age,
    required this.gender,
    required this.profilePicturePath,
    required this.location,
    required this.registration,
    required this.verificationState,
    required this.completedDocs,
    required this.tasksPosted,
    required this.tasksCompleted,
    required this.rating,
  });

  /// Documents a client must complete before posting tasks.
  static const List<VerificationDoc> requiredDocs = [
    VerificationDoc.nrc,
    VerificationDoc.faceSelfie,
    VerificationDoc.permanentAddress,
  ];
}

/// A service-provider's stored profile.
class TaskerProfile {
  // ── Public (rendered) ──────────────────────────────────────────────────
  final String fullName;
  final int age;
  final Gender gender;
  final String? profilePicturePath;
  final Set<TaskerSkill> skills;

  // ── Private (NEVER rendered — see PrivateRegistration) ──────────────────
  final PrivateRegistration registration;

  // ── Verification ────────────────────────────────────────────────────────
  final VerificationState verificationState;
  final Set<VerificationDoc> completedDocs;

  // ── Stats (static demo values) ──────────────────────────────────────────
  final int tasksCompleted;
  final double completionRate; // 0..1
  final double? rating; // null -> shown as "N/A".
  final String responseTime; // static placeholder, already localized.

  // ── Availability ──────────────────────────────────────────────────────
  final TaskerAvailability availability;

  const TaskerProfile({
    required this.fullName,
    required this.age,
    required this.gender,
    required this.profilePicturePath,
    required this.skills,
    required this.registration,
    required this.verificationState,
    required this.completedDocs,
    required this.tasksCompleted,
    required this.completionRate,
    required this.rating,
    required this.responseTime,
    required this.availability,
  });

  /// Documents a tasker must complete before accepting tasks — stricter than
  /// the client set: the pitching video is mandatory.
  static const List<VerificationDoc> requiredDocs = [
    VerificationDoc.nrc,
    VerificationDoc.faceSelfie,
    VerificationDoc.permanentAddress,
    VerificationDoc.pitchingVideo,
  ];
}

/// Derives the overall [VerificationState] from how many required documents
/// are complete. Shared by both profiles so the badge, progress bar and the
/// post/accept gate always agree — and so the screens can recompute it live as
/// the user mock-uploads documents.
VerificationState verificationStateFor(
  Set<VerificationDoc> completed,
  List<VerificationDoc> required,
) {
  final done = required.where(completed.contains).length;
  if (done == 0) return VerificationState.notVerified;
  if (done < required.length) return VerificationState.pending;
  return VerificationState.verified;
}

// ----------------------------------------------------------------------------
// DEMO PROFILES — the two static identities the profile tabs render.
// The client starts UNVERIFIED (0/3) to show the locked "post task" gate;
// the tasker is fully VERIFIED (4/4) to show the unlocked, stats-rich state.
// ----------------------------------------------------------------------------
const ClientProfile demoClientProfile = ClientProfile(
  fullName: "မအေးအေး",
  age: 28,
  gender: Gender.female,
  profilePicturePath: null,
  location: "ကမာရွတ်၊ ရန်ကုန်",
  registration: PrivateRegistration(
    phone: "09-7xx-xxx-xxx",
    phoneVerified: true,
    password: "********",
    hearAbout: HearAboutSource.facebook,
    accountType: AccountType.client,
  ),
  verificationState: VerificationState.notVerified,
  completedDocs: <VerificationDoc>{},
  tasksPosted: 0,
  tasksCompleted: 0,
  rating: null,
);

const TaskerProfile demoTaskerProfile = TaskerProfile(
  fullName: "ကိုမင်း",
  age: 32,
  gender: Gender.male,
  profilePicturePath: null,
  skills: <TaskerSkill>{
    TaskerSkill.plumbing,
    TaskerSkill.electrical,
    TaskerSkill.cleaning,
  },
  registration: PrivateRegistration(
    phone: "09-4xx-xxx-xxx",
    phoneVerified: true,
    password: "********",
    hearAbout: HearAboutSource.friend,
    accountType: AccountType.tasker,
  ),
  verificationState: VerificationState.verified,
  completedDocs: <VerificationDoc>{
    VerificationDoc.nrc,
    VerificationDoc.faceSelfie,
    VerificationDoc.permanentAddress,
    VerificationDoc.pitchingVideo,
  },
  tasksCompleted: 150,
  completionRate: 0.96,
  rating: 4.8,
  // TODO(native-speaker-review): confirm "~15 min" phrasing with a speaker.
  responseTime: "~၁၅ မိနစ်",
  availability: TaskerAvailability(
    weekdays: true,
    weekends: false,
    slots: <AvailabilitySlot>{
      AvailabilitySlot.morning,
      AvailabilitySlot.afternoon,
    },
  ),
);
