// Global demo switch. When true the app uses ONLY hardcoded Dart constants and
// synchronous mock AI — no API keys, no network, no backend, no database.
//
// All demo behaviour in this app assumes DEMO_MODE == true:
//   * AI responses come from lib/core/utils/ai_mock.dart (synchronous)
//   * All data comes from lib/core/data/demo_data.dart (const lists)
//   * No delays longer than 100ms, no blocking error states.
// ignore_for_file: constant_identifier_names
const bool DEMO_MODE = true;
