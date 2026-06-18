# TOLY MOLY

On-demand service marketplace for Myanmar — *"Hire for the task, pay for the
work, done in a day."*

**Current phase:** Phase 1 — fully offline Flutter MVP (hardcoded data, mock AI,
no backend/DB/network).

## Run it

```bash
flutter pub get
flutter run        # to a connected device/emulator
```

## Documentation (start here)

- **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** — full technical
  documentation: folder structure, every core system, file-by-file reference,
  routing, data flow, state, navigation lifecycle, and the future extension
  plan. *Read time ~10–15 min.*
- **[docs/TEAM_PLAN.md](docs/TEAM_PLAN.md)** — team ownership, sprint roadmap,
  feature status matrix, scaling guide, and the "add a new feature safely"
  checklist.

## Golden rules (Phase 1)

1. Data + AI live in exactly two files: `lib/core/data/demo_data.dart` and
   `lib/core/utils/ai_mock.dart`.
2. No hardcoded colors/text/spacing in screens — use `lib/core/theme/` tokens.
3. All navigation via GoRouter (`push` forward, `pop`/system back, `go` only for
   resets). Never override the back button per screen.
4. No backend, no database, no network, no real AI, no async in app logic.
