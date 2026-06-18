// ============================================================================
// CORE FILE 1 of 2 — HARDCODED DART CONSTANTS ONLY
// ----------------------------------------------------------------------------
// NO JSON file loading. NO File.readAsString(). NO jsonDecode() at runtime.
// Every value below is a compile-time `const` — zero async, zero I/O.
// ============================================================================

class Worker {
  final int id;
  final String name;
  final String skill;
  final String emoji; // avatar emoji (offline, no network images)
  final double rating;
  final int reviews;
  final String experience;
  final double distanceMiles;
  final int hourlyRateMmk;
  final bool isAvailableNow;
  final String bio;

  const Worker({
    required this.id,
    required this.name,
    required this.skill,
    required this.emoji,
    required this.rating,
    required this.reviews,
    required this.experience,
    required this.distanceMiles,
    required this.hourlyRateMmk,
    required this.isAvailableNow,
    required this.bio,
  });
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

class Booking {
  final int id;
  final String customerName;
  final String workerName;
  final String skill;
  final String status; // Completed | Active | Pending
  final String date;
  final int totalMmk;

  const Booking({
    required this.id,
    required this.customerName,
    required this.workerName,
    required this.skill,
    required this.status,
    required this.date,
    required this.totalMmk,
  });
}

class ChatMessage {
  final String text;
  final bool fromUser;

  const ChatMessage({required this.text, required this.fromUser});
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
    hourlyRateMmk: 8000,
    isAvailableNow: true,
    bio: "Licensed electrician. Wiring, fans, breakers and lighting for homes and shops.",
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
    hourlyRateMmk: 7000,
    isAvailableNow: true,
    bio: "Fast leak fixes, pipe fitting, sink and toilet repair. Comes with own tools.",
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
    hourlyRateMmk: 5000,
    isAvailableNow: false,
    bio: "Deep cleaning for apartments and offices. Eco-friendly supplies on request.",
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
    hourlyRateMmk: 9000,
    isAvailableNow: true,
    bio: "Custom furniture, door repair and shelving. Teak specialist.",
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
    hourlyRateMmk: 10000,
    isAvailableNow: true,
    bio: "AC install, gas refill and servicing for all major brands.",
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
    hourlyRateMmk: 6000,
    isAvailableNow: false,
    bio: "Maths and English tutoring, grades 5–10. Patient and exam focused.",
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
    hourlyRateMmk: 6500,
    isAvailableNow: true,
    bio: "Odd jobs, mounting, small repairs around the house. No task too small.",
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
    hourlyRateMmk: 5500,
    isAvailableNow: true,
    bio: "Move-in / move-out cleaning and laundry. Reliable and on time.",
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
    hourlyRateMmk: 6000,
    isAvailableNow: false,
    bio: "Water tank, pump and pipe installation. Quick estimates.",
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
    hourlyRateMmk: 8500,
    isAvailableNow: true,
    bio: "Solar setup, inverters and full house rewiring.",
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
    hourlyRateMmk: 4500,
    isAvailableNow: true,
    bio: "Lawn care, planting and garden maintenance.",
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
    hourlyRateMmk: 9500,
    isAvailableNow: false,
    bio: "Cabinet making and flooring. Detailed finish work.",
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
    hourlyRateMmk: 4000,
    isAvailableNow: true,
    bio: "Same-day delivery across Yangon. Bike and small van available.",
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
    hourlyRateMmk: 9000,
    isAvailableNow: true,
    bio: "AC diagnostics and preventive maintenance contracts.",
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
    hourlyRateMmk: 6000,
    isAvailableNow: false,
    bio: "Painting, sealing and general fixes. Free quote on site.",
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
    hourlyRateMmk: 7000,
    isAvailableNow: true,
    bio: "University entrance prep. Physics and chemistry.",
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
    totalMmk: 35000,
  ),
  Booking(
    id: 2,
    customerName: "Ma Mai",
    workerName: "Ko Aung",
    skill: "Electrician",
    status: "Active",
    date: "2026-06-18",
    totalMmk: 48000,
  ),
  Booking(
    id: 3,
    customerName: "Ko Zin",
    workerName: "Ko Thant",
    skill: "AC Technician",
    status: "Pending",
    date: "2026-06-19",
    totalMmk: 30000,
  ),
  Booking(
    id: 4,
    customerName: "Daw Khin",
    workerName: "Ma Thiri",
    skill: "Cleaner",
    status: "Completed",
    date: "2026-06-12",
    totalMmk: 22000,
  ),
  Booking(
    id: 5,
    customerName: "Ko Soe",
    workerName: "Ko Zaw",
    skill: "Carpenter",
    status: "Completed",
    date: "2026-06-10",
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
  hourlyRateMmk: 7000,
  isAvailableNow: true,
  bio: "Fast leak fixes, pipe fitting, sink and toilet repair.",
);

const List<Worker> fallbackWorkers = [fallbackWorker];

const List<Category> fallbackCategories = [
  Category(id: 1, name: "Plumbing", icon: "🔧", burmese: "ရေပိုက်ပြင်ဆင်ခြင်း"),
];
