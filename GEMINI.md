# Toly Moly - Project Context

## Project Overview
Toly Moly is an on-demand service marketplace for Myanmar (Yangon-first). It connects customers (plumbing, cleaning, etc.) with local workers.

**Current Phase: Phase 1 (Offline MVP)**
The app is currently a 100% offline, clickable demo built for presentation. It uses hardcoded data and a synchronous mock AI layer.

### Main Technologies
- **Framework:** [Flutter](https://flutter.dev/)
- **State Management:** [Riverpod](https://riverpod.dev/) (`flutter_riverpod`)
- **Routing:** [GoRouter](https://pub.dev/packages/go_router)
- **Icons:** Material Icons & Cupertino Icons

## Architecture
- **`lib/main.dart`**: App entry point. Wires theme and router.
- **`lib/core/`**: Shared infrastructure.
    - **`constants/`**: UI strings and demo mode flags.
    - **`data/demo_data.dart`**: **CORE SEAM.** The ONLY source of data (const lists).
    - **`utils/ai_mock.dart`**: **CORE SEAM.** The ONLY source of AI responses (synchronous mocks).
    - **`routing/app_router.dart`**: GoRouter configuration and global back-button handler.
    - **`theme/`**: Design system tokens (colors, text styles, spacing).
    - **`widgets/`**: Reusable UI components (buttons, tiles, cards).
- **`lib/features/`**: Feature-specific UI and local state.
    - `auth/`: Splash and Role Selection.
    - `customer/`: Home, Worker List, Profile, and Booking.
    - `worker/`: Onboarding and Dashboard.
    - `chatbot/`: Mock AI assistant.

## Building and Running
The project uses standard Flutter commands.

### Key Commands
- **`
`**: Installs dependencies.
- **`flutter run`**: Runs the app on a connected device or emulator.
- **`flutter test`**: Runs the widget test suite.
- **`flutter analyze`**: Runs static analysis.

## Development Conventions (Phase 1)

### Phase 1 Constraints
- **Offline Only**: No backend, no database, no network calls (HTTP/WebSockets).
- **Synchronous Logic**: No `async/await` in app logic or data flow. All data is `const`.
- **Data/AI Seams**: All data MUST come from `demo_data.dart`. All AI MUST come from `ai_mock.dart`.

### Styling & Theme
- **No Hardcoding**: Never hardcode colors, spacing, or text styles in screens.
- **Use Tokens**: Use tokens from `lib/core/theme/` via `Theme.of(context)` or the `AppSpacing`/`AppTextStyles` classes.

### Navigation & Routing
- **Constants**: Always use `Routes.*` constants from `app_router.dart`, never raw path strings.
- **Verbs**:
    - `context.push(route)`: For forward navigation (adds to stack).
    - `context.pop()`: For going back.
    - `context.go(route)`: ONLY for intentional stack resets (e.g., switching roles, finishing a flow).
- **Back Button**: Do NOT override the back button per screen. It is handled globally in `_RootBackHandler` within `app_router.dart`.

### State Management
- **Local State**: Riverpod is used for local UI state only.
- **Co-location**: Declare `StateProvider`s **inside the screen file** that uses them. Do not create global/shared provider files in Phase 1.
- **No Async Providers**: Avoid `FutureProvider` or `AsyncNotifier` in Phase 1.

### Testing
- Tests are located in the `test/` directory.
- Use `flutter test` to verify UI behavior.
